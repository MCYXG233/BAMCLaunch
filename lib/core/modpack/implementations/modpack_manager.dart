import '../interfaces/i_modpack_manager.dart';
import '../models/modpack_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../download/i_download_engine.dart';
import '../../content/interfaces/i_content_manager.dart';
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

class ModpackManager implements IModpackManager {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;
  final IDownloadEngine _downloadEngine;
  final IContentManager _contentManager;

  ModpackManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IDownloadEngine downloadEngine,
    required IContentManager contentManager,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _downloadEngine = downloadEngine,
        _contentManager = contentManager;

  @override
  Future<Modpack> importModpack(String filePath) async {
    try {
      _logger.info('导入整合包: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('整合包文件不存在');
      }

      // 读取整合包文件
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找modpack.json文件
      late Map<String, dynamic> modpackInfo;
      for (final file in archive) {
        if (file.name == 'modpack.json' || file.name == 'manifest.json') {
          final content = utf8.decode(file.content as List<int>);
          modpackInfo = jsonDecode(content);
          break;
        }
      }

      if (modpackInfo == null) {
        throw Exception('整合包文件中未找到modpack.json或manifest.json');
      }

      // 解析整合包信息
      final modpackId = modpackInfo['id'] ?? 'modpack_${DateTime.now().millisecondsSinceEpoch}';
      final modpackName = modpackInfo['name'] ?? 'Unknown Modpack';
      final modpackVersion = modpackInfo['version'] ?? '1.0.0';
      final author = modpackInfo['author'] ?? 'Unknown';
      final description = modpackInfo['description'] ?? '';
      final gameVersion = modpackInfo['gameVersion'] ?? modpackInfo['minecraft']?['version'] ?? '1.19.4';
      final modLoader = modpackInfo['modLoader'] ?? modpackInfo['minecraft']?['modLoaders']?[0]?['id']?.split('-')[0] ?? 'fabric';
      final modLoaderVersion = modpackInfo['modLoaderVersion'] ?? modpackInfo['minecraft']?['modLoaders']?[0]?['version'] ?? 'latest';

      // 创建整合包目录
      final modpackDir = '${_platformAdapter.gameDirectory}/modpacks/$modpackId';
      await _platformAdapter.createDirectory(modpackDir);

      // 提取整合包内容
      for (final file in archive) {
        final filePath = '$modpackDir/${file.name}';
        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      // 提取图标
      String iconPath = '';
      for (final file in archive) {
        if (file.name.endsWith('.png') && (file.name == 'icon.png' || file.name == 'logo.png')) {
          iconPath = '$modpackDir/${file.name}';
          break;
        }
      }

      // 解析模组列表
      final mods = <Mod>[];
      final files = modpackInfo['files'] ?? modpackInfo['mods'] ?? [];
      for (final file in files) {
        if (file is Map<String, dynamic>) {
          mods.add(Mod(
            id: file['id']?.toString() ?? '',
            name: file['name'] ?? '',
            version: file['version'] ?? '',
            author: file['author'] ?? '',
            description: file['description'] ?? '',
            source: file['source'] ?? 'curseforge',
            downloadUrl: file['downloadUrl'] ?? '',
            size: file['size'] ?? 0,
            filePath: '',
            installedAt: DateTime.now(),
          ));
        }
      }

      final modpack = Modpack(
        id: modpackId,
        name: modpackName,
        version: modpackVersion,
        author: author,
        description: description,
        gameVersion: gameVersion,
        modLoader: modLoader,
        modLoaderVersion: modLoaderVersion,
        iconPath: iconPath,
        mods: mods,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        path: modpackDir,
      );

      // 保存整合包信息
      await _saveModpackInfo(modpack);

      _logger.info('整合包导入成功: $modpackName');
      return modpack;
    } catch (e) {
      _logger.error('导入整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> exportModpack(String modpackId, String destination) async {
    try {
      _logger.info('导出整合包: $modpackId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        throw Exception('整合包不存在');
      }

      // 创建临时目录
      final tempDir = Directory.systemTemp.createTempSync('modpack_export');
      final modpackDir = '${tempDir.path}/${modpack.name}';
      await Directory(modpackDir).create(recursive: true);

      // 复制整合包文件
      final sourceDir = Directory(modpack.path);
      if (await sourceDir.exists()) {
        await for (final entity in sourceDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst('${sourceDir.path}/', '');
            final destPath = '$modpackDir/$relativePath';
            await File(destPath).parent.create(recursive: true);
            await entity.copy(destPath);
          }
        }
      }

      // 创建modpack.json
      final modpackInfo = {
        'id': modpack.id,
        'name': modpack.name,
        'version': modpack.version,
        'author': modpack.author,
        'description': modpack.description,
        'gameVersion': modpack.gameVersion,
        'modLoader': modpack.modLoader,
        'modLoaderVersion': modpack.modLoaderVersion,
        'files': modpack.mods.map((mod) => {
          'id': mod.id,
          'name': mod.name,
          'version': mod.version,
          'author': mod.author,
          'source': mod.source,
          'downloadUrl': mod.downloadUrl,
        }).toList(),
      };

      await File('$modpackDir/modpack.json').writeAsString(jsonEncode(modpackInfo, indent: 2));

      // 创建ZIP文件
      final outputFile = File(destination);
      final encoder = ZipEncoder();
      final archive = Archive();

      // 添加文件到ZIP
      await for (final entity in Directory(modpackDir).list(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.replaceFirst('${modpackDir}/', '');
          final content = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, content.length, content));
        }
      }

      // 写入ZIP文件
      final zipBytes = encoder.encode(archive)!;
      await outputFile.writeAsBytes(zipBytes);

      // 清理临时目录
      await tempDir.delete(recursive: true);

      _logger.info('整合包导出成功: $destination');
      return destination;
    } catch (e) {
      _logger.error('导出整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<ModpackInstallationResult> installModpack(String modpackId, String gameVersion) async {
    try {
      _logger.info('安装整合包: $modpackId, 游戏版本: $gameVersion');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        throw Exception('整合包不存在');
      }

      // 创建游戏实例目录
      final instanceDir = '${_platformAdapter.gameDirectory}/instances/${modpack.name}';
      await _platformAdapter.createDirectory(instanceDir);
      await _platformAdapter.createDirectory('$instanceDir/mods');
      await _platformAdapter.createDirectory('$instanceDir/config');

      final installedMods = <String>[];
      final failedMods = <String>[];

      // 安装模组
      for (final mod in modpack.mods) {
        try {
          final modPath = '$instanceDir/mods/${mod.name}-${mod.version}.jar';
          if (mod.downloadUrl.isNotEmpty) {
            // 使用简化的下载方法下载模组文件
            // mod.downloadUrl: 模组下载链接
            // modPath: 模组保存路径
            await _downloadEngine.downloadFile(
              mod.downloadUrl,
              modPath,
            );
          } else if (File(mod.filePath).existsSync()) {
            await File(mod.filePath).copy(modPath);
          }
          installedMods.add(mod.name);
        } catch (e) {
          _logger.error('安装模组失败: ${mod.name}, 错误: $e');
          failedMods.add(mod.name);
        }
      }

      // 创建版本配置
      final versionJson = {
        'id': '${modpack.name}-${modpack.version}',
        'inheritsFrom': gameVersion,
        'jar': gameVersion,
        'name': '${modpack.name} ${modpack.version}',
        'type': 'release',
      };

      await _platformAdapter.writeFile(
        '$instanceDir/${modpack.name}-${modpack.version}.json',
        jsonEncode(versionJson, indent: 2),
      );

      final success = failedMods.isEmpty;
      _logger.info('整合包安装${success ? '成功' : '失败'}: ${modpack.name}');

      return ModpackInstallationResult(
        success: success,
        modpackId: modpackId,
        gameVersion: gameVersion,
        installedMods: installedMods,
        failedMods: failedMods,
        error: success ? null : '部分模组安装失败',
      );
    } catch (e) {
      _logger.error('安装整合包失败: $e');
      return ModpackInstallationResult(
        success: false,
        modpackId: modpackId,
        gameVersion: gameVersion,
        installedMods: [],
        failedMods: [],
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> uninstallModpack(String modpackId) async {
    try {
      _logger.info('卸载整合包: $modpackId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        return false;
      }

      // 删除整合包目录
      final modpackDir = Directory(modpack.path);
      if (await modpackDir.exists()) {
        await modpackDir.delete(recursive: true);
      }

      // 删除整合包信息文件
      final infoFile = File('${_platformAdapter.gameDirectory}/modpacks/modpacks.json');
      if (await infoFile.exists()) {
        final content = await infoFile.readAsString();
        final modpacks = jsonDecode(content) as List;
        final updatedModpacks = modpacks.where((m) => m['id'] != modpackId).toList();
        await infoFile.writeAsString(jsonEncode(updatedModpacks, indent: 2));
      }

      _logger.info('整合包卸载成功: $modpackId');
      return true;
    } catch (e) {
      _logger.error('卸载整合包失败: $e');
      return false;
    }
  }

  @override
  Future<List<Modpack>> getModpacks() async {
    try {
      _logger.info('获取整合包列表');
      
      final modpacksDir = '${_platformAdapter.gameDirectory}/modpacks';
      if (!await Directory(modpacksDir).exists()) {
        return [];
      }

      final infoFile = File('$modpacksDir/modpacks.json');
      if (!await infoFile.exists()) {
        return [];
      }

      final content = await infoFile.readAsString();
      final modpacksData = jsonDecode(content) as List;
      final modpacks = <Modpack>[];

      for (final data in modpacksData) {
        final modpack = await _loadModpackFromData(data);
        if (modpack != null) {
          modpacks.add(modpack);
        }
      }

      return modpacks;
    } catch (e) {
      _logger.error('获取整合包列表失败: $e');
      return [];
    }
  }

  @override
  Future<Modpack?> getModpack(String modpackId) async {
    try {
      _logger.info('获取整合包详情: $modpackId');
      
      final modpacksDir = '${_platformAdapter.gameDirectory}/modpacks';
      final infoFile = File('$modpacksDir/modpacks.json');
      
      if (!await infoFile.exists()) {
        return null;
      }

      final content = await infoFile.readAsString();
      final modpacksData = jsonDecode(content) as List;
      
      for (final data in modpacksData) {
        if (data['id'] == modpackId) {
          return await _loadModpackFromData(data);
        }
      }

      return null;
    } catch (e) {
      _logger.error('获取整合包详情失败: $e');
      return null;
    }
  }

  @override
  Future<Modpack> updateModpack(String modpackId) async {
    try {
      _logger.info('更新整合包: $modpackId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        throw Exception('整合包不存在');
      }

      // 这里可以添加从API获取最新版本的逻辑
      // 暂时返回原整合包
      return modpack;
    } catch (e) {
      _logger.error('更新整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> backupModpack(String modpackId, String destination) async {
    try {
      _logger.info('备份整合包: $modpackId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        throw Exception('整合包不存在');
      }

      // 创建备份文件
      final backupFile = File(destination);
      final encoder = ZipEncoder();
      final archive = Archive();

      // 添加整合包文件
      final modpackDir = Directory(modpack.path);
      await for (final entity in modpackDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.replaceFirst('${modpackDir.path}/', '');
          final content = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, content.length, content));
        }
      }

      // 写入备份文件
      final zipBytes = encoder.encode(archive)!;
      await backupFile.writeAsBytes(zipBytes);

      _logger.info('整合包备份成功: $destination');
      return destination;
    } catch (e) {
      _logger.error('备份整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<Modpack> restoreModpack(String backupPath) async {
    try {
      _logger.info('恢复整合包: $backupPath');
      
      // 导入备份文件（与导入整合包逻辑相同）
      return await importModpack(backupPath);
    } catch (e) {
      _logger.error('恢复整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Mod>> getModpackMods(String modpackId) async {
    try {
      _logger.info('获取整合包模组列表: $modpackId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        return [];
      }

      return modpack.mods;
    } catch (e) {
      _logger.error('获取整合包模组列表失败: $e');
      return [];
    }
  }

  @override
  Future<bool> addModToModpack(String modpackId, String modId, String version) async {
    try {
      _logger.info('向整合包添加模组: $modpackId, 模组: $modId, 版本: $version');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        return false;
      }

      // 获取模组详情
      final modDetails = await _contentManager.getModDetails(modId);
      
      // 创建模组对象
      final newMod = Mod(
        id: modId,
        name: modDetails.name,
        version: version,
        author: modDetails.author,
        description: modDetails.summary,
        source: modDetails.source,
        downloadUrl: '', // 后续需要获取下载链接
        size: 0,
        filePath: '',
        installedAt: DateTime.now(),
      );

      // 添加到模组列表
      final updatedMods = [...modpack.mods, newMod];
      final updatedModpack = modpack.copyWith(
        mods: updatedMods,
        updatedAt: DateTime.now(),
      );

      // 保存更新后的整合包信息
      await _saveModpackInfo(updatedModpack);

      _logger.info('模组添加成功: ${modDetails.name}');
      return true;
    } catch (e) {
      _logger.error('添加模组失败: $e');
      return false;
    }
  }

  @override
  Future<bool> removeModFromModpack(String modpackId, String modId) async {
    try {
      _logger.info('从整合包移除模组: $modpackId, 模组: $modId');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        return false;
      }

      // 移除模组
      final updatedMods = modpack.mods.where((mod) => mod.id != modId).toList();
      final updatedModpack = modpack.copyWith(
        mods: updatedMods,
        updatedAt: DateTime.now(),
      );

      // 保存更新后的整合包信息
      await _saveModpackInfo(updatedModpack);

      _logger.info('模组移除成功: $modId');
      return true;
    } catch (e) {
      _logger.error('移除模组失败: $e');
      return false;
    }
  }

  @override
  Future<bool> updateModInModpack(String modpackId, String modId, String version) async {
    try {
      _logger.info('更新整合包中的模组: $modpackId, 模组: $modId, 版本: $version');
      
      final modpack = await getModpack(modpackId);
      if (modpack == null) {
        return false;
      }

      // 更新模组版本
      final updatedMods = modpack.mods.map((mod) {
        if (mod.id == modId) {
          return mod.copyWith(
            version: version,
            installedAt: DateTime.now(),
          );
        }
        return mod;
      }).toList();

      final updatedModpack = modpack.copyWith(
        mods: updatedMods,
        updatedAt: DateTime.now(),
      );

      // 保存更新后的整合包信息
      await _saveModpackInfo(updatedModpack);

      _logger.info('模组更新成功: $modId, 版本: $version');
      return true;
    } catch (e) {
      _logger.error('更新模组失败: $e');
      return false;
    }
  }

  // 辅助方法
  Future<void> _saveModpackInfo(Modpack modpack) async {
    final modpacksDir = '${_platformAdapter.gameDirectory}/modpacks';
    await _platformAdapter.createDirectory(modpacksDir);

    final infoFile = File('$modpacksDir/modpacks.json');
    List<dynamic> modpacks = [];

    if (await infoFile.exists()) {
      final content = await infoFile.readAsString();
      modpacks = jsonDecode(content) as List;
    }

    // 移除旧的整合包信息
    modpacks = modpacks.where((m) => m['id'] != modpack.id).toList();

    // 添加新的整合包信息
    modpacks.add({
      'id': modpack.id,
      'name': modpack.name,
      'version': modpack.version,
      'author': modpack.author,
      'description': modpack.description,
      'gameVersion': modpack.gameVersion,
      'modLoader': modpack.modLoader,
      'modLoaderVersion': modpack.modLoaderVersion,
      'iconPath': modpack.iconPath,
      'path': modpack.path,
      'createdAt': modpack.createdAt.toIso8601String(),
      'updatedAt': modpack.updatedAt.toIso8601String(),
    });

    await infoFile.writeAsString(jsonEncode(modpacks, indent: 2));
  }

  Future<Modpack?> _loadModpackFromData(dynamic data) async {
    try {
      final modpackDir = data['path'] as String;
      if (!await Directory(modpackDir).exists()) {
        return null;
      }

      // 加载模组列表
      final mods = <Mod>[];
      // 这里可以从modpack.json或其他文件加载模组列表

      return Modpack(
        id: data['id'] as String,
        name: data['name'] as String,
        version: data['version'] as String,
        author: data['author'] as String,
        description: data['description'] as String,
        gameVersion: data['gameVersion'] as String,
        modLoader: data['modLoader'] as String,
        modLoaderVersion: data['modLoaderVersion'] as String,
        iconPath: data['iconPath'] as String,
        mods: mods,
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: DateTime.parse(data['updatedAt'] as String),
        path: data['path'] as String,
      );
    } catch (e) {
      _logger.error('加载整合包信息失败: $e');
      return null;
    }
  }
}
