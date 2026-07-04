import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/api_endpoints.dart';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';

/// 整合包元数据
class ModpackManifest {
  final String name;
  final String version;
  final String? author;
  final String? description;
  final String? icon;
  final String gameVersion;
  final String? modLoader;
  final String? loaderVersion;
  final List<ModpackMod> mods;
  final String? overrides;

  ModpackManifest({
    required this.name,
    required this.version,
    this.author,
    this.description,
    this.icon,
    required this.gameVersion,
    this.modLoader,
    this.loaderVersion,
    this.mods = const [],
    this.overrides,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'icon': icon,
      'gameVersion': gameVersion,
      'modLoader': modLoader,
      'loaderVersion': loaderVersion,
      'mods': mods.map((m) => m.toJson()).toList(),
      'overrides': overrides,
    };
  }

  factory ModpackManifest.fromJson(Map<String, dynamic> json) {
    return ModpackManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      author: json['author'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      gameVersion: json['gameVersion'] as String,
      modLoader: json['modLoader'] as String?,
      loaderVersion: json['loaderVersion'] as String?,
      mods: (json['mods'] as List<dynamic>?)
              ?.map((e) => ModpackMod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overrides: json['overrides'] as String?,
    );
  }
}

/// 整合包中的Mod信息
class ModpackMod {
  final String name;
  final String? version;
  final String? downloadUrl;
  final String? sha1;
  final int? size;
  final bool optional;
  final String? projectId;
  final String? fileId;
  final String? fileName;

  ModpackMod({
    required this.name,
    this.version,
    this.downloadUrl,
    this.sha1,
    this.size,
    this.optional = false,
    this.projectId,
    this.fileId,
    this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'downloadUrl': downloadUrl,
      'sha1': sha1,
      'size': size,
      'optional': optional,
      'projectId': projectId,
      'fileId': fileId,
      'fileName': fileName,
    };
  }

  factory ModpackMod.fromJson(Map<String, dynamic> json) {
    return ModpackMod(
      name: json['name'] as String,
      version: json['version'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      sha1: json['sha1'] as String?,
      size: json['size'] as int?,
      optional: json['optional'] as bool? ?? false,
      projectId: json['projectId'] as String?,
      fileId: json['fileId'] as String?,
      fileName: json['fileName'] as String?,
    );
  }
}

/// 整合包安装状态
enum ModpackInstallStatus {
  idle,
  downloadingMods,
  downloadingOverrides,
  extracting,
  settingUp,
  completed,
  error,
}

/// 整合包安装进度
class ModpackInstallProgress {
  final ModpackInstallStatus status;
  final double progress;
  final int currentMod;
  final int totalMods;
  final String? currentFile;
  final String? error;

  ModpackInstallProgress({
    required this.status,
    this.progress = 0,
    this.currentMod = 0,
    this.totalMods = 0,
    this.currentFile,
    this.error,
  });
}

/// 整合包管理器
class ModpackManager {
  static ModpackManager? _instance;

  final Logger _logger = Logger('ModpackManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 整合包目录
  Directory? _modpackDir;

  /// 当前安装进度回调
  void Function(ModpackInstallProgress)? _onProgress;

  /// 是否正在安装
  bool _isInstalling = false;

  ModpackManager._internal();

  /// 获取单例实例
  static ModpackManager get instance {
    return ServiceLocator.instance.tryGet<ModpackManager>() ??
        (_instance ??= ModpackManager._internal());
  }

  /// 工厂构造函数
  factory ModpackManager() => instance;

  /// 初始化整合包管理器
  Future<void> initialize() async {
    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _modpackDir = Directory(path.join(supportDir, 'modpacks'));

      if (!await _modpackDir!.exists()) {
        await _modpackDir!.create(recursive: true);
      }

      _logger.info('Modpack manager initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize modpack manager', e, stackTrace);
    }
  }

  /// 从文件导入整合包
  Future<ModpackManifest?> importModpack(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.error('Modpack file not found: $filePath');
        return null;
      }

