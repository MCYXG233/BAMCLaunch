import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'account.dart';

/// 皮肤类型
enum SkinType {
  /// 经典皮肤（Steve）
  steve,

  /// 细臂皮肤（Alex）
  alex,
}

/// 皮肤数据
class SkinData {
  /// 皮肤图像数据
  final List<int> imageData;

  /// 皮肤类型
  final SkinType type;

  /// 皮肤URL
  final String? skinUrl;

  /// 披风URL
  final String? capeUrl;

  /// 皮肤数据的SHA1哈希
  final String hash;

  /// 创建时间
  final DateTime createdAt;

  SkinData({
    required this.imageData,
    required this.type,
    this.skinUrl,
    this.capeUrl,
    required this.hash,
    required this.createdAt,
  });

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

  factory SkinData.fromJson(Map<String, dynamic> json) {
    return SkinData(
      imageData: base64Decode(json['imageData'] as String),
      type: SkinType.values.firstWhere(
        (e) => e.name == json['type'],
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
/// 负责获取、缓存和管理玩家皮肤
class SkinManager {
  static SkinManager? _instance;

  final Logger _logger = Logger('SkinManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 缓存有效期（30天）
  static const Duration _cacheDuration = Duration(days: 30);

  /// 内存中的皮肤缓存
  final Map<String, SkinData> _skinCache = {};

  /// 是否正在初始化
  bool _initialized = false;

  /// 缓存目录
  Directory? _cacheDir;

  SkinManager._internal();

  /// 获取单例实例
  static SkinManager get instance {
    _instance ??= SkinManager._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory SkinManager() => instance;

  /// 初始化皮肤管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _cacheDir = Directory(path.join(supportDir, 'skins'));

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _logger.info('Skin manager initialized, cache dir: ${_cacheDir!.path}');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize skin manager', e, stackTrace);
      // 即使失败也标记为初始化，避免重复尝试
      _initialized = true;
    }
  }

  /// 获取账户的皮肤
  /// [account] 账户对象
  /// [forceRefresh] 是否强制刷新
  Future<SkinData?> getSkin(Account account, {bool forceRefresh = false}) async {
    await initialize();

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
      _skinCache[cacheKey] = cachedSkin;
      return cachedSkin;
    }

    // 从网络获取
    try {
      final skin = await _fetchSkin(account);
      if (skin != null) {
        _skinCache[cacheKey] = skin;
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
  String _getCacheKey(Account account) {
    if (account.uuid != null) {
      return 'uuid_${account.uuid}';
    }
    return 'user_${account.username}';
  }

  /// 从网络获取皮肤
  Future<SkinData?> _fetchSkin(Account account) async {
    // 优先使用账户中已有的皮肤URL
    if (account.skinUrl != null) {
      try {
        return await _downloadSkin(account.skinUrl!, account.capeUrl, account);
      } catch (e) {
        _logger.warn('Failed to download skin from account URL: $e');
      }
    }

    // 尝试从 Mojang API 获取
    if (account.uuid != null && account.type == AccountType.microsoft) {
      try {
        return await _fetchFromMojang(account);
      } catch (e) {
        _logger.warn('Failed to fetch skin from Mojang API: $e');
      }
    }

    // 尝试从 Crafatar 获取
    try {
      return await _fetchFromCrafatar(account);
    } catch (e) {
      _logger.warn('Failed to fetch skin from Crafatar: $e');
    }

    return null;
  }

  /// 从 Mojang API 获取皮肤
  Future<SkinData> _fetchFromMojang(Account account) async {
    // Mojang API 需要完整的 UUID（不带连字符）
    final cleanUuid = account.uuid?.replaceAll('-', '');
    final sessionUrl = 'https://sessionserver.mojang.com/session/minecraft/profile/$cleanUuid';

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(sessionUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Mojang API returned ${response.statusCode}');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final profileData = jsonDecode(responseBody) as Map<String, dynamic>;

      // 解析皮肤数据
      final properties = profileData['properties'] as List?;
      if (properties != null) {
        for (final property in properties) {
          if (property is Map && property['name'] == 'textures') {
            final value = property['value'] as String;
            final decodedValue = utf8.decode(base64Decode(value));
            final textureData = jsonDecode(decodedValue) as Map<String, dynamic>;

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

      throw Exception('No skin data found in profile');
    } finally {
      client.close();
    }
  }

  /// 从 Crafatar 获取皮肤
  Future<SkinData> _fetchFromCrafatar(Account account) async {
    // Crafatar 直接提供头像和皮肤
    final identifier = account.uuid ?? account.username;
    final skinUrl = 'https://crafatar.com/skins/$identifier';

    return await _downloadSkin(skinUrl, null, account);
  }

  /// 下载皮肤图片
  Future<SkinData> _downloadSkin(String skinUrl, String? capeUrl, Account account) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(skinUrl));
      request.headers.set('User-Agent', 'BAMCLaunch/1.0');

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Skin download failed with ${response.statusCode}');
      }

      final imageBytes = await response.expand((chunk) => chunk).toList();

      // 计算哈希值
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
    } finally {
      client.close();
    }
  }

  /// 简单猜测皮肤类型
  SkinType _guessSkinType(List<int> imageData) {
    // 简单的启发式判断
    // 实际上需要解析PNG来查看尺寸或特定像素
    // 这里先默认返回 steve
    return SkinType.steve;
  }

  /// 加载缓存的皮肤
  Future<SkinData?> _loadCachedSkin(String cacheKey, {bool ignoreExpiry = false}) async {
    if (_cacheDir == null) return null;

    try {
      final metadataFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));
      final imageFile = File(path.join(_cacheDir!.path, '$cacheKey.png'));

      if (!await metadataFile.exists() || !await imageFile.exists()) {
        return null;
      }

      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

      final createdAt = DateTime.parse(metadata['createdAt'] as String);
      if (!ignoreExpiry && DateTime.now().difference(createdAt) > _cacheDuration) {
        _logger.debug('Cache expired for $cacheKey');
        return null;
      }

      final imageData = await imageFile.readAsBytes();

      return SkinData(
        imageData: imageData,
        type: SkinType.values.firstWhere(
          (e) => e.name == metadata['type'],
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
  Future<void> _saveCachedSkin(String cacheKey, SkinData skin) async {
    if (_cacheDir == null) return;

    try {
      final metadataFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));
      final imageFile = File(path.join(_cacheDir!.path, '$cacheKey.png'));

      await metadataFile.writeAsString(jsonEncode({
        'type': skin.type.name,
        'skinUrl': skin.skinUrl,
        'capeUrl': skin.capeUrl,
        'hash': skin.hash,
        'createdAt': skin.createdAt.toIso8601String(),
      }));

      await imageFile.writeAsBytes(skin.imageData);
    } catch (e) {
      _logger.warn('Failed to save cached skin: $e');
    }
  }

  /// 清理过期缓存
  Future<void> cleanExpiredCache() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      int cleanedCount = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final metadata = jsonDecode(content) as Map<String, dynamic>;
            final createdAt = DateTime.parse(metadata['createdAt'] as String);

            if (DateTime.now().difference(createdAt) > _cacheDuration) {
              final baseName = path.basenameWithoutExtension(file.path);
              final imageFile = File(path.join(_cacheDir!.path, '$baseName.png'));

              await file.delete();
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
  Future<void> clearAllCache() async {
    _skinCache.clear();

    if (_cacheDir != null && await _cacheDir!.exists()) {
      try {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _logger.info('Cleared all skin cache');
      } catch (e, stackTrace) {
        _logger.error('Failed to clear skin cache', e, stackTrace);
      }
    }
  }

  /// 计算缓存大小
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    try {
      int totalSize = 0;
      final files = await _cacheDir!.list().toList();

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
}
