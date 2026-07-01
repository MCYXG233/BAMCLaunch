import 'dart:async';
import 'dart:convert';
import '../core/network_client.dart';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../di/service_locator.dart';

/// 镜像源信息类
///
/// 用于存储和管理单个镜像源的相关信息，包括：
/// - 镜像的唯一标识符
/// - 显示名称
/// - 基础URL地址
/// - 是否为内置镜像
/// - 是否为官方镜像
/// - 优先级（数值越小优先级越高）
///
/// 该类支持JSON序列化和反序列化，便于配置的持久化存储。
class MirrorInfo {
  /// 镜像源的唯一标识符
  ///
  /// 用于在系统中唯一标识一个镜像源，例如 'official'、'bmclapi2' 等
  final String id;

  /// 镜像源的显示名称
  ///
  /// 用于在用户界面中展示，例如 'Mojang 官方源'、'BMCLAPI-2' 等
  final String name;

  /// 镜像源的基础URL地址
  ///
  /// 例如 'https://bmclapi2.bangbang93.com'
  final String url;

  /// 是否为内置镜像
  ///
  /// 内置镜像由程序预设，用户无法删除
  final bool isBuiltIn;

  /// 是否为官方镜像
  ///
  /// 官方镜像指 Mojang 官方源，下载URL的处理逻辑与其他镜像不同
  final bool isOfficial;

  /// 镜像源的优先级
  ///
  /// 数值越小优先级越高，默认为0
  /// 用于在自动选择镜像时作为排序依据
  final int priority;

  /// 创建镜像源信息实例
  ///
  /// [id] 和 [name] 为必填参数
  /// [url] 为必填参数，指定镜像源的基础地址
  /// [isBuiltIn] 默认为 false，标记是否为内置镜像
  /// [isOfficial] 默认为 false，标记是否为官方镜像
  /// [priority] 默认为 0，数值越小优先级越高
  MirrorInfo({
    required this.id,
    required this.name,
    required this.url,
    this.isBuiltIn = false,
    this.isOfficial = false,
    this.priority = 0,
  });

  /// 将镜像信息转换为JSON格式
  ///
  /// 返回一个包含所有镜像信息的Map，用于配置的持久化存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'isBuiltIn': isBuiltIn,
      'isOfficial': isOfficial,
      'priority': priority,
    };
  }

  /// 从JSON数据创建镜像信息实例
  ///
  /// [json] 包含镜像信息的Map对象
  ///
  /// 如果JSON中缺少可选字段，将使用默认值：
  /// - isBuiltIn: false
  /// - isOfficial: false
  /// - priority: 0
  factory MirrorInfo.fromJson(Map<String, dynamic> json) {
    return MirrorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      isOfficial: json['isOfficial'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
    );
  }

  /// 创建当前镜像信息的副本，可选择性地修改部分字段
  ///
  /// 所有参数都是可选的，未提供的参数将保持原值不变
  /// 返回一个新的 MirrorInfo 实例
  MirrorInfo copyWith({
    String? id,
    String? name,
    String? url,
    bool? isBuiltIn,
    bool? isOfficial,
    int? priority,
  }) {
    return MirrorInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isOfficial: isOfficial ?? this.isOfficial,
      priority: priority ?? this.priority,
    );
  }
}

/// 镜像测速结果类
///
/// 用于存储单个镜像源的测速测试结果，包括：
/// - 被测试的镜像源信息
/// - 是否可用
/// - 响应延迟（毫秒）
/// - 错误信息（如果测试失败）
///
/// 该类主要用于 [MirrorManager.speedTestAllMirrors] 方法的返回结果
class MirrorSpeedTestResult {
  /// 被测试的镜像源信息
  final MirrorInfo mirror;

  /// 镜像源是否可用
  ///
  /// 如果HTTP请求成功且返回状态码为200，则为true
  final bool isAvailable;

  /// 响应延迟（毫秒）
  ///
  /// 只有当 [isAvailable] 为 true 时此值才有意义
  final int latencyMs;

  /// 错误信息
  ///
  /// 当 [isAvailable] 为 false 时，包含具体的错误原因
  /// 可能是HTTP状态码错误或网络异常信息
  final String? errorMessage;