      // 这里应该解压文件并解析
      // 简化版本：假设是JSON manifest文件
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final manifest = ModpackManifest.fromJson(json);
      _logger.info('Imported modpack: ${manifest.name}');

      return manifest;
    } catch (e, stackTrace) {
      _logger.error('Failed to import modpack', e, stackTrace);
      return null;
    }
  }

  /// 安装整合包
  Future<bool> installModpack({
    required ModpackManifest manifest,
    required String targetPath,
    void Function(ModpackInstallProgress)? onProgress,
  }) async {
    if (_isInstalling) {
      _logger.warn('Installation already in progress');
      return false;
    }

    _isInstalling = true;
    _onProgress = onProgress;

    try {
      _logger.info('Installing modpack: ${manifest.name}');

      // 创建目标目录
      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 下载Mod
      if (manifest.mods.isNotEmpty) {
        _emitProgress(ModpackInstallProgress(
          status: ModpackInstallStatus.downloadingMods,
          progress: 0,
          totalMods: manifest.mods.length,
        ));

        final instanceDir = Directory(targetPath);

        // 确保 mods 目录存在
        final modsDir = Directory(path.join(instanceDir.path, 'mods'));
        if (!await modsDir.exists()) {
          await modsDir.create(recursive: true);
        }

        for (int i = 0; i < manifest.mods.length; i++) {
          final mod = manifest.mods[i];

          // 跳过可选Mod
          if (mod.optional) continue;

          _emitProgress(ModpackInstallProgress(
            status: ModpackInstallStatus.downloadingMods,
            progress: i / manifest.mods.length,
            currentMod: i + 1,
            totalMods: manifest.mods.length,
            currentFile: mod.name,
          ));

          try {
            String? downloadUrl;

            if (mod.downloadUrl != null && mod.downloadUrl!.isNotEmpty) {
              // 有直接下载 URL（Modrinth 格式）
              downloadUrl = mod.downloadUrl;
            } else if (mod.projectId != null && mod.fileId != null) {
              // CurseForge 格式：通过 API 获取下载 URL
              downloadUrl = await _getCurseForgeDownloadUrl(mod.projectId!, mod.fileId!);
            }

            if (downloadUrl != null) {
              final savePath = path.join(
                modsDir.path,
                mod.fileName ?? '${mod.name}.jar',
              );
              await _downloadFile(downloadUrl, savePath);
              _logger.info('Downloaded mod: ${mod.name}');
            } else {
              _logger.warn('No download URL for mod: ${mod.name}');
            }
          } catch (e) {
            _logger.warn('Failed to download mod: ${mod.name}: $e');
            // 继续下载其他 Mod，不中断整个流程
          }
        }
      }

      // 应用覆盖文件
      if (manifest.overrides != null && manifest.overrides!.isNotEmpty) {
        _emitProgress(ModpackInstallProgress(
          status: ModpackInstallStatus.downloadingOverrides,
          progress: 0,
        ));

        // 从解压的临时目录中找到 overrides 目录
        final sourceOverridesDir = Directory(path.join(targetPath, manifest.overrides!));
        if (await sourceOverridesDir.exists()) {
          await _copyDirectory(sourceOverridesDir, Directory(targetPath));
          _logger.info('Applied overrides from: ${manifest.overrides}');
        }
      }

      // 设置实例
      _emitProgress(ModpackInstallProgress(
        status: ModpackInstallStatus.settingUp,
        progress: 0.8,
      ));

      // 创建实例配置
      final configFile = File(path.join(targetPath, 'modpack.json'));
      await configFile.writeAsString(jsonEncode({
        'name': manifest.name,
        'version': manifest.version,
        'gameVersion': manifest.gameVersion,
        'installedAt': DateTime.now().toIso8601String(),
      }));

      _emitProgress(ModpackInstallProgress(
        status: ModpackInstallStatus.completed,
        progress: 1,
      ));

      _logger.info('Successfully installed modpack: ${manifest.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to install modpack', e, stackTrace);
      _emitProgress(ModpackInstallProgress(
        status: ModpackInstallStatus.error,
        error: e.toString(),
      ));
      return false;
    } finally {
      _isInstalling = false;
      _onProgress = null;
    }
  }

