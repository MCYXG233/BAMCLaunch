import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../event/event_bus.dart';
import '../event/event.dart';

/// OptiFine版本信息
class OptiFineVersion {
  /// 版本ID（如 "1.20.1")
  final String minecraftVersion;

  /// OptiFine版本（如 "HD_U_I9_PREVIEW")
  final String optiFineVersion;

  /// 完整版本字符串（如 "1.20.1_HD_U_I9_preview_5")
  final String fullVersion;

  /// 下载URL
  final String? downloadUrl;

  /// 构建号
  final int? build;

  const OptiFineVersion({
    required this.minecraftVersion,
    required this.optiFineVersion,
    required this.fullVersion,
    this.downloadUrl,
    this.build,
  });

  factory OptiFineVersion.fromJson(Map<String, dynamic> json) {
    return OptiFineVersion(
      minecraftVersion: json['minecraftVersion'] as String? ?? '',
      optiFineVersion: json['optiFineVersion'] as String? ?? '',
      fullVersion: json['fullVersion'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String?,
      build: json['build'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minecraftVersion': minecraftVersion,
      'optiFineVersion': optiFineVersion,
      'fullVersion': fullVersion,
      'downloadUrl': downloadUrl,
      'build': build,
    };
  }

  @override
  String toString() => fullVersion;
}

/// OptiFine安装进度事件
class OptiFineInstallProgressEvent extends Event {
  final String instanceId;
  final double progress;
  final String stage;
  final String? currentFile;

  OptiFineInstallProgressEvent({
    required this.instanceId,
    required this.progress,
    required this.stage,
    this.currentFile,
  });
}

/// OptiFine安装完成事件
class OptiFineInstallCompletedEvent extends Event {
  final String instanceId;
  final String version;

  OptiFineInstallCompletedEvent({
    required this.instanceId,
    required this.version,
  });
}

/// OptiFine安装失败事件
class OptiFineInstallFailedEvent extends Event {
  final String instanceId;
  final String error;

  OptiFineInstallFailedEvent({
    required this.instanceId,
    required this.error,
  });
}

/// OptiFine安装器
class OptiFineInstaller {
  static OptiFineInstaller? _instance;

  factory OptiFineInstaller() {
    _instance ??= OptiFineInstaller._internal();
    return _instance!;
  }

  OptiFineInstaller._internal();

  final Logger _logger = Logger('OptiFineInstaller');
  final NetworkClient _networkClient = NetworkClient();

  /// OptiFine官方下载页面
  static const String _optiFineBaseUrl = 'https://optifine.net';

  /// BMCLAPI镜像源（备选）
  static const String _bmclApiBaseUrl = 'https://bmclapi2.bangbang93.com';

  /// 获取OptiFine版本列表
  Future<List<OptiFineVersion>> getVersionList({
    void Function(String status, int current, int total)? onProgress,
  }) async {
    try {
      onProgress?.call('正在获取OptiFine版本列表...', 0, 100);

      // 首先尝试从BMCLAPI获取版本列表
      final versions = await _getVersionsFromBMCLAPI();
      
      if (versions.isNotEmpty) {
        onProgress?.call('获取成功', 100, 100);
        return versions;
      }

      // 如果BMCLAPI失败，从官方页面解析
      onProgress?.call('正在从官网获取...', 50, 100);
      return await _getVersionsFromOfficial();
    } catch (e) {
      _logger.error('Failed to get OptiFine version list', e);
      return [];
    }
  }

  /// 从BMCLAPI获取版本列表
  Future<List<OptiFineVersion>> _getVersionsFromBMCLAPI() async {
    try {
      final response = await _networkClient.get(
        '$_bmclApiBaseUrl/optifine/version',
        timeoutSeconds: 30,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => OptiFineVersion.fromJson(json)).toList();
      }
    } catch (e) {
      _logger.warn('BMCLAPI获取失败: $e');
    }
    return [];
  }

  /// 从官方页面解析版本列表
  Future<List<OptiFineVersion>> _getVersionsFromOfficial() async {
    try {
      final response = await http.post(
        Uri.parse('$_optiFineBaseUrl/adloadx.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: '.downloadLink=1',
      );

      if (response.statusCode == 200) {
        // 解析HTML响应中的版本信息
        return _parseOfficialVersions(response.body);
      }
    } catch (e) {
      _logger.warn('官方获取失败: $e');
    }
    return [];
  }

  /// 解析官方页面版本列表
  List<OptiFineVersion> _parseOfficialVersions(String html) {
    final versions = <OptiFineVersion>[];
    
    // 使用正则匹配版本信息
    final versionRegex = RegExp(
      r'version=([0-9.]+)_([A-Z_]+(?:_RC\d+)?(?:_preview_\d+)?)',
    );
    
    final matches = versionRegex.allMatches(html);
    final seen = <String>{};
    
    for (final match in matches) {
      final mcVersion = match.group(1) ?? '';
      final optiVersion = match.group(2) ?? '';
      final fullVersion = '${mcVersion}_$optiVersion';
      
      if (!seen.contains(fullVersion)) {
        seen.add(fullVersion);
        versions.add(OptiFineVersion(
          minecraftVersion: mcVersion,
          optiFineVersion: optiVersion,
          fullVersion: fullVersion,
        ));
      }
    }
    
    return versions;
  }

  /// 获取特定Minecraft版本的OptiFine列表
  Future<List<OptiFineVersion>> getVersionsForMinecraft(String minecraftVersion) async {
    final allVersions = await getVersionList();
    return allVersions.where((v) => v.minecraftVersion == minecraftVersion).toList();
  }

  /// 安装OptiFine到指定实例
  Future<bool> install({
    required String instanceId,
    required String instancePath,
    required String minecraftVersion,
    required String optiFineVersion,
    required String optiFineJarPath,
    void Function(String status, double progress)? onProgress,
  }) async {
    _logger.info('Installing OptiFine $optiFineVersion to $instancePath');

    try {
      // 触发进度事件
      EventBus().publish(OptiFineInstallProgressEvent(
        instanceId: instanceId,
        progress: 0,
        stage: '准备安装...',
      ));
      onProgress?.call('准备安装...', 0);

      // 1. 查找Forge版本目录
      final versionsDir = Directory(path.join(instancePath, 'versions'));
      if (!await versionsDir.exists()) {
        throw AppException.fromCode(
          ErrorCodes.fileNotFound,
          detail: 'versions目录不存在',
        );
      }

      // 找到对应的Forge版本
      final forgeVersionDir = await _findForgeVersion(versionsDir, minecraftVersion);
      if (forgeVersionDir == null) {
        throw AppException.fromCode(
          ErrorCodes.fileNotFound,
          detail: '未找到对应的Forge版本',
        );
      }

      onProgress?.call('正在合并JAR文件...', 30);
      EventBus().publish(OptiFineInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.3,
        stage: '正在合并JAR文件...',
      ));

      // 2. 合并OptiFine到Forge JAR
      final forgeJarPath = path.join(forgeVersionDir.path, '$minecraftVersion.jar');
      if (!await File(forgeJarPath).exists()) {
        // 尝试带Forge后缀的名称
        final files = await versionsDir.list().toList();
        for (final entity in files) {
          if (entity is Directory && entity.path.contains(minecraftVersion)) {
            final jarFiles = await Directory(entity.path)
                .list()
                .where((f) => f.path.endsWith('.jar'))
                .toList();
            if (jarFiles.isNotEmpty) {
              // 使用找到的第一个JAR
              await _mergeOptiFine(
                optiFineJarPath,
                jarFiles.first.path,
                forgeJarPath,
              );
              break;
            }
          }
        }
      } else {
        await _mergeOptiFine(optiFineJarPath, forgeJarPath, forgeJarPath);
      }

      onProgress?.call('正在更新版本JSON...', 70);
      EventBus().publish(OptiFineInstallProgressEvent(
        instanceId: instanceId,
        progress: 0.7,
        stage: '正在更新版本JSON...',
      ));

      // 3. 更新版本JSON添加OptiFine作为前置Mod
      await _updateVersionJson(
        path.join(forgeVersionDir.path, '$minecraftVersion.json'),
        optiFineVersion,
      );

      onProgress?.call('安装完成', 100);
      EventBus().publish(OptiFineInstallCompletedEvent(
        instanceId: instanceId,
        version: optiFineVersion,
      ));

      _logger.info('OptiFine安装成功: $optiFineVersion');
      return true;
    } catch (e, stackTrace) {
      _logger.error('OptiFine安装失败', e, stackTrace);
      EventBus().publish(OptiFineInstallFailedEvent(
        instanceId: instanceId,
        error: e.toString(),
      ));
      return false;
    }
  }

  /// 查找Forge版本目录
  Future<Directory?> _findForgeVersion(Directory versionsDir, String minecraftVersion) async {
    await for (final entity in versionsDir.list()) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        // Forge目录通常包含Minecraft版本和Forge版本号
        if (dirName.contains(minecraftVersion) && dirName.contains('forge')) {
          return entity;
        }
        // 也检查子目录
        if (await Directory(entity.path).list().any((f) => f.path.endsWith('.jar'))) {
          return entity;
        }
      }
    }
    return null;
  }

  /// 合并OptiFine到JAR文件
  Future<void> _mergeOptiFine(String optiFineJar, String forgeJar, String outputPath) async {
    // 读取Forge JAR
    final forgeFile = File(forgeJar);
    final forgeBytes = await forgeFile.readAsBytes();
    final forgeArchive = ZipDecoder().decodeBytes(forgeBytes);

    // 读取OptiFine JAR
    final optifineFile = File(optiFineJar);
    final optifineBytes = await optifineFile.readAsBytes();
    final optifineArchive = ZipDecoder().decodeBytes(optifineBytes);

    // 创建合并的JAR
    final mergedArchive = Archive();

    // 先添加Forge的所有文件
    for (final file in forgeArchive) {
      if (!file.isFile) continue;
      // 跳过META-INF
      if (file.name.startsWith('META-INF/')) continue;
      mergedArchive.addFile(file);
    }

    // 从OptiFine添加必要的类文件
    final optifineClasses = <String, ArchiveFile>{};
    for (final file in optifineArchive) {
      if (!file.isFile) continue;
      final name = file.name;
      // 只添加OptiFine相关的类
      if (name.startsWith('optifine/') || 
          name.startsWith('Config.class') ||
          name.startsWith('GuiOptiFine')) {
        optifineClasses[name] = file;
      }
    }

    // 添加OptiFine类（覆盖原有）
    for (final entry in optifineClasses.entries) {
      mergedArchive.addFile(entry.value);
    }

    // 编码并写入
    final encoder = ZipEncoder();
    final encoded = encoder.encode(mergedArchive);
    if (encoded != null) {
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encoded);
    }
  }

  /// 更新版本JSON
  Future<void> _updateVersionJson(String jsonPath, String optiFineVersion) async {
    final jsonFile = File(jsonPath);
    if (!await jsonFile.exists()) return;

    final content = await jsonFile.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    // 添加OptiFine到mods列表或创建mainClass覆盖
    final mainClass = json['mainClass'] as String?;
    if (mainClass != null && !mainClass.contains('OptiFine')) {
      json['mainClass'] = 'net.optifine.Launch';
      
      // 保存原始主类到OptiFine配置
      json['_originalMainClass'] = mainClass;
    }

    // 写入更新后的JSON
    final encoder = JsonEncoder.withIndent('  ');
    await jsonFile.writeAsString(encoder.convert(json));
  }

  /// 下载OptiFine安装器
  Future<String?> downloadInstaller({
    required String version,
    required String savePath,
    void Function(String status, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('正在获取下载链接...', 0);

      // 构造下载URL - 使用BMCLAPI镜像
      final mcVersion = version.split('_').first;
      final downloadUrl = '$_bmclApiBaseUrl/optifine/$mcVersion/$version';

      onProgress?.call('正在下载OptiFine...', 20);

      // 下载文件
      await _networkClient.downloadFile(
        downloadUrl,
        savePath,
        onProgress: (received, total) {
          if (total > 0) {
            final progress = 20.0 + (received / total * 70);
            onProgress?.call('下载中...', progress);
          }
        },
      );

      if (await File(savePath).exists()) {
        onProgress?.call('下载完成', 100);
        return savePath;
      }
    } catch (e) {
      _logger.error('下载OptiFine失败: $e');
    }
    return null;
  }

  /// 检查是否已安装OptiFine
  Future<bool> isInstalled(String instancePath) async {
    final versionsDir = Directory(path.join(instancePath, 'versions'));
    if (!await versionsDir.exists()) return false;

    await for (final entity in versionsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content);
          if (json is Map && json['mainClass'] == 'net.optifine.Launch') {
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  /// 获取已安装的OptiFine版本
  Future<String?> getInstalledVersion(String instancePath) async {
    final versionsDir = Directory(path.join(instancePath, 'versions'));
    if (!await versionsDir.exists()) return null;

    await for (final entity in versionsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content);
          if (json is Map && json['mainClass'] == 'net.optifine.Launch') {
            // 从文件名提取版本
            final jsonFile = File(entity.path);
            return path.basenameWithoutExtension(jsonFile.path);
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