  /// 创建测速结果实例
  ///
  /// [mirror] 和 [isAvailable] 为必填参数
  /// [latencyMs] 默认为 0
  /// [errorMessage] 默认为 null
  MirrorSpeedTestResult({
    required this.mirror,
    required this.isAvailable,
    this.latencyMs = 0,
    this.errorMessage,
  });
}

/// 镜像管理器接口
///
/// 定义了镜像管理器的标准接口，包括：
/// - 获取和管理镜像列表
/// - 设置和获取当前选中的镜像
/// - 镜像测速功能
/// - 自动选择最快镜像
/// - 生成下载URL
/// - 配置的保存和加载
///
/// 使用接口可以方便地进行单元测试和实现不同的镜像管理策略
abstract class IMirrorManager {
  /// 获取所有可用的镜像列表
  ///
  /// 包括内置镜像和用户添加的自定义镜像
  List<MirrorInfo> get allMirrors;

  /// 获取当前选中的镜像源
  ///
  /// 返回用户当前选择的镜像源信息
  MirrorInfo get currentMirror;

  /// 获取最近一次测速的结果
  ///
  /// 返回所有镜像源的测速结果列表
  /// 如果尚未进行测速，返回空列表
  List<MirrorSpeedTestResult> get speedTestResults;

  /// 设置当前使用的镜像源
  ///
  /// [mirrorId] 要设置的镜像源ID
  /// 如果提供的ID不存在于镜像列表中，则不会进行任何更改
  void setCurrentMirror(String mirrorId);

  /// 添加自定义镜像源
  ///
  /// [mirror] 要添加的镜像源信息
  /// 添加后会自动保存配置
  Future<void> addCustomMirror(MirrorInfo mirror);

  /// 移除自定义镜像源
  ///
  /// [mirrorId] 要移除的镜像源ID
  /// 只能移除用户添加的自定义镜像，无法移除内置镜像
  /// 如果移除的是当前选中的镜像，会自动切换到第一个内置镜像
  Future<void> removeCustomMirror(String mirrorId);

  /// 对所有镜像源进行测速测试
  ///
  /// 并发测试所有镜像源的响应速度
  /// 返回包含所有测速结果的列表
  Future<List<MirrorSpeedTestResult>> speedTestAllMirrors();

  /// 自动选择最快的镜像源
  ///
  /// 首先对所有镜像源进行测速
  /// 然后选择延迟最低的可用镜像作为当前镜像
  /// 如果没有可用的镜像，则返回第一个内置镜像
  Future<MirrorInfo> autoSelectFastestMirror();

  /// 获取指定镜像源的下载URL
  ///
  /// [path] 原始下载路径
  /// [mirrorId] 镜像源ID
  ///
  /// 根据镜像源的类型和配置，将原始路径转换为完整的下载URL
  /// 对于官方镜像，会特殊处理URL格式
  String getDownloadUrl(String path, String mirrorId);

  /// 保存镜像配置到持久化存储
  ///
  /// 包括自定义镜像列表和当前选中的镜像ID
  Future<void> saveConfig();

  /// 从持久化存储加载镜像配置
  ///
  /// 恢复之前保存的自定义镜像列表和选中的镜像ID
  Future<void> loadConfig();
}

/// 镜像管理器实现类
///
/// 实现了 [IMirrorManager] 接口，提供完整的镜像源管理功能：
/// - 管理内置镜像源（Mojang官方、BMCLAPI等）
/// - 支持用户添加自定义镜像源
/// - 提供镜像测速功能
/// - 自动选择最快镜像
/// - 配置的持久化存储
///
/// 该类采用单例模式，确保全局只有一个镜像管理器实例
class MirrorManager implements IMirrorManager {
  /// 单例实例
  static MirrorManager? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例，如果实例不存在则创建
  factory MirrorManager() {
    return _instance ??= MirrorManager._internal();
  }

  /// 私有内部构造函数
  ///
  /// 用于创建单例实例
  MirrorManager._internal();

  /// 获取单例实例的静态方法
  ///
  /// 提供更直观的单例访问方式
  static MirrorManager get instance =>
      ServiceLocator.instance.tryGet<MirrorManager>() ??
      (_instance ??= MirrorManager._internal());

  /// 配置管理器实例
  ///
  /// 用于读写镜像配置到持久化存储
  final ConfigManager _configManager = ConfigManager();