  /// 获取已安装的整合包列表
  Future<List<InstalledModpack>> getInstalledModpacks() async {
    final modpacks = <InstalledModpack>[];

    if (_modpackDir == null) return modpacks;

    await for (final entity in _modpackDir!.list()) {
      if (entity is Directory) {
        final configFile = File(path.join(entity.path, 'modpack.json'));
        if (await configFile.exists()) {
          try {
            final content = await configFile.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;

            modpacks.add(InstalledModpack(
              name: json['name'] as String,
              version: json['version'] as String,
              gameVersion: json['gameVersion'] as String,
              path: entity.path,
              installedAt: DateTime.parse(json['installedAt'] as String),
            ));
          } catch (e) {
            // 忽略无效的整合包
          }
        }
      }
    }

    modpacks.sort((a, b) => b.installedAt.compareTo(a.installedAt));
    return modpacks;
  }

  /// 删除已安装的整合包
  Future<bool> deleteModpack(String modpackPath) async {
    try {
      final dir = Directory(modpackPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _logger.info('Deleted modpack at: $modpackPath');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete modpack', e, stackTrace);
      return false;
    }
  }

  /// 导出当前实例为整合包
  Future<bool> exportModpack({
    required String instancePath,
    required String outputPath,
    required String name,
    required String version,
    String? description,
    String? author,
    void Function(ModpackInstallProgress)? onProgress,
  }) async {
    try {
      _logger.info('Exporting modpack: $name');

      // 扫描Mod
      final modsDir = Directory(path.join(instancePath, 'mods'));
      final mods = <ModpackMod>[];

      if (await modsDir.exists()) {
        await for (final file in modsDir.list()) {
          if (file is File) {
            final name = path.basenameWithoutExtension(file.path);
            mods.add(ModpackMod(name: name));
          }
        }
      }

      // 创建Manifest
      final manifest = ModpackManifest(
        name: name,
        version: version,
        author: author,
        description: description,
        gameVersion: 'unknown', // 应该从实例读取
        mods: mods,
      );

      // 这里应该打包文件
      // 简化实现：只保存manifest
      final outputFile = File(outputPath);
      await outputFile.writeAsString(jsonEncode(manifest.toJson()));

      _logger.info('Exported modpack to: $outputPath');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to export modpack', e, stackTrace);
      return false;
    }
  }

  /// 发送进度更新
  void _emitProgress(ModpackInstallProgress progress) {
    if (_onProgress != null) {
      _onProgress!(progress);
    }
  }

  /// 递归复制目录内容
  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final targetPath = path.join(target.path, relativePath);
      if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      }
    }
  }

  /// 下载单个文件
  Future<void> _downloadFile(String url, String savePath) async {
    final saveDir = Directory(path.dirname(savePath));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    final networkClient = NetworkClient();
    await networkClient.downloadFile(url, savePath);
  }

  /// 通过 CurseForge API 获取 Mod 文件的下载 URL
  Future<String?> _getCurseForgeDownloadUrl(String projectId, String fileId) async {
    try {
      final networkClient = NetworkClient();
      final url = '${ApiEndpoints.curseforgeApi}/mods/$projectId/files/$fileId';
      final response = await networkClient.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final fileData = data['data'] as Map<String, dynamic>?;
        return fileData?['downloadUrl'] as String?;
      }
      _logger.warn('CurseForge API returned ${response.statusCode} for mod $projectId file $fileId');
      return null;
    } catch (e) {
      _logger.warn('Failed to get CurseForge download URL for $projectId/$fileId: $e');
      return null;
    }
  }

  /// 是否正在安装
  bool get isInstalling => _isInstalling;
}

/// 已安装的整合包信息
class InstalledModpack {
  final String name;
  final String version;
  final String gameVersion;
  final String path;
  final DateTime installedAt;

  InstalledModpack({
    required this.name,
    required this.version,
    required this.gameVersion,
    required this.path,
    required this.installedAt,
  });
}
