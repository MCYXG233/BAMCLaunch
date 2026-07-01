import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'account.dart';
import 'account_manager.dart';

/// 皮肤类型枚举
///
/// 定义了 Minecraft 中两种主要的玩家皮肤类型：
/// - [steve]: 经典皮肤，手臂宽度为 4 像素
/// - [alex]: 细臂皮肤，手臂宽度为 3 像素
enum SkinType {
  /// 经典皮肤（Steve）
  /// 标准的 Minecraft 皮肤格式，手臂宽度为 4 像素
  steve,

  /// 细臂皮肤（Alex）
  /// 较新的皮肤格式，手臂宽度为 3 像素，看起来更纤细
  alex,
}

/// 皮肤数据类
///
/// 封装了玩家皮肤的完整信息，包括图像数据、皮肤类型、
/// 来源 URL 以及缓存相关的元数据。
///
/// 该类支持 JSON 序列化和反序列化，便于持久化存储。
class SkinData {
  /// 皮肤图像数据
  ///
  /// 存储 PNG 格式的皮肤图片原始字节数据。
  /// 标准皮肤尺寸为 64x64 像素。
  final List<int> imageData;

  /// 皮肤类型
  ///
  /// 标识此皮肤是经典类型（Steve）还是细臂类型（Alex）。
  /// 这影响皮肤在游戏中的渲染方式。
  final SkinType type;

  /// 皮肤 URL
  ///
  /// 皮肤图片的下载来源地址，可能为空。
  /// 用于记录皮肤来源，便于后续刷新或验证。
  final String? skinUrl;

  /// 披风 URL
  ///
  /// 玩家披风的下载地址，可能为空。
  /// 并非所有玩家都有披风。
  final String? capeUrl;

  /// 皮肤数据的 SHA1 哈希值
  ///
  /// 用于唯一标识皮肤内容，便于缓存验证和去重。
  final String hash;

  /// 创建时间
  ///
  /// 记录此皮肤数据的创建时间，用于缓存有效期判断。
  final DateTime createdAt;

  /// 创建皮肤数据实例
  ///
  /// [imageData] 皮肤图像的字节数据
  /// [type] 皮肤类型（Steve 或 Alex）
  /// [skinUrl] 皮肤来源 URL（可选）
  /// [capeUrl] 披风 URL（可选）
  /// [hash] 皮肤数据的 SHA1 哈希值
  /// [createdAt] 数据创建时间
  SkinData({
    required this.imageData,
    required this.type,
    this.skinUrl,
    this.capeUrl,
    required this.hash,
    required this.createdAt,
  });