  /// 内置镜像列表
  ///
  /// 包含程序预设的镜像源，按优先级排序：
  /// - official: Mojang官方源（优先级最高）
  /// - bmclapi2: BMCLAPI-2镜像源
  /// - bmclapi: BMCLAPI镜像源
  /// - mcbbs: MCBBS镜像源
  ///
  /// 这些镜像源无法被用户删除
  static final List<MirrorInfo> _builtInMirrors = [
    MirrorInfo(
      id: 'official',
      name: 'Mojang 官方源',
      url: 'https://launcher.mojang.com',
      isBuiltIn: true,
      isOfficial: true,
      priority: 0,
    ),
    MirrorInfo(
      id: 'bmclapi2',
      name: 'BMCLAPI-2',
      url: 'https://bmclapi2.bangbang93.com',
      isBuiltIn: true,
      priority: 1,
    ),
    MirrorInfo(
      id: 'bmclapi',
      name: 'BMCLAPI',
      url: 'https://bmclapi.bangbang93.com',
      isBuiltIn: true,
      priority: 2,
    ),
    MirrorInfo(
      id: 'mcbbs',
      name: 'MCBBS',
      url: 'https://download.mcbbs.net',
      isBuiltIn: true,
      priority: 3,
    ),
  ];

  /// 用户自定义镜像列表
  ///
  /// 存储用户添加的镜像源，可以随时添加和删除
  List<MirrorInfo> _customMirrors = [];

  /// 当前选中的镜像ID
  ///
  /// 默认使用 'bmclapi2' 作为初始镜像
  String _selectedMirrorId = 'bmclapi2';

  /// 测速结果缓存
  ///
  /// 存储最近一次测速的结果，避免重复测速
  List<MirrorSpeedTestResult> _speedTestResults = [];

  /// 是否正在进行测速
  ///
  /// 用于防止重复测速，当正在测速时为 true
  bool _isSpeedTesting = false;

  /// 获取所有可用的镜像列表
  ///
  /// 合并内置镜像和自定义镜像，返回完整的镜像列表
  @override
  List<MirrorInfo> get allMirrors {
    // 创建新列表，先添加内置镜像
    final all = <MirrorInfo>[..._builtInMirrors];
    // 再添加用户自定义镜像
    all.addAll(_customMirrors);
    return all;
  }

  /// 获取当前选中的镜像源
  ///
  /// 根据存储的镜像ID查找对应的镜像信息
  /// 如果找不到匹配的镜像，则返回第一个内置镜像作为默认值
  @override
  MirrorInfo get currentMirror {
    return allMirrors.firstWhere(
      (m) => m.id == _selectedMirrorId,
      // 如果找不到，使用第一个内置镜像作为默认值
      orElse: () => _builtInMirrors.first,
    );
  }

  /// 获取最近一次测速的结果
  @override
  List<MirrorSpeedTestResult> get speedTestResults => _speedTestResults;

  /// 检查是否正在进行测速
  ///
  /// 用于UI显示测速状态
  bool get isSpeedTesting => _isSpeedTesting;

  /// 设置当前使用的镜像源
  ///
  /// [mirrorId] 要设置的镜像源ID
  ///
  /// 只有当镜像ID存在于镜像列表中时才会更新
  /// 更新后会自动保存配置
  @override
  void setCurrentMirror(String mirrorId) {
    // 检查镜像ID是否存在
    if (allMirrors.any((m) => m.id == mirrorId)) {
      _selectedMirrorId = mirrorId;
      // 保存配置到持久化存储
      saveConfig();
    }
  }

