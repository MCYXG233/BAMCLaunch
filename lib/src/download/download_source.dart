import 'dart:async';
import '../core/network_client.dart';
import '../di/service_locator.dart';

/// 下载源接口
abstract class IDownloadSource {
  /// 下载源名称
  String get name;

  /// 获取文件下载URL
  ///
  /// [path] 文件路径
  Future<String> getUrl(String path);

  /// 检查下载源是否可用
  Future<bool> isAvailable();
}

/// BMCLAPI 镜像源实现
class BMCLApiDownloadSource implements IDownloadSource {
  /// BMCLAPI 基础URL
  final String baseUrl;

  @override
  final String name;

  BMCLApiDownloadSource(this.baseUrl, this.name);

  @override
  Future<String> getUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final pathPart = uri.path;

      if (pathPart.startsWith('/maven/')) {
        return '$baseUrl/maven${pathPart.substring(6)}';
      } else if (pathPart.startsWith('/assets/')) {
        return '$baseUrl/assets${pathPart.substring(7)}';
      } else if (pathPart.startsWith('/libraries/')) {
        return '$baseUrl/libraries${pathPart.substring(10)}';
      } else if (pathPart.contains('/versions/')) {
        return '$baseUrl/versions${pathPart.split('/versions').last}';
      }
    }
    return '$baseUrl$path';
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        '$baseUrl/minecraft/version/1.20.4',
        headers: NetworkClient.bmclapiHeaders,
        timeoutSeconds: 5,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// 官方源实现
class OfficialDownloadSource implements IDownloadSource {
  @override
  String get name => 'Official';

  @override
  Future<String> getUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return 'https://launcher.mojang.com$path';
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        'https://launchermeta.mojang.com/mc/game/version_manifest.json',
        timeoutSeconds: 10,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// 镜像源管理器
class MirrorSourceManager {
  static MirrorSourceManager? _instance;

  factory MirrorSourceManager() {
    return _instance ??= MirrorSourceManager._internal();
  }

  MirrorSourceManager._internal();

  static MirrorSourceManager get instance =>
      ServiceLocator.instance.tryGet<MirrorSourceManager>() ??
      (_instance ??= MirrorSourceManager._internal());

  /// 所有可用的 BMCLAPI 镜像源
  static final List<Map<String, String>> _bmclapiMirrors = [
    {
      'url': 'https://bmclapi2.bangbang93.com',
      'name': 'BMCLAPI-2',
    },
    {
      'url': 'https://bmclapi.bangbang93.com',
      'name': 'BMCLAPI',
    },
    {
      'url': 'https://download.mcbbs.net',
      'name': 'MCBBS',
    },
  ];

  List<BMCLApiDownloadSource>? _cachedMirrorSources;

  /// 获取所有 BMCLAPI 镜像源
  List<BMCLApiDownloadSource> get allMirrorSources {
    _cachedMirrorSources ??= _bmclapiMirrors
        .map((mirror) => BMCLApiDownloadSource(mirror['url']!, mirror['name']!))
        .toList();
    return _cachedMirrorSources!;
  }

  /// 当前选中的镜像源索引
  int _selectedMirrorIndex = 0;

  /// 获取当前选中的镜像源
  BMCLApiDownloadSource get currentMirrorSource =>
      allMirrorSources[_selectedMirrorIndex];

  /// 设置当前选中的镜像源索引
  void setSelectedMirrorIndex(int index) {
    if (index >= 0 && index < allMirrorSources.length) {
      _selectedMirrorIndex = index;
    }
  }

  /// 获取当前选中的镜像源索引
  int get selectedMirrorIndex => _selectedMirrorIndex;

  /// 检查所有镜像源的可用性
  Future<List<(BMCLApiDownloadSource, bool)>> checkAllMirrors() async {
    final results = <(BMCLApiDownloadSource, bool)>[];
    for (final source in allMirrorSources) {
      final available = await source.isAvailable();
      results.add((source, available));
    }
    return results;
  }

  /// 自动选择一个可用的镜像源
  Future<BMCLApiDownloadSource> selectAvailableMirror() async {
    final results = await checkAllMirrors();
    
    // 先尝试使用当前选中的镜像源
    final currentResult = results[_selectedMirrorIndex];
    if (currentResult.$2) {
      return currentResult.$1;
    }

    // 查找第一个可用的镜像源
    for (var i = 0; i < results.length; i++) {
      if (results[i].$2 && i != _selectedMirrorIndex) {
        _selectedMirrorIndex = i;
        return results[i].$1;
      }
    }

    // 如果没有可用的镜像源，返回默认的
    return allMirrorSources[0];
  }

  /// 切换到下一个镜像源
  BMCLApiDownloadSource switchToNextMirror() {
    _selectedMirrorIndex = (_selectedMirrorIndex + 1) % allMirrorSources.length;
    return currentMirrorSource;
  }
}