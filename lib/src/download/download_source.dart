import 'dart:async';
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../di/service_locator.dart';
import 'mirror_manager.dart';

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
    return '${ApiEndpoints.mojangLauncher}$path';
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        ApiEndpoints.minecraftVersionManifest,
        timeoutSeconds: 10,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// 镜像源管理器
///
/// 已废弃：请使用 [MirrorManager] 替代。此类保留用于向后兼容，
/// 内部已委托给 [MirrorManager]。
@Deprecated('Use MirrorManager instead. This class delegates to MirrorManager.')
class MirrorSourceManager {
  static MirrorSourceManager? _instance;

  factory MirrorSourceManager() {
    return _instance ??= MirrorSourceManager._internal();
  }

  MirrorSourceManager._internal();

  static MirrorSourceManager get instance =>
      ServiceLocator.instance.tryGet<MirrorSourceManager>() ??
      (_instance ??= MirrorSourceManager._internal());

  /// 内部委托给 MirrorManager
  MirrorManager get _mirrorManager => MirrorManager.instance;

  List<BMCLApiDownloadSource>? _cachedMirrorSources;

  /// 获取所有 BMCLAPI 镜像源
  ///
  /// 从 [MirrorManager] 获取所有镜像并转换为 [BMCLApiDownloadSource] 列表
  List<BMCLApiDownloadSource> get allMirrorSources {
    _cachedMirrorSources ??= _mirrorManager.allMirrors
        .where((m) => !m.isOfficial)
        .map((m) => BMCLApiDownloadSource(m.url, m.name))
        .toList();
    return _cachedMirrorSources!;
  }

  /// 获取当前选中的镜像源
  BMCLApiDownloadSource get currentMirrorSource {
    final mirror = _mirrorManager.currentMirror;
    if (mirror.isOfficial) {
      return allMirrorSources.isNotEmpty
          ? allMirrorSources[0]
          : BMCLApiDownloadSource(ApiEndpoints.bmclapi2, 'BMCLAPI-2');
    }
    return BMCLApiDownloadSource(mirror.url, mirror.name);
  }

  /// 设置当前选中的镜像源索引
  void setSelectedMirrorIndex(int index) {
    final nonOfficial = _mirrorManager.allMirrors.where((m) => !m.isOfficial).toList();
    if (index >= 0 && index < nonOfficial.length) {
      _mirrorManager.setCurrentMirror(nonOfficial[index].id);
      _cachedMirrorSources = null; // 清除缓存
    }
  }

  /// 获取当前选中的镜像源索引
  int get selectedMirrorIndex {
    final currentId = _mirrorManager.currentMirror.id;
    final nonOfficial = _mirrorManager.allMirrors.where((m) => !m.isOfficial).toList();
    return nonOfficial.indexWhere((m) => m.id == currentId);
  }

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
    final fastest = await _mirrorManager.autoSelectFastestMirror();
    if (!fastest.isOfficial) {
      return BMCLApiDownloadSource(fastest.url, fastest.name);
    }
    // 回退到第一个非官方镜像
    return allMirrorSources.isNotEmpty
        ? allMirrorSources[0]
        : BMCLApiDownloadSource(ApiEndpoints.bmclapi2, 'BMCLAPI-2');
  }

  /// 切换到下一个镜像源
  BMCLApiDownloadSource switchToNextMirror() {
    final nonOfficial = _mirrorManager.allMirrors.where((m) => !m.isOfficial).toList();
    final currentId = _mirrorManager.currentMirror.id;
    int currentIndex = nonOfficial.indexWhere((m) => m.id == currentId);
    final nextIndex = (currentIndex + 1) % nonOfficial.length;
    _mirrorManager.setCurrentMirror(nonOfficial[nextIndex].id);
    _cachedMirrorSources = null;
    return BMCLApiDownloadSource(nonOfficial[nextIndex].url, nonOfficial[nextIndex].name);
  }
}