  /// 添加自定义镜像源
  ///
  /// [mirror] 要添加的镜像源信息
  ///
  /// 会自动生成唯一的镜像ID（格式：custom_时间戳）
  /// 并标记为非内置镜像
  /// 添加后会自动保存配置
  @override
  Future<void> addCustomMirror(MirrorInfo mirror) async {
    // 创建新的镜像实例，自动生成唯一ID
    final newMirror = mirror.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      isBuiltIn: false,
    );
    _customMirrors.add(newMirror);
    await saveConfig();
  }

  /// 移除自定义镜像源
  ///
  /// [mirrorId] 要移除的镜像源ID
  ///
  /// 只能移除非内置的镜像（isBuiltIn为false）
  /// 如果移除的是当前选中的镜像，会自动切换到第一个内置镜像
  @override
  Future<void> removeCustomMirror(String mirrorId) async {
    // 只移除非内置镜像
    _customMirrors.removeWhere((m) => m.id == mirrorId && !m.isBuiltIn);
    // 如果移除的是当前选中的镜像，切换到默认镜像
    if (_selectedMirrorId == mirrorId) {
      _selectedMirrorId = _builtInMirrors.first.id;
    }
    await saveConfig();
  }

  /// 对所有镜像源进行测速测试
  ///
  /// 并发测试所有镜像源的响应速度
  /// 如果已经在测速中，直接返回当前的测速结果
  ///
  /// 返回包含所有测速结果的列表，按镜像列表顺序排列
  @override
  Future<List<MirrorSpeedTestResult>> speedTestAllMirrors() async {
    // 防止重复测速
    if (_isSpeedTesting) {
      return _speedTestResults;
    }

    _isSpeedTesting = true;
    // 清空之前的测速结果
    _speedTestResults = [];

    try {
      // 并发测试所有镜像
      final futures = allMirrors.map((mirror) => _speedTestMirror(mirror));
      // 等待所有测速完成
      _speedTestResults = await Future.wait(futures);
    } catch (e) {
      // Future.wait 可能因某个镜像测速异常而抛出错误
      // 此时保留已成功的结果
    } finally {
      _isSpeedTesting = false;
    }

    return _speedTestResults;
  }

  /// 对单个镜像源进行测速测试
  ///
  /// [mirror] 要测试的镜像源信息
  ///
  /// 测试方法：
  /// - 对于官方镜像：访问版本清单API
  /// - 对于其他镜像：访问特定版本的目录
  ///
  /// 超时时间设置为10秒
  /// 返回测速结果，包含是否可用、延迟和错误信息
  Future<MirrorSpeedTestResult> _speedTestMirror(MirrorInfo mirror) async {
    // 启动计时器
    final stopwatch = Stopwatch()..start();

    try {
      final networkClient = NetworkClient();
      String testUrl;

      // 根据镜像类型选择不同的测试URL
      if (mirror.isOfficial) {
        // 官方镜像测试版本清单API
        testUrl = 'https://launchermeta.mojang.com/mc/game/version_manifest.json';
      } else {
        // 第三方镜像测试特定版本目录
        testUrl = '${mirror.url}/minecraft/version/1.20.4';
      }

      // 发送HTTP请求，超时时间10秒
      final response = await networkClient.get(
        testUrl,
        timeoutSeconds: 10,
      );

      stopwatch.stop();

      // 根据HTTP状态码判断是否可用
      if (response.statusCode == 200) {
        return MirrorSpeedTestResult(
          mirror: mirror,
          isAvailable: true,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        // HTTP状态码非200，记录错误
        return MirrorSpeedTestResult(
          mirror: mirror,
          isAvailable: false,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      stopwatch.stop();
      // 捕获异常，记录错误信息
      return MirrorSpeedTestResult(
        mirror: mirror,
        isAvailable: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 自动选择最快的镜像源
  ///
  /// 首先对所有镜像源进行测速
  /// 然后从可用的镜像中选择延迟最低的
  /// 更新当前选中的镜像并保存配置
  ///
  /// 如果没有可用的镜像，返回第一个内置镜像
  @override
  Future<MirrorInfo> autoSelectFastestMirror() async {
    // 执行测速
    final results = await speedTestAllMirrors();

    // 筛选可用的镜像，并按延迟排序
    final availableMirrors = results
        .where((r) => r.isAvailable)
        .toList()
      // 按延迟从小到大排序
      ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));

    // 如果有可用的镜像，选择延迟最低的
    if (availableMirrors.isNotEmpty) {
      final fastest = availableMirrors.first.mirror;
      _selectedMirrorId = fastest.id;
      await saveConfig();
      return fastest;
    }

    // 没有可用镜像，返回默认镜像
    return _builtInMirrors.first;
  }

  /// 获取指定镜像源的下载URL
  ///
  /// [path] 原始下载路径
  /// [mirrorId] 镜像源ID
  ///
  /// URL转换规则：
  /// 1. 对于官方镜像：
  ///    - 如果path已经是完整URL，直接返回
  ///    - 否则拼接官方域名
  /// 2. 对于第三方镜像：
  ///    - 如果path是完整URL，需要替换域名
  ///    - 根据路径前缀（/maven/、/assets/、/libraries/等）进行相应转换
  ///    - 如果path是相对路径，直接拼接镜像URL
  @override
  String getDownloadUrl(String path, String mirrorId) {
    // 查找指定的镜像源
    final mirror = allMirrors.firstWhere(
      (m) => m.id == mirrorId,
      // 找不到时使用默认镜像
      orElse: () => _builtInMirrors.first,
    );

    // 官方镜像的URL处理
    if (mirror.isOfficial) {
      // 如果已经是完整URL，直接返回
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      // 拼接官方域名
      return 'https://launcher.mojang.com$path';
    }

    // 第三方镜像的URL处理
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // 解析原始URL
      final uri = Uri.parse(path);
      final pathPart = uri.path;

      // 根据路径前缀进行转换
      // Maven资源路径转换
      if (pathPart.startsWith('/maven/')) {
        return '${mirror.url}/maven${pathPart.substring(6)}';
      }
      // 资源文件路径转换
      else if (pathPart.startsWith('/assets/')) {
        return '${mirror.url}/assets${pathPart.substring(7)}';
      }
      // 库文件路径转换
      else if (pathPart.startsWith('/libraries/')) {
        return '${mirror.url}/libraries${pathPart.substring(10)}';
      }
      // 版本文件路径转换
      else if (pathPart.contains('/versions/')) {
        return '${mirror.url}/versions${pathPart.split('/versions').last}';
      }
    }

    // 相对路径，直接拼接
    return '${mirror.url}$path';
  }

  /// 保存镜像配置到持久化存储
  ///
  /// 保存内容包括：
  /// - 自定义镜像列表（JSON格式）
  /// - 当前选中的镜像ID
  @override
  Future<void> saveConfig() async {
    // 将自定义镜像列表转换为JSON字符串
    final customMirrorsJson = _customMirrors.map((m) => m.toJson()).toList();
    await _configManager.setString(
      ConfigKeys.customMirrors,
      jsonEncode(customMirrorsJson),
    );
    // 保存当前选中的镜像ID
    await _configManager.setString(ConfigKeys.selectedMirror, _selectedMirrorId);
  }

  /// 从持久化存储加载镜像配置
  ///
  /// 加载内容包括：
  /// - 自定义镜像列表
  /// - 当前选中的镜像ID
  ///
  /// 如果加载失败或配置不存在，使用默认值
  @override
  Future<void> loadConfig() async {
    try {
      // 加载自定义镜像列表
      final customMirrorsStr = _configManager.getString(ConfigKeys.customMirrors);
      if (customMirrorsStr != null && customMirrorsStr.isNotEmpty) {
        try {
          // 解析JSON数据
          final decoded = jsonDecode(customMirrorsStr);
          if (decoded is List) {
            _customMirrors = [];
            for (final item in decoded) {
              try {
                if (item is Map<String, dynamic>) {
                  _customMirrors.add(MirrorInfo.fromJson(item));
                }
              } catch (e) {
                // 跳过无效的镜像条目
              }
            }
          }
        } catch (e) {
          // 解析失败，使用空列表
          _customMirrors = [];
        }
      }

      // 加载当前选中的镜像ID
      final selectedMirror = _configManager.getString(ConfigKeys.selectedMirror);
      // 验证镜像ID是否有效
      if (selectedMirror != null && allMirrors.any((m) => m.id == selectedMirror)) {
        _selectedMirrorId = selectedMirror;
      }
    } catch (e) {
      // 配置加载失败，使用默认值
      _customMirrors = [];
      _selectedMirrorId = 'bmclapi2';
    }
  }
}

/// 配置键扩展
///
/// 为 [ConfigKeys] 类添加镜像管理相关的配置键常量
/// 用于在配置存储中标识镜像相关的配置项
extension ConfigKeysMirrorExtension on ConfigKeys {
  /// 自定义镜像列表配置键
  ///
  /// 用于存储用户添加的自定义镜像源列表（JSON格式）
  static const String customMirrors = 'customMirrors';

  /// 当前选中镜像配置键
  ///
  /// 用于存储用户当前选择的镜像源ID
  static const String selectedMirror = 'selectedMirror';
}