  /// 将皮肤数据序列化为 JSON 格式
  ///
  /// 返回一个包含所有皮肤信息的 Map，其中：
  /// - `imageData`: Base64 编码的图像数据
  /// - `type`: 皮肤类型名称字符串
  /// - `skinUrl`: 皮肤 URL（可能为空）
  /// - `capeUrl`: 披风 URL（可能为空）
  /// - `hash`: SHA1 哈希值
  /// - `createdAt`: ISO8601 格式的时间字符串
  ///
  /// 主要用于将皮肤数据保存到缓存文件。
  Map<String, dynamic> toJson() {
    return {
      'imageData': base64Encode(imageData),
      'type': type.name,
      'skinUrl': skinUrl,
      'capeUrl': capeUrl,
      'hash': hash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 从 JSON 数据创建皮肤数据实例
  ///
  /// [json] 包含皮肤数据的 Map 对象
  ///
  /// 返回一个新的 [SkinData] 实例。
  ///
  /// JSON 字段说明：
  /// - `imageData`: Base64 编码的图像数据（必需）
  /// - `type`: 皮肤类型名称，默认为 [SkinType.steve]
  /// - `skinUrl`: 皮肤 URL（可选）
  /// - `capeUrl`: 披风 URL（可选）
  /// - `hash`: SHA1 哈希值（必需）
  /// - `createdAt`: ISO8601 格式的时间字符串（必需）
  factory SkinData.fromJson(Map<String, dynamic> json) {
    return SkinData(
      imageData: base64Decode(json['imageData'] as String),
      type: SkinType.values.firstWhere(
        (e) => e.name == json['type'],
        // 如果类型无法识别，默认使用 Steve 类型
        orElse: () => SkinType.steve,
      ),
      skinUrl: json['skinUrl'] as String?,
      capeUrl: json['capeUrl'] as String?,
      hash: json['hash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 皮肤管理器
///
/// 负责获取、缓存和管理玩家皮肤的 singleton 类。
///
/// 主要功能：
/// - 从多个来源获取玩家皮肤（账户 URL、Mojang API、Crafatar）
/// - 支持内存缓存和文件缓存，减少网络请求
/// - 自动管理缓存有效期（默认 30 天）
/// - 提供缓存清理功能
/// - 支持自定义皮肤设置和移除
///
/// 使用示例：
/// ```dart
/// final skinManager = SkinManager();
/// await skinManager.initialize();
/// final skin = await skinManager.getSkin(account);
/// ```
class SkinManager {
  /// 单例实例
  static SkinManager? _instance;

  /// 日志记录器
  final Logger _logger = Logger('SkinManager');

  /// 平台适配器，用于获取应用支持目录等平台相关功能
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 缓存有效期
  ///
  /// 皮肤缓存的有效时长，默认为 30 天。
  /// 超过此时间的缓存将被视为过期，需要重新获取。
  static const Duration _cacheDuration = Duration(days: 30);

  /// 内存中的皮肤缓存
  ///
  /// 键为缓存键（基于账户 UUID 或用户名），值为 [SkinData] 对象。
  /// 用于快速访问最近使用的皮肤，避免频繁读取文件。
  final Map<String, SkinData> _skinCache = {};

  /// 是否已完成初始化
  ///
  /// 标记皮肤管理器是否已完成初始化，避免重复初始化。
  bool _initialized = false;

  /// 缓存目录
  ///
  /// 存储皮肤缓存文件的目录路径。
  /// 初始化时会在应用支持目录下创建 'skins' 子目录。
  Directory? _cacheDir;

  /// 自定义皮肤目录
  ///
  /// 存储自定义皮肤文件的目录路径。
  Directory? _customSkinDir;

  /// 私有构造函数
  ///
  /// 实现单例模式，外部应通过 [instance] 或工厂构造函数获取实例。
  SkinManager._internal();

  /// 获取单例实例
  ///
  /// 返回 [SkinManager] 的唯一实例。
  /// 如果实例不存在，会自动创建。
  static SkinManager get instance {
    _instance ??= SkinManager._internal();
    return _instance!;
  }

  /// 工厂构造函数
  ///
  /// 返回单例实例，等同于调用 [instance]。
  factory SkinManager() => instance;

  /// 初始化皮肤管理器
  ///
  /// 创建缓存目录并完成初始化。此方法是幂等的，
  /// 多次调用只会执行一次初始化。
  ///
  /// 初始化过程：
  /// 1. 获取应用支持目录
  /// 2. 创建 'skins' 子目录（如果不存在）
  /// 3. 创建 'custom_skins' 子目录（如果不存在）
  /// 4. 标记初始化完成
  ///
  /// 即使初始化失败也会标记为已完成，避免重复尝试导致性能问题。
  Future<void> initialize() async {
    // 避免重复初始化
    if (_initialized) return;

    try {
      // 获取应用支持目录
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      // 创建皮肤缓存目录
      _cacheDir = Directory(path.join(supportDir, 'skins'));

      // 如果目录不存在，递归创建
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // 创建自定义皮肤目录
      _customSkinDir = Directory(path.join(supportDir, 'custom_skins'));
      if (!await _customSkinDir!.exists()) {
        await _customSkinDir!.create(recursive: true);
      }

      _logger.info('Skin manager initialized, cache dir: ${_cacheDir!.path}, custom dir: ${_customSkinDir!.path}');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize skin manager', e, stackTrace);
      // 即使失败也标记为初始化，避免重复尝试
      _initialized = true;
    }
  }

  /// 获取账户的皮肤
  ///
  /// 根据账户信息获取对应的皮肤数据。支持多级缓存策略：
  /// 1. 首先检查内存缓存
  /// 2. 然后检查文件缓存
  /// 3. 最后从网络获取
  ///
  /// [account] 要获取皮肤的账户对象
  /// [forceRefresh] 是否强制刷新，为 true 时跳过所有缓存
  ///
  /// 返回皮肤数据，如果获取失败则返回 null。
  ///
  /// 获取流程：
  /// 1. 确保管理器已初始化
  /// 2. 生成缓存键
  /// 3. 检查内存缓存（如果未强制刷新）
  /// 4. 检查文件缓存（如果未强制刷新）
  /// 5. 从网络获取皮肤
  /// 6. 更新内存和文件缓存
  Future<SkinData?> getSkin(Account account, {bool forceRefresh = false}) async {
    // 确保管理器已初始化
    await initialize();

    // 生成缓存键
    final cacheKey = _getCacheKey(account);

    // 先检查内存缓存
    if (!forceRefresh && _skinCache.containsKey(cacheKey)) {
      _logger.debug('Using in-memory cached skin for ${account.username}');
      return _skinCache[cacheKey];
    }

    // 检查文件缓存
    final cachedSkin = await _loadCachedSkin(cacheKey);
    if (!forceRefresh && cachedSkin != null) {
      _logger.debug('Using file cached skin for ${account.username}');
      // 同时更新内存缓存
      _skinCache[cacheKey] = cachedSkin;
      return cachedSkin;
    }

    // 从网络获取
    try {
      final skin = await _fetchSkin(account);
      if (skin != null) {
        // 更新内存缓存
        _skinCache[cacheKey] = skin;
        // 保存到文件缓存
        await _saveCachedSkin(cacheKey, skin);
        _logger.info('Fetched new skin for ${account.username}');
      }
      return skin;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch skin for ${account.username}', e, stackTrace);
      // 如果获取失败，尝试使用缓存（即使过期了）
      return await _loadCachedSkin(cacheKey, ignoreExpiry: true);
    }
  }

  /// 生成缓存键
  ///
  /// 根据账户信息生成唯一的缓存键。
  /// 优先使用 UUID（更稳定），如果没有 UUID 则使用用户名。
  ///
  /// [account] 账户对象
  ///
  /// 返回缓存键字符串，格式为：
  /// - 有 UUID 时: `uuid_{uuid}`
  /// - 无 UUID 时: `user_{username}`
  String _getCacheKey(Account account) {
    if (account.uuid != null) {
      return 'uuid_${account.uuid}';
    }
    return 'user_${account.username}';
  }

  /// 从网络获取皮肤
  ///
  /// 按优先级从多个来源尝试获取皮肤：
  /// 1. 账户中已有的皮肤 URL
  /// 2. Mojang API（仅限微软账户且有 UUID）
  /// 3. Crafatar 服务（最后的备选方案）
  ///
  /// [account] 账户对象
  ///
  /// 返回皮肤数据，如果所有来源都失败则返回 null。
  Future<SkinData?> _fetchSkin(Account account) async {
    // 优先使用账户中已有的皮肤URL
    if (account.skinUrl != null) {
      try {
        return await _downloadSkin(account.skinUrl!, account.capeUrl, account);
      } catch (e) {
        _logger.warn('Failed to download skin from account URL: $e');
      }
    }

    // 尝试从 Mojang API 获取（仅限微软账户）
    if (account.uuid != null && account.type == AccountType.microsoft) {
      try {
        return await _fetchFromMojang(account);
      } catch (e) {
        _logger.warn('Failed to fetch skin from Mojang API: $e');
      }
    }

    // 尝试从 Crafatar 获取（通用备选方案）
    try {
      return await _fetchFromCrafatar(account);
    } catch (e) {
      _logger.warn('Failed to fetch skin from Crafatar: $e');
    }

    return null;
  }

  /// 从 Mojang API 获取皮肤
  ///
  /// 通过 Mojang 的 Session Server API 获取玩家的皮肤信息。
  /// 这是获取正版账户皮肤最可靠的方式。
  ///
  /// API 端点: `https://sessionserver.mojang.com/session/minecraft/profile/{uuid}`
  ///
  /// [account] 账户对象，必须包含有效的 UUID
  ///
  /// 返回皮肤数据。
  ///
  /// 流程：
  /// 1. 清理 UUID（移除连字符）
  /// 2. 请求 Session Server API
  /// 3. 解析返回的 properties 中的 textures 数据
  /// 4. 从 textures 中提取皮肤 URL 和披风 URL
  /// 5. 下载皮肤图片
  Future<SkinData> _fetchFromMojang(Account account) async {
    // Mojang API 需要完整的 UUID（不带连字符）
    final cleanUuid = account.uuid?.replaceAll('-', '');
    final sessionUrl = 'https://sessionserver.mojang.com/session/minecraft/profile/$cleanUuid';

    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        sessionUrl,
        headers: {'User-Agent': 'BAMCLaunch/1.0'},
        timeoutSeconds: 30,
      );

      if (response.statusCode != 200) {
        throw NetworkException.fromStatusCode(response.statusCode);
      }

      // 读取并解析响应
      final profileData = jsonDecode(response.body) as Map<String, dynamic>;

      // 解析皮肤数据
      // properties 是一个数组，包含多个属性
      final properties = profileData['properties'] as List?;
      if (properties != null) {
        for (final property in properties) {
          // 查找名为 'textures' 的属性
          if (property is Map && property['name'] == 'textures') {
            // textures 的 value 是 Base64 编码的 JSON
            final value = property['value'] as String;
            final decodedValue = utf8.decode(base64Decode(value));
            final textureData = jsonDecode(decodedValue) as Map<String, dynamic>;

            // 提取皮肤和披风的 URL
            final textures = textureData['textures'] as Map?;
            if (textures != null) {
              final skinTexture = textures['SKIN'] as Map?;
              final capeTexture = textures['CAPE'] as Map?;

              final skinUrl = skinTexture?['url'] as String?;
              final capeUrl = capeTexture?['url'] as String?;

              if (skinUrl != null) {
                return await _downloadSkin(skinUrl, capeUrl, account);
              }
            }
          }
        }
      }

      throw AppException.fromCode(
        ErrorCodes.networkJsonParseError,
        detail: 'No skin data found in profile',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 从 Crafatar 获取皮肤
  ///
  /// Crafatar 是一个第三方皮肤服务，可以通过 UUID 或用户名获取皮肤。
  /// 作为 Mojang API 不可用时的备选方案。
  ///
  /// API 端点: `https://crafatar.com/skins/{identifier}`
  ///
  /// [account] 账户对象，使用 UUID 或用户名作为标识符
  ///
  /// 返回皮肤数据。
  Future<SkinData> _fetchFromCrafatar(Account account) async {
    // Crafatar 直接提供头像和皮肤
    // 优先使用 UUID，其次使用用户名
    final identifier = account.uuid ?? account.username;
    final skinUrl = 'https://crafatar.com/skins/$identifier';

    return await _downloadSkin(skinUrl, null, account);
  }

  /// 下载皮肤图片
  ///
  /// 从指定 URL 下载皮肤图片并创建 [SkinData] 对象。
  ///
  /// [skinUrl] 皮肤图片的下载地址
  /// [capeUrl] 披风图片的下载地址（可选）
  /// [account] 关联的账户对象
  ///
  /// 返回包含图片数据和元信息的 [SkinData] 对象。
  ///
  /// 流程：
  /// 1. 发送 HTTP GET 请求
  /// 2. 读取响应数据
  /// 3. 计算 SHA1 哈希值
  /// 4. 判断皮肤类型
  /// 5. 创建并返回 SkinData 对象
  Future<SkinData> _downloadSkin(String skinUrl, String? capeUrl, Account account) async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        skinUrl,
        headers: {'User-Agent': 'BAMCLaunch/1.0'},
        timeoutSeconds: 30,
      );

      if (response.statusCode != 200) {
        throw NetworkException.fromStatusCode(response.statusCode);
      }

      // 将响应数据转换为字节列表
      final imageBytes = response.bodyBytes;

      // 计算哈希值，用于缓存验证和去重
      final hash = sha1.convert(imageBytes).toString();

      // 简单判断皮肤类型 - 检查皮肤尺寸或者使用默认
      // 这里我们使用简单的判断，实际可以解析皮肤文件
      final skinType = _guessSkinType(imageBytes);

      return SkinData(
        imageData: imageBytes,
        type: skinType,
        skinUrl: skinUrl,
        capeUrl: capeUrl,
        hash: hash,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 简单猜测皮肤类型
  ///
  /// 根据皮肤图片数据判断皮肤类型（Steve 或 Alex）。
  ///
  /// 注意：当前实现总是返回 [SkinType.steve]，
  /// 实际应用中应该解析 PNG 文件来检查皮肤尺寸或特定像素。
  ///
  /// [imageData] 皮肤图片的字节数据
  ///
  /// 返回皮肤类型枚举值。
  SkinType _guessSkinType(List<int> imageData) {
    // 简单的启发式判断
    // 实际上需要解析PNG来查看尺寸或特定像素
    // 这里先默认返回 steve
    return SkinType.steve;
  }

  /// 加载缓存的皮肤
  ///
  /// 从文件系统加载缓存的皮肤数据。
  /// 缓存由两个文件组成：
  /// - `{cacheKey}.json`: 元数据（类型、URL、哈希、创建时间）
  /// - `{cacheKey}.png`: 皮肤图片
  ///
  /// [cacheKey] 缓存键
  /// [ignoreExpiry] 是否忽略缓存有效期，为 true 时即使过期也返回缓存数据
  ///
  /// 返回皮肤数据，如果缓存不存在或已过期则返回 null。
  Future<SkinData?> _loadCachedSkin(String cacheKey, {bool ignoreExpiry = false}) async {
    if (_cacheDir == null) return null;

    try {
      // 构建缓存文件路径
      final metadataFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));
      final imageFile = File(path.join(_cacheDir!.path, '$cacheKey.png'));

      // 检查缓存文件是否存在
      if (!await metadataFile.exists() || !await imageFile.exists()) {
        return null;
      }

      // 读取并解析元数据
      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

      // 检查缓存是否过期
      final createdAt = DateTime.parse(metadata['createdAt'] as String);
      if (!ignoreExpiry && DateTime.now().difference(createdAt) > _cacheDuration) {
        _logger.debug('Cache expired for $cacheKey');
        return null;
      }

      // 读取图片数据
      final imageData = await imageFile.readAsBytes();

      return SkinData(
        imageData: imageData,
        type: SkinType.values.firstWhere(
          (e) => e.name == metadata['type'],
          // 如果类型无法识别，默认使用 Steve 类型
          orElse: () => SkinType.steve,
        ),
        skinUrl: metadata['skinUrl'] as String?,
        capeUrl: metadata['capeUrl'] as String?,
        hash: metadata['hash'] as String,
        createdAt: createdAt,
      );
    } catch (e) {
      _logger.warn('Failed to load cached skin: $e');
      return null;
    }
  }

  /// 保存皮肤到缓存
  ///
  /// 将皮肤数据保存到文件系统缓存。
  /// 创建两个文件：
  /// - `{cacheKey}.json`: 元数据文件
  /// - `{cacheKey}.png`: 皮肤图片文件
  ///
  /// [cacheKey] 缓存键
  /// [skin] 要保存的皮肤数据
  Future<void> _saveCachedSkin(String cacheKey, SkinData skin) async {
    if (_cacheDir == null) return;

    try {
      // 构建缓存文件路径
      final metadataFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));
      final imageFile = File(path.join(_cacheDir!.path, '$cacheKey.png'));

      // 保存元数据（不包含图片数据，图片单独存储）
      await metadataFile.writeAsString(jsonEncode({
        'type': skin.type.name,
        'skinUrl': skin.skinUrl,
        'capeUrl': skin.capeUrl,
        'hash': skin.hash,
        'createdAt': skin.createdAt.toIso8601String(),
      }));

      // 保存图片数据
      await imageFile.writeAsBytes(skin.imageData);
    } catch (e) {
      _logger.warn('Failed to save cached skin: $e');
    }
  }

  /// 清理过期缓存
  ///
  /// 遍历缓存目录，删除超过有效期的缓存文件。
  /// 同时清理对应的内存缓存。
  ///
  /// 流程：
  /// 1. 列出缓存目录中的所有文件
  /// 2. 遍历所有 JSON 元数据文件
  /// 3. 检查每个缓存的创建时间
  /// 4. 删除过期的元数据文件和对应的图片文件
  /// 5. 从内存缓存中移除对应的条目
  Future<void> cleanExpiredCache() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      int cleanedCount = 0;

      for (final file in files) {
        // 只处理 JSON 元数据文件
        if (file is File && file.path.endsWith('.json')) {
          try {
            // 读取并解析元数据
            final content = await file.readAsString();
            final metadata = jsonDecode(content) as Map<String, dynamic>;
            final createdAt = DateTime.parse(metadata['createdAt'] as String);

            // 检查是否过期
            if (DateTime.now().difference(createdAt) > _cacheDuration) {
              // 获取基础文件名，用于查找对应的图片文件
              final baseName = path.basenameWithoutExtension(file.path);
              final imageFile = File(path.join(_cacheDir!.path, '$baseName.png'));

              // 删除元数据文件
              await file.delete();
              // 删除对应的图片文件（如果存在）
              if (await imageFile.exists()) {
                await imageFile.delete();
              }

              // 清理内存缓存
              _skinCache.remove(baseName);

              cleanedCount++;
            }
          } catch (e) {
            // 删除失败的文件，直接忽略
          }
        }
      }

      _logger.info('Cleaned $cleanedCount expired skin files');
    } catch (e, stackTrace) {
      _logger.error('Failed to clean expired cache', e, stackTrace);
    }
  }

  /// 清除所有缓存
  ///
  /// 清空内存缓存并删除所有缓存文件。
  /// 缓存目录会被重新创建（空目录）。
  Future<void> clearAllCache() async {
    // 清空内存缓存
    _skinCache.clear();

    if (_cacheDir != null && await _cacheDir!.exists()) {
      try {
        // 删除整个缓存目录
        await _cacheDir!.delete(recursive: true);
        // 重新创建空目录
        await _cacheDir!.create(recursive: true);
        _logger.info('Cleared all skin cache');
      } catch (e, stackTrace) {
        _logger.error('Failed to clear skin cache', e, stackTrace);
      }
    }
  }

  /// 计算缓存大小
  ///
  /// 遍历缓存目录中的所有文件，计算总大小。
  ///
  /// 返回缓存的总字节数。如果缓存目录不存在或读取失败，返回 0。
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    try {
      int totalSize = 0;
      final files = await _cacheDir!.list().toList();

      // 累加所有文件的大小
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// 设置自定义皮肤
  ///
  /// 为指定账户设置自定义皮肤。
  ///
  /// [account] 要设置皮肤的账户
  /// [skinData] 皮肤图像的字节数据
  Future<void> setCustomSkin(Account account, List<int> skinData) async {
    await initialize();

    try {
      final cacheKey = _getCacheKey(account);
      
      // 保存自定义皮肤文件
      final skinFileName = '${cacheKey}_custom.png';
      final skinFile = File(path.join(_customSkinDir!.path, skinFileName));
      await skinFile.writeAsBytes(skinData);

      // 更新账户皮肤URL
      final accountManager = AccountManager();
      await accountManager.updateAccount(account.copyWith(skinUrl: skinFile.path));

      // 清除缓存，强制重新加载
      _skinCache.remove(cacheKey);
      await clearCacheForAccount(account);

      _logger.info('Custom skin set for account: ${account.username}');
    } catch (e, stackTrace) {
      _logger.error('Failed to set custom skin', e, stackTrace);
      rethrow;
    }
  }

  /// 移除自定义皮肤
  ///
  /// 移除指定账户的自定义皮肤，恢复为默认皮肤。
  ///
  /// [account] 要移除皮肤的账户
  Future<void> removeCustomSkin(Account account) async {
    await initialize();

    try {
      final cacheKey = _getCacheKey(account);
      
      // 删除自定义皮肤文件
      final skinFileName = '${cacheKey}_custom.png';
      final skinFile = File(path.join(_customSkinDir!.path, skinFileName));
      if (await skinFile.exists()) {
        await skinFile.delete();
      }

      // 更新账户皮肤URL
      final accountManager = AccountManager();
      await accountManager.updateAccount(account.copyWith(skinUrl: null));

      // 清除缓存
      _skinCache.remove(cacheKey);
      await clearCacheForAccount(account);

      _logger.info('Custom skin removed for account: ${account.username}');
    } catch (e, stackTrace) {
      _logger.error('Failed to remove custom skin', e, stackTrace);
      rethrow;
    }
  }

  /// 清除指定账户的缓存
  ///
  /// [account] 要清除缓存的账户
  Future<void> clearCacheForAccount(Account account) async {
    await initialize();

    final cacheKey = _getCacheKey(account);
    
    // 删除缓存文件
    try {
      final metadataFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));
      final imageFile = File(path.join(_cacheDir!.path, '$cacheKey.png'));
      
      if (await metadataFile.exists()) await metadataFile.delete();
      if (await imageFile.exists()) await imageFile.delete();
    } catch (e) {
      _logger.warn('Failed to delete cache files for account: ${account.username}');
    }
  }

  /// 释放资源
  ///
  /// 清空内存缓存并重置初始化状态。
  void dispose() {
    _skinCache.clear();
    _initialized = false;
    _cacheDir = null;
    _customSkinDir = null;
  }
}