import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/network_client.dart';
import '../core/logger.dart';
import '../core/error_codes.dart';
import '../di/service_locator.dart';
import '../event/event_bus.dart';
import '../event/event.dart';

/// Quilt加载器版本信息
class QuiltVersion {
  /// 版本ID
  final String id;

  /// 构建号
  final int build;

  /// 发布时间
  final DateTime time;

  /// 依赖的Minecraft版本
  final String minecraftVersion;

  /// 加载器版本
  final String loaderVersion;

  /// 短版本号
  final String shortVersion;

  const QuiltVersion({
    required this.id,
    required this.build,
    required this.time,
    required this.minecraftVersion,
    required this.loaderVersion,
    required this.shortVersion,
  });

  factory QuiltVersion.fromJson(Map<String, dynamic> json) {
    return QuiltVersion(
      id: json['id'] as String,
      build: json['build'] as int,
      time: DateTime.parse(json['time'] as String),
      minecraftVersion: json['intermediary']?['version'] as String? ?? '',
      loaderVersion: json['loader']?['version'] as String? ?? '',
      shortVersion: json['shortVersion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'build': build,
      'time': time.toIso8601String(),
      'minecraftVersion': minecraftVersion,
      'loaderVersion': loaderVersion,
      'shortVersion': shortVersion,
    };
  }
}

/// Quilt安装进度事件
class QuiltInstallProgressEvent extends Event {
  final String instanceId;
  final double progress;
  final String stage;
  final String? currentFile;

  QuiltInstallProgressEvent({
    required this.instanceId,
    required this.progress,
    required this.stage,
    this.currentFile,
  });
}

/// Quilt安装完成事件
class QuiltInstallCompletedEvent extends Event {
  final String instanceId;
  final String version;
  final String minecraftVersion;

  QuiltInstallCompletedEvent({
    required this.instanceId,
    required this.version,
    required this.minecraftVersion,
  });
}

/// Quilt安装失败事件
class QuiltInstallFailedEvent extends Event {
  final String instanceId;
  final String error;

  QuiltInstallFailedEvent({
    required this.instanceId,
    required this.error,
  });
}

/// Quilt加载器安装服务
class QuiltInstaller {
  static QuiltInstaller? _instance;
  static QuiltInstaller get instance =>
      ServiceLocator.instance.tryGet<QuiltInstaller>() ??
      (_instance ??= QuiltInstaller._());
  QuiltInstaller._();

  /// Quilt API版本清单地址
  static const String _quiltVersionsUrl = 'https://api.quiltmc.org/v2/versions/';

  final Logger _logger = Logger('QuiltInstaller');
  final NetworkClient _networkClient = NetworkClient();
  final EventBus _eventBus = EventBus.instance;

