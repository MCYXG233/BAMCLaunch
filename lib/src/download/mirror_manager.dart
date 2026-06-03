import 'dart:async';
import 'dart:convert';
import '../core/network_client.dart';
import '../config/config_manager.dart';
import '../config/config_keys.dart';

/// 镜像源信息
class MirrorInfo {
  final String id;
  final String name;
  final String url;
  final bool isBuiltIn;
  final bool isOfficial;
  final int priority;

  MirrorInfo({
    required this.id,
    required this.name,
    required this.url,
    this.isBuiltIn = false,
    this.isOfficial = false,
    this.priority = 0,
  });

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

/// 镜像测速结果
class MirrorSpeedTestResult {
  final MirrorInfo mirror;
  final bool isAvailable;
  final int latencyMs;
  final String? errorMessage;

  MirrorSpeedTestResult({
    required this.mirror,
    required this.isAvailable,
    this.latencyMs = 0,
    this.errorMessage,
  });
}

/// 镜像管理器接口
abstract class IMirrorManager {
  /// 获取所有镜像列表
  List<MirrorInfo> get allMirrors;

  /// 获取当前选中的镜像
  MirrorInfo get currentMirror;

  /// 获取测速结果
  List<MirrorSpeedTestResult> get speedTestResults;

  /// 设置当前选中的镜像
  void setCurrentMirror(String mirrorId);

  /// 添加自定义镜像
  Future<void> addCustomMirror(MirrorInfo mirror);

  /// 移除自定义镜像
  Future<void> removeCustomMirror(String mirrorId);

  /// 测速所有镜像
  Future<List<MirrorSpeedTestResult>> speedTestAllMirrors();

  /// 自动选择最快镜像
  Future<MirrorInfo> autoSelectFastestMirror();

  /// 获取镜像下载URL
  String getDownloadUrl(String path, String mirrorId);

  /// 保存配置
  Future<void> saveConfig();

  /// 加载配置
  Future<void> loadConfig();
}

/// 镜像管理器实现
class MirrorManager implements IMirrorManager {
  static MirrorManager? _instance;

  factory MirrorManager() {
    return _instance ??= MirrorManager._internal();
  }

  MirrorManager._internal();

  static MirrorManager get instance =>
      _instance ??= MirrorManager._internal();

  final ConfigManager _configManager = ConfigManager();

  /// 内置镜像列表
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

  /// 自定义镜像列表
  List<MirrorInfo> _customMirrors = [];

  /// 当前选中的镜像ID
  String _selectedMirrorId = 'bmclapi2';

  /// 测速结果缓存
  List<MirrorSpeedTestResult> _speedTestResults = [];

  /// 是否正在测速
  bool _isSpeedTesting = false;

  @override
  List<MirrorInfo> get allMirrors {
    final all = <MirrorInfo>[..._builtInMirrors];
    all.addAll(_customMirrors);
    return all;
  }

  @override
  MirrorInfo get currentMirror {
    return allMirrors.firstWhere(
      (m) => m.id == _selectedMirrorId,
      orElse: () => _builtInMirrors.first,
    );
  }

  @override
  List<MirrorSpeedTestResult> get speedTestResults => _speedTestResults;

  bool get isSpeedTesting => _isSpeedTesting;

  @override
  void setCurrentMirror(String mirrorId) {
    if (allMirrors.any((m) => m.id == mirrorId)) {
      _selectedMirrorId = mirrorId;
      saveConfig();
    }
  }

  @override
  Future<void> addCustomMirror(MirrorInfo mirror) async {
    final newMirror = mirror.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      isBuiltIn: false,
    );
    _customMirrors.add(newMirror);
    await saveConfig();
  }

  @override
  Future<void> removeCustomMirror(String mirrorId) async {
    _customMirrors.removeWhere((m) => m.id == mirrorId && !m.isBuiltIn);
    if (_selectedMirrorId == mirrorId) {
      _selectedMirrorId = _builtInMirrors.first.id;
    }
    await saveConfig();
  }

  @override
  Future<List<MirrorSpeedTestResult>> speedTestAllMirrors() async {
    if (_isSpeedTesting) {
      return _speedTestResults;
    }

    _isSpeedTesting = true;
    _speedTestResults = [];

    final futures = allMirrors.map((mirror) => _speedTestMirror(mirror));
    _speedTestResults = await Future.wait(futures);

    _isSpeedTesting = false;
    return _speedTestResults;
  }

  Future<MirrorSpeedTestResult> _speedTestMirror(MirrorInfo mirror) async {
    final stopwatch = Stopwatch()..start();

    try {
      final networkClient = NetworkClient();
      String testUrl;

      if (mirror.isOfficial) {
        testUrl = 'https://launchermeta.mojang.com/mc/game/version_manifest.json';
      } else {
        testUrl = '${mirror.url}/minecraft/version/1.20.4';
      }

      final response = await networkClient.get(
        testUrl,
        timeoutSeconds: 10,
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        return MirrorSpeedTestResult(
          mirror: mirror,
          isAvailable: true,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return MirrorSpeedTestResult(
          mirror: mirror,
          isAvailable: false,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      stopwatch.stop();
      return MirrorSpeedTestResult(
        mirror: mirror,
        isAvailable: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<MirrorInfo> autoSelectFastestMirror() async {
    final results = await speedTestAllMirrors();

    final availableMirrors = results
        .where((r) => r.isAvailable)
        .toList()
      ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));

    if (availableMirrors.isNotEmpty) {
      final fastest = availableMirrors.first.mirror;
      _selectedMirrorId = fastest.id;
      await saveConfig();
      return fastest;
    }

    return _builtInMirrors.first;
  }

  @override
  String getDownloadUrl(String path, String mirrorId) {
    final mirror = allMirrors.firstWhere(
      (m) => m.id == mirrorId,
      orElse: () => _builtInMirrors.first,
    );

    if (mirror.isOfficial) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      return 'https://launcher.mojang.com$path';
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final pathPart = uri.path;

      if (pathPart.startsWith('/maven/')) {
        return '${mirror.url}/maven${pathPart.substring(6)}';
      } else if (pathPart.startsWith('/assets/')) {
        return '${mirror.url}/assets${pathPart.substring(7)}';
      } else if (pathPart.startsWith('/libraries/')) {
        return '${mirror.url}/libraries${pathPart.substring(10)}';
      } else if (pathPart.contains('/versions/')) {
        return '${mirror.url}/versions${pathPart.split('/versions').last}';
      }
    }

    return '${mirror.url}$path';
  }

  @override
  Future<void> saveConfig() async {
    final customMirrorsJson = _customMirrors.map((m) => m.toJson()).toList();
    await _configManager.setString(
      ConfigKeys.customMirrors,
      jsonEncode(customMirrorsJson),
    );
    await _configManager.setString(ConfigKeys.selectedMirror, _selectedMirrorId);
  }

  @override
  Future<void> loadConfig() async {
    final customMirrorsStr = _configManager.getString(ConfigKeys.customMirrors);
    if (customMirrorsStr != null && customMirrorsStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(customMirrorsStr);
        _customMirrors = decoded
            .map((json) => MirrorInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _customMirrors = [];
      }
    }

    final selectedMirror = _configManager.getString(ConfigKeys.selectedMirror);
    if (selectedMirror != null && allMirrors.any((m) => m.id == selectedMirror)) {
      _selectedMirrorId = selectedMirror;
    }
  }
}

/// 配置键扩展
extension ConfigKeysMirrorExtension on ConfigKeys {
  static const String customMirrors = 'customMirrors';
  static const String selectedMirror = 'selectedMirror';
}