  /// 获取可用的Quilt版本列表
  Future<List<QuiltVersion>> getQuiltVersions() async {
    try {
      _logger.info('Fetching Quilt versions from QuiltMC API...');

      final response = await _networkClient.get(_quiltVersionsUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Quilt API返回结构: { "versions": [...] }
        final versionsJson = data['versions'] as List<dynamic>? ?? [];

        final versions = <QuiltVersion>[];
        for (final v in versionsJson) {
          try {
            versions.add(QuiltVersion.fromJson(v as Map<String, dynamic>));
          } catch (e) {
            _logger.warning('Failed to parse Quilt version: $e');
          }
        }

        _logger.info('Found ${versions.length} Quilt versions');
        return versions;
      } else {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'HTTP ${response.statusCode}',
          retryable: true,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch Quilt versions', e, stackTrace);
      rethrow;
    }
  }

  /// 获取特定Minecraft版本的Quilt版本列表
  Future<List<QuiltVersion>> getQuiltVersionsForMinecraft(String mcVersion) async {
    final allVersions = await getQuiltVersions();
    return allVersions
        .where((v) => v.minecraftVersion == mcVersion)
        .toList()
      ..sort((a, b) => b.build.compareTo(a.build));
  }

  /// 获取最新稳定版Quilt版本
  Future<QuiltVersion?> getLatestStableQuiltVersion(String mcVersion) async {
    final versions = await getQuiltVersionsForMinecraft(mcVersion);
    if (versions.isEmpty) return null;
    return versions.first;
  }

  /// 下载Quilt安装器
  Future<String> _downloadQuiltInstaller({
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
    void Function(int received, int total)? onProgress,
  }) async {
    final installerVersion = loaderVersion;
    final url = 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/$installerVersion/quilt-installer-$installerVersion.jar';

    _logger.info('Downloading Quilt installer from: $url');

    final downloadDir = Directory(path.join(gameDirectory, 'libraries', 'quilt-installer'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final filePath = path.join(downloadDir.path, 'quilt-installer-$installerVersion.jar');

    await _networkClient.downloadFile(
      url,
      filePath,
      onProgress: onProgress,
    );

    _logger.info('Quilt installer downloaded to: $filePath');
    return filePath;
  }

  /// 下载Quilt Loader库文件
  Future<String> _downloadQuiltLoader({
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
    void Function(int received, int total)? onProgress,
  }) async {
    final url = 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-loader/$loaderVersion/quilt-loader-$loaderVersion.jar';

    _logger.info('Downloading Quilt loader from: $url');

    final downloadDir = Directory(path.join(
      gameDirectory,
      'libraries',
      'org',
      'quiltmc',
      'quilt-loader',
      loaderVersion,
    ));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final filePath = path.join(downloadDir.path, 'quilt-loader-$loaderVersion.jar');

    await _networkClient.downloadFile(
      url,
      filePath,
      onProgress: onProgress,
    );

    _logger.info('Quilt loader downloaded to: $filePath');
    return filePath;
  }

  /// 安装Quilt加载器
  Future<void> installQuilt({
    required String instanceId,
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
    void Function(double progress, String stage, String? currentFile)? onProgress,
  }) async {
    try {
      _logger.info('Installing Quilt $loaderVersion for Minecraft $mcVersion');

      onProgress?.call(0.1, '正在获取下载链接...', null);
      _eventBus.publish(QuiltInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.1,
        stage: '正在获取下载链接...',
      ));

      // 下载Quilt Loader
      onProgress?.call(0.2, '正在下载Quilt Loader...', 'quilt-loader-$loaderVersion.jar');
      _eventBus.publish(QuiltInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.2,
        stage: '正在下载Quilt Loader...',
        currentFile: 'quilt-loader-$loaderVersion.jar',
      ));

      final loaderPath = await _downloadQuiltLoader(
        mcVersion: mcVersion,
        loaderVersion: loaderVersion,
        gameDirectory: gameDirectory,
        onProgress: (received, total) {
          final fileProgress = received / total;
          onProgress?.call(0.2 + fileProgress * 0.3, '正在下载Quilt Loader...', 'quilt-loader-$loaderVersion.jar');
        },
      );

      onProgress?.call(0.5, '正在下载Quilt安装器...', 'quilt-installer-$loaderVersion.jar');
      _eventBus.publish(QuiltInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.5,
        stage: '正在下载Quilt安装器...',
        currentFile: 'quilt-installer-$loaderVersion.jar',
      ));

      // 下载Quilt安装器
      final installerPath = await _downloadQuiltInstaller(
        mcVersion: mcVersion,
        loaderVersion: loaderVersion,
        gameDirectory: gameDirectory,
        onProgress: (received, total) {
          final fileProgress = received / total;
          onProgress?.call(0.5 + fileProgress * 0.3, '正在下载Quilt安装器...', 'quilt-installer-$loaderVersion.jar');
        },
      );

      onProgress?.call(0.8, '正在安装Quilt...', null);
      _eventBus.publish(QuiltInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.8,
        stage: '正在安装Quilt...',
      ));

      // 运行安装器
      await _runQuiltInstaller(
        installerPath: installerPath,
        mcVersion: mcVersion,
        loaderVersion: loaderVersion,
        gameDirectory: gameDirectory,
      );

      // 创建版本JSON
      await _createQuiltVersionJson(
        mcVersion: mcVersion,
        loaderVersion: loaderVersion,
        gameDirectory: gameDirectory,
        loaderPath: loaderPath,
      );

      onProgress?.call(1.0, '安装完成', null);
      _eventBus.publish(QuiltInstallCompletedEvent(
        instanceId: instanceId,
        version: loaderVersion,
        minecraftVersion: mcVersion,
      ));

      _logger.info('Quilt installation completed successfully');

      // 清理安装器
      final installerFile = File(installerPath);
      if (await installerFile.exists()) {
        await installerFile.delete();
        _logger.info('Cleaned up Quilt installer');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to install Quilt', e, stackTrace);
      _eventBus.publish(QuiltInstallFailedEvent(
        instanceId: instanceId,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 运行Quilt安装器
  Future<void> _runQuiltInstaller({
    required String installerPath,
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
  }) async {
    try {
      _logger.info('Running Quilt installer...');

      final result = await Process.run(
        'java',
        [
          '-jar',
          installerPath,
          'install',
          'client',
          mcVersion,
          '--install-dir',
          gameDirectory,
        ],
        workingDirectory: gameDirectory,
      );

      if (result.exitCode != 0) {
        _logger.warning('Quilt installer output: ${result.stdout}');
        _logger.warning('Quilt installer errors: ${result.stderr}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to run Quilt installer', e, stackTrace);
      rethrow;
    }
  }

  /// 创建Quilt版本JSON文件
  Future<void> _createQuiltVersionJson({
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
    required String loaderPath,
  }) async {
    try {
      final id = '$mcVersion-quilt-$loaderVersion';

      // 获取Minecraft原版版本JSON路径
      final baseVersionDir = path.join(gameDirectory, 'versions', mcVersion);
      final baseVersionJsonPath = path.join(baseVersionDir, '$mcVersion.json');

      Map<String, dynamic> baseVersionJson = {};
      if (await File(baseVersionJsonPath).exists()) {
        final content = await File(baseVersionJsonPath).readAsString();
        baseVersionJson = jsonDecode(content) as Map<String, dynamic>;
      }

      // 构建Quilt版本JSON
      final quiltVersionJson = {
        'id': id,
        'inheritsFrom': mcVersion,
        'releaseTime': DateTime.now().toIso8601String(),
        'time': DateTime.now().toIso8601String(),
        'type': 'release',
        'mainClass': baseVersionJson['mainClass'] ?? 'org.quiltmc.loader.impl.launch.knot.KnotClient',
        'arguments': {
          'game': [
            '--fml.quilt.accessWidener',
            r'${libraryDirectory}/org/quiltmc/quilt-access-widener/$loaderVersion/quilt-access-widener-$loaderVersion.jar',
          ],
        },
        'libraries': [
          ...(baseVersionJson['libraries'] as List<dynamic>? ?? []),
          {
            'name': 'org.quiltmc:quilt-loader:$loaderVersion',
            'downloads': {
              'artifact': {
                'path': 'org/quiltmc/quilt-loader/$loaderVersion/quilt-loader-$loaderVersion.jar',
                'sha1': '',  // 实际应该计算SHA1
                'size': 0,  // 实际应该获取文件大小
                'url': 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-loader/$loaderVersion/quilt-loader-$loaderVersion.jar',
              }
            }
          }
        ],
      };

      // 写入版本JSON文件
      final versionDir = path.join(gameDirectory, 'versions', id);
      final versionJsonFile = File(path.join(versionDir, '$id.json'));

      if (!await versionJsonFile.parent.exists()) {
        await versionJsonFile.parent.create(recursive: true);
      }

      await versionJsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(quiltVersionJson),
      );

      _logger.info('Quilt version JSON created at: ${versionJsonFile.path}');
    } catch (e, stackTrace) {
      _logger.error('Failed to create Quilt version JSON', e, stackTrace);
      rethrow;
    }
  }

  /// 获取已安装的Quilt版本
  Future<List<String>> getInstalledQuiltVersions(String gameDirectory) async {
    final versionsDir = Directory(path.join(gameDirectory, 'versions'));
    if (!await versionsDir.exists()) {
      return [];
    }

    final installedVersions = <String>[];
    await for (final entity in versionsDir.list()) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        if (dirName.contains('-quilt-')) {
          installedVersions.add(dirName);
        }
      }
    }

    return installedVersions;
  }

  /// 检查Quilt是否已安装
  Future<bool> isQuiltInstalled({
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
  }) async {
    final installedVersions = await getInstalledQuiltVersions(gameDirectory);
    final targetId = '$mcVersion-quilt-$loaderVersion';
    return installedVersions.contains(targetId);
  }
}
