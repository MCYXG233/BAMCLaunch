import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

import '../interfaces/i_modpack_manager.dart';
import '../models/modpack_models.dart';
import '../../download/i_download_engine.dart';
import '../../download/download_engine.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../version/interfaces/i_version_manager.dart';
import '../../version/models/loader_models.dart';

class ModpackManager implements IModpackManager {
  final IDownloadEngine _downloadEngine;
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;
  final IVersionManager _versionManager;

  ModpackManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IVersionManager versionManager,
    IDownloadEngine? downloadEngine,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _versionManager = versionManager,
        _downloadEngine = downloadEngine ?? DownloadEngine();

  @override
  Future<List<Modpack>> getInstalledModpacks() async {
    final modpacksDir =
        Directory('${_platformAdapter.configDirectory}/modpacks');
    final installedModpacks = <Modpack>[];

    if (!await modpacksDir.exists()) {
      return installedModpacks;
    }

    final modpackFiles = await modpacksDir.list().toList();

    for (final file in modpackFiles) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final modpackData = jsonDecode(content);
          final modpack = Modpack.fromJson(modpackData);
          installedModpacks.add(modpack);
        } catch (e) {
          _logger.error('Failed to parse modpack file ${file.path}: $e');
        }
      }
    }

    return installedModpacks;
  }

  @override
  Future<ModpackManifest> parseModpack(String filePath) async {
    _logger.info('Parsing modpack: $filePath');

    final format = await detectModpackFormat(filePath);

    switch (format) {
      case ModpackFormat.curseforge:
        return _parseCurseforgeModpack(filePath);
      case ModpackFormat.modrinth:
        return _parseModrinthModpack(filePath);
      case ModpackFormat.mmc:
        return _parseMMCModpack(filePath);
      case ModpackFormat.pcl:
        return _parsePCLModpack(filePath);
      case ModpackFormat.hmcl:
        return _parseHMCLModpack(filePath);
      default:
        throw Exception('Unsupported modpack format');
    }
  }

  @override
  Future<ModpackImportResult> importModpack({
    required String filePath,
    Function(ModpackImportProgress)? onProgress,
  }) async {
    try {
      onProgress?.call(ModpackImportProgress(
        status: ModpackImportStatus.parsing,
        progress: 0.1,
        message: '解析整合包...',
      ));

      final manifest = await parseModpack(filePath);

      onProgress?.call(ModpackImportProgress(
        status: ModpackImportStatus.downloading,
        progress: 0.3,
        message: '下载文件...',
      ));

      final modpackId = _generateModpackId(manifest.name, manifest.version);
      final modpack = Modpack(
        id: modpackId,
        name: manifest.name,
        author: manifest.author,
        version: manifest.version,
        description: manifest.description,
        minecraftVersion: manifest.minecraftVersion,
        loaderType: manifest.loaderType,
        loaderVersion: manifest.loaderVersion,
        iconPath: manifest.iconPath,
        fileCount: manifest.files.length,
        size: 0,
        format: await detectModpackFormat(filePath),
        status: ModpackStatus.installed,
        createdAt: DateTime.now(),
        installedAt: DateTime.now(),
      );

      await _saveModpack(modpack);
      await _extractModpack(filePath, modpackId);

      onProgress?.call(ModpackImportProgress(
        status: ModpackImportStatus.installing,
        progress: 0.7,
        message: '安装整合包...',
      ));

      final installResult = await installModpack(
        modpack: modpack,
        onProgress: (progress) {
          onProgress?.call(ModpackImportProgress(
            status: ModpackImportStatus.installing,
            progress: 0.7 + progress * 0.2,
            message: '安装中...',
          ));
        },
      );

      if (installResult.success) {
        final updatedModpack = modpack.copyWith(
          gameVersionId: installResult.gameVersionId,
        );
        await _saveModpack(updatedModpack);

        onProgress?.call(ModpackImportProgress(
          status: ModpackImportStatus.completed,
          progress: 1.0,
          message: '整合包导入成功',
        ));

        return ModpackImportResult(
          success: true,
          modpack: updatedModpack,
        );
      } else {
        onProgress?.call(ModpackImportProgress(
          status: ModpackImportStatus.failed,
          progress: 1.0,
          message: '整合包安装失败',
        ));

        return ModpackImportResult(
          success: false,
          errorMessage: installResult.errorMessage,
        );
      }
    } catch (e) {
      _logger.error('Failed to import modpack: $e');
      onProgress?.call(ModpackImportProgress(
        status: ModpackImportStatus.failed,
        progress: 1.0,
        message: '整合包导入失败',
      ));
      return ModpackImportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<ModpackInstallResult> installModpack({
    required Modpack modpack,
    Function(double)? onProgress,
  }) async {
    try {
      _logger.info('Installing modpack: ${modpack.name} ${modpack.version}');

      final mcVersion = modpack.minecraftVersion;
      
      onProgress?.call(0.05);
      _logger.info('Checking Minecraft version $mcVersion');
      
      final installedVersions = await _versionManager.getInstalledVersions();
      final isVersionInstalled = installedVersions.any(
          (v) => v.id == mcVersion || v.id.startsWith('$mcVersion-'));

      if (!isVersionInstalled) {
        _logger.info('Installing Minecraft version $mcVersion');
        await _versionManager.installVersion(mcVersion, (progress) {
          onProgress?.call(0.05 + progress * 0.25);
        });
      } else {
        _logger.info('Minecraft version $mcVersion already installed');
        onProgress?.call(0.3);
      }

      String gameVersionId = mcVersion;

      if (modpack.loaderType != null && modpack.loaderVersion != null) {
        final loaderType = _parseLoaderType(modpack.loaderType!);
        _logger.info('Installing ${loaderType.name} ${modpack.loaderVersion}');
        
        final loaderInstallResult = await _versionManager.installLoader(
          loaderType: loaderType,
          mcVersion: mcVersion,
          loaderVersion: modpack.loaderVersion!,
          onProgress: (progress) {
            onProgress?.call(0.3 + progress * 0.4);
          },
        );

        if (!loaderInstallResult.success) {
          throw Exception('Failed to install loader: ${loaderInstallResult.errorMessage}');
        }

        gameVersionId = loaderInstallResult.versionId;
      }

      _logger.info('Installing modpack files');
      await _installModpackFiles(modpack.id, gameVersionId, (progress) {
        onProgress?.call(0.7 + progress * 0.3);
      });

      return ModpackInstallResult(
        success: true,
        gameVersionId: gameVersionId,
      );
    } catch (e) {
      _logger.error('Failed to install modpack: $e');
      return ModpackInstallResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> uninstallModpack(String modpackId) async {
    _logger.info('Uninstalling modpack: $modpackId');

    final modpacksDir =
        Directory('${_platformAdapter.configDirectory}/modpacks');
    final modpackFile = File('${modpacksDir.path}/$modpackId.json');

    if (await modpackFile.exists()) {
      await modpackFile.delete();
    }

    final extractedDir = Directory(
        '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');
    if (await extractedDir.exists()) {
      await extractedDir.delete(recursive: true);
    }
  }

  @override
  Future<ModpackExportResult> exportModpack({
    required String modpackId,
    required String exportPath,
    required ModpackFormat format,
    Function(double)? onProgress,
  }) async {
    try {
      _logger.info('Exporting modpack $modpackId to $exportPath');

      final modpack = await getModpackInfo(modpackId);
      final extractedDir = Directory(
          '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');

      if (!await extractedDir.exists()) {
        return ModpackExportResult(
          success: false,
          errorMessage: 'Modpack files not found',
        );
      }

      switch (format) {
        case ModpackFormat.curseforge:
          await _exportCurseforgeModpack(
              modpack, extractedDir, exportPath, onProgress);
          break;
        case ModpackFormat.modrinth:
          await _exportModrinthModpack(
              modpack, extractedDir, exportPath, onProgress);
          break;
        case ModpackFormat.mmc:
          await _exportMMCModpack(
              modpack, extractedDir, exportPath, onProgress);
          break;
        default:
          throw Exception('Export format not implemented');
      }

      return ModpackExportResult(
        success: true,
        exportPath: exportPath,
      );
    } catch (e) {
      _logger.error('Failed to export modpack: $e');
      return ModpackExportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<Modpack> createModpack(ModpackCreateOptions options) async {
    _logger.info('Creating custom modpack: ${options.name} ${options.version}');
    
    final modpackId = _generateModpackId(options.name, options.version);
    final extractedDir = Directory(
        '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');
    await extractedDir.create(recursive: true);

    final gameDir = Directory(_platformAdapter.gameDirectory);
    int totalSize = 0;
    int fileCount = 0;

    if (options.includeFiles.isNotEmpty) {
      for (final includePath in options.includeFiles) {
        final sourcePath = path.join(gameDir.path, includePath);
        final sourceFile = File(sourcePath);
        
        if (await sourceFile.exists()) {
          final targetPath = path.join(extractedDir.path, includePath);
          await File(targetPath).parent.create(recursive: true);
          await sourceFile.copy(targetPath);
          
          final fileSize = await sourceFile.length();
          totalSize += fileSize;
          fileCount++;
        }
      }
    } else {
      final filesToCopy = <String>[
        'mods',
        'resourcepacks',
        'shaderpacks',
        'config',
        'saves',
        'datapacks',
      ];

      for (final dirName in filesToCopy) {
        final sourceDir = Directory(path.join(gameDir.path, dirName));
        if (await sourceDir.exists()) {
          await _copyDirectory(sourceDir, Directory(path.join(extractedDir.path, dirName)), 
              options.excludeFiles);
        }
      }

      final files = await extractedDir
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      
      fileCount = files.length;
      for (final file in files) {
        totalSize += await file.length();
      }
    }

    final modpack = Modpack(
      id: modpackId,
      name: options.name,
      author: options.author,
      version: options.version,
      description: options.description,
      minecraftVersion: options.minecraftVersion,
      loaderType: options.loaderType,
      loaderVersion: options.loaderVersion,
      iconPath: options.iconPath,
      fileCount: fileCount,
      size: totalSize,
      format: options.format,
      status: ModpackStatus.installed,
      createdAt: DateTime.now(),
      installedAt: DateTime.now(),
    );

    await _saveModpack(modpack);
    _logger.info('Custom modpack created successfully: $modpackId');
    return modpack;
  }

  Future<void> _copyDirectory(Directory source, Directory destination, List<String> excludePatterns) async {
    await destination.create(recursive: true);
    
    final entities = await source.list().toList();
    for (final entity in entities) {
      final relativePath = path.relative(entity.path, from: source.path);
      
      bool shouldExclude = false;
      for (final pattern in excludePatterns) {
        if (relativePath.contains(pattern) || path.basename(entity.path) == pattern) {
          shouldExclude = true;
          break;
        }
      }
      
      if (shouldExclude) continue;
      
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(path.join(destination.path, relativePath)), excludePatterns);
      } else if (entity is File) {
        await File(path.join(destination.path, relativePath))
            .writeAsBytes(await entity.readAsBytes());
      }
    }
  }

  @override
  Future<Modpack> getModpackInfo(String modpackId) async {
    final modpackFile =
        File('${_platformAdapter.configDirectory}/modpacks/$modpackId.json');

    if (!await modpackFile.exists()) {
      throw Exception('Modpack $modpackId not found');
    }

    final content = await modpackFile.readAsString();
    final modpackData = jsonDecode(content);
    return Modpack.fromJson(modpackData);
  }

  @override
  Future<bool> checkModpackIntegrity(String modpackId) async {
    try {
      _logger.info('Checking modpack integrity: $modpackId');
      
      final modpack = await getModpackInfo(modpackId);
      final modpackFile =
          File('${_platformAdapter.configDirectory}/modpacks/$modpackId.json');
      final extractedDir = Directory(
          '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');

      if (!await modpackFile.exists()) {
        _logger.error('Modpack metadata file missing');
        return false;
      }

      if (!await extractedDir.exists()) {
        _logger.error('Extracted modpack directory missing');
        return false;
      }

      final files = await extractedDir
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        _logger.error('No files found in modpack');
        return false;
      }

      if (modpack.fileCount > 0 && files.length < modpack.fileCount) {
        _logger.error('File count mismatch: expected ${modpack.fileCount}, found ${files.length}');
        return false;
      }

      _logger.info('Modpack integrity check passed: ${files.length} files found');
      return true;
    } catch (e) {
      _logger.error('Failed to check modpack integrity: $e');
      return false;
    }
  }

  @override
  Future<void> repairModpack(String modpackId) async {
    _logger.info('Repairing modpack: $modpackId');
    
    try {
      final modpack = await getModpackInfo(modpackId);
      final extractedDir = Directory(
          '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');

      if (!await extractedDir.exists()) {
        _logger.info('Re-creating extracted directory');
        await extractedDir.create(recursive: true);
      }

      final files = await extractedDir
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        _logger.info('No files found, reinstalling modpack');
        await uninstallModpack(modpackId);
        return;
      }

      _logger.info('Verifying file integrity');
      bool hasCorruptedFiles = false;

      for (final file in files) {
        try {
          await file.length();
        } catch (e) {
          _logger.error('Corrupted file detected: ${file.path}');
          await file.delete();
          hasCorruptedFiles = true;
        }
      }

      if (hasCorruptedFiles) {
        _logger.info('Some files were corrupted and removed');
        await updateModpackStatus(modpackId, ModpackStatus.corrupted);
      } else {
        _logger.info('Modpack repair completed successfully');
        await updateModpackStatus(modpackId, ModpackStatus.installed);
      }
    } catch (e) {
      _logger.error('Failed to repair modpack: $e');
      await updateModpackStatus(modpackId, ModpackStatus.corrupted);
      rethrow;
    }
  }

  @override
  Future<List<Modpack>> searchModpacks(String query) async {
    final allModpacks = await getInstalledModpacks();
    return allModpacks.where((modpack) {
      return modpack.name.toLowerCase().contains(query.toLowerCase()) ||
          modpack.author.toLowerCase().contains(query.toLowerCase()) ||
          modpack.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<void> refreshModpackCache() async {
    _logger.info('Refreshing modpack cache');
  }

  @override
  Future<bool> isModpackInstalled(String modpackId) async {
    final modpackFile =
        File('${_platformAdapter.configDirectory}/modpacks/$modpackId.json');
    return await modpackFile.exists();
  }

  @override
  Future<void> updateModpackStatus(
      String modpackId, ModpackStatus status) async {
    final modpack = await getModpackInfo(modpackId);
    final updatedModpack = modpack.copyWith(status: status);
    await _saveModpack(updatedModpack);
  }

  @override
  Future<ModpackFormat> detectModpackFormat(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());

      for (final file in archive.files) {
        if (file.name == 'manifest.json' ||
            file.name.contains('manifest.json')) {
          return ModpackFormat.curseforge;
        } else if (file.name == 'modrinth.index.json') {
          return ModpackFormat.modrinth;
        } else if (file.name == 'instance.cfg') {
          return ModpackFormat.mmc;
        }
      }
    } catch (e) {
      _logger.error('Failed to detect modpack format: $e');
    }

    throw Exception('Unknown modpack format');
  }

  Future<ModpackManifest> _parseCurseforgeModpack(String filePath) async {
    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (file.name == 'manifest.json') {
        final manifestContent = utf8.decode(file.content);
        final manifestData = jsonDecode(manifestContent);

        return ModpackManifest(
          name: manifestData['name'],
          author: manifestData['author'],
          version: manifestData['version'],
          description: manifestData['description'] ?? '',
          minecraftVersion: manifestData['minecraft']['version'],
          loaderType:
              manifestData['minecraft']['modLoaders']?[0]?['id']?.split('-')[0],
          loaderVersion:
              manifestData['minecraft']['modLoaders']?[0]?['id']?.split('-')[1],
          files: (manifestData['files'] as List).map((file) {
            return ModpackFile(
              path: 'mods/${file['projectID']}-${file['fileID']}.jar',
              url:
                  'https://edge.forgecdn.net/files/${file['fileID'] ~/ 10000}/${file['fileID'] % 10000}/${file['filename']}',
              isRequired: true,
            );
          }).toList(),
          iconPath: manifestData['logoFile'],
        );
      }
    }

    throw Exception('CurseForge manifest.json not found');
  }

  Future<ModpackManifest> _parseModrinthModpack(String filePath) async {
    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (file.name == 'modrinth.index.json') {
        final manifestContent = utf8.decode(file.content);
        final manifestData = jsonDecode(manifestContent);

        return ModpackManifest(
          name: manifestData['name'],
          author: manifestData['author'] ?? '',
          version: manifestData['version'],
          description: manifestData['description'] ?? '',
          minecraftVersion: manifestData['dependencies']['minecraft'],
          loaderType: manifestData['dependencies'].keys.firstWhere(
                (key) => ['forge', 'fabric', 'quilt', 'neoforge'].contains(key),
                orElse: () => '',
              ),
          loaderVersion: manifestData['dependencies']
              [manifestData['dependencies'].keys.firstWhere(
                    (key) =>
                        ['forge', 'fabric', 'quilt', 'neoforge'].contains(key),
                    orElse: () => '',
                  )],
          files: (manifestData['files'] as List).map((file) {
            return ModpackFile(
              path: file['path'],
              url: file['downloads']?.isNotEmpty == true
                  ? file['downloads'][0]
                  : null,
              sha1: file['hashes']?['sha1'],
              size: file['fileSize'],
              isRequired: true,
            );
          }).toList(),
          iconPath: manifestData['icon'],
        );
      }
    }

    throw Exception('Modrinth index.json not found');
  }

  Future<ModpackManifest> _parseMMCModpack(String filePath) async {
    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (file.name == 'instance.cfg') {
        final content = utf8.decode(file.content);
        final lines = content.split('\n');

        String name = '';
        String author = '';
        String mcVersion = '';
        String loaderType = '';
        String loaderVersion = '';

        for (final line in lines) {
          if (line.startsWith('name=')) name = line.substring(5);
          if (line.startsWith('author=')) author = line.substring(7);
          if (line.startsWith('MCVersion=')) mcVersion = line.substring(10);
          if (line.startsWith('ModLoader=')) {
            final loader = line.substring(10);
            if (loader.contains('forge')) {
              loaderType = 'forge';
              loaderVersion = loader.replaceFirst('forge-', '');
            } else if (loader.contains('fabric')) {
              loaderType = 'fabric';
              loaderVersion = loader.replaceFirst('fabric-', '');
            }
          }
        }

        return ModpackManifest(
          name: name,
          author: author,
          version: '1.0',
          description: '',
          minecraftVersion: mcVersion,
          loaderType: loaderType.isNotEmpty ? loaderType : null,
          loaderVersion: loaderVersion.isNotEmpty ? loaderVersion : null,
          files: [],
        );
      }
    }

    throw Exception('MMC instance.cfg not found');
  }

  Future<ModpackManifest> _parsePCLModpack(String filePath) async {
    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (file.name == 'manifest.json') {
        final manifestContent = utf8.decode(file.content);
        final manifestData = jsonDecode(manifestContent);

        return ModpackManifest(
          name: manifestData['name'],
          author: manifestData['author'] ?? '',
          version: manifestData['version'] ?? '1.0',
          description: manifestData['description'] ?? '',
          minecraftVersion: manifestData['minecraftVersion'],
          loaderType: manifestData['loader']?['type'],
          loaderVersion: manifestData['loader']?['version'],
          files: (manifestData['files'] as List?)?.map((file) {
                return ModpackFile(
                  path: file['path'],
                  url: file['url'],
                  sha1: file['sha1'],
                  size: file['size'],
                  isRequired: file['required'] ?? true,
                );
              }).toList() ?? [],
          iconPath: manifestData['icon'],
        );
      }
    }

    throw Exception('PCL manifest.json not found');
  }

  Future<ModpackManifest> _parseHMCLModpack(String filePath) async {
    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (file.name == 'manifest.json') {
        final manifestContent = utf8.decode(file.content);
        final manifestData = jsonDecode(manifestContent);

        return ModpackManifest(
          name: manifestData['name'],
          author: manifestData['author'] ?? '',
          version: manifestData['version'] ?? '1.0',
          description: manifestData['description'] ?? '',
          minecraftVersion: manifestData['gameVersion'],
          loaderType: manifestData['loader']?['type'],
          loaderVersion: manifestData['loader']?['version'],
          files: (manifestData['files'] as List?)?.map((file) {
                return ModpackFile(
                  path: file['path'],
                  url: file['downloadUrl'],
                  sha1: file['checksum']?['sha1'],
                  size: file['size'],
                  isRequired: file['required'] ?? true,
                );
              }).toList() ?? [],
          iconPath: manifestData['icon'],
        );
      }
    }

    throw Exception('HMCL manifest.json not found');
  }

  Future<void> _saveModpack(Modpack modpack) async {
    final modpacksDir =
        Directory('${_platformAdapter.configDirectory}/modpacks');
    await modpacksDir.create(recursive: true);

    final modpackFile = File('${modpacksDir.path}/${modpack.id}.json');
    await modpackFile.writeAsString(jsonEncode(modpack.toJson()));
  }

  Future<void> _extractModpack(String filePath, String modpackId) async {
    final extractedDir = Directory(
        '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');
    await extractedDir.create(recursive: true);

    final archive =
        ZipDecoder().decodeBytes(await File(filePath).readAsBytes());

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final outputPath = path.join(extractedDir.path, file.name);
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(file.content);
    }
  }

  Future<void> _installModpackFiles(String modpackId, String gameVersionId,
      Function(double) onProgress) async {
    final extractedDir = Directory(
        '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');
    final gameDir = Directory(_platformAdapter.gameDirectory);

    final modpack = await getModpackInfo(modpackId);
    final manifest = await parseModpack(
        '${_platformAdapter.configDirectory}/modpacks_extracted/$modpackId');
    
    final allFiles = <ModpackFile>[];
    
    final localFiles = await extractedDir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    
    for (final localFile in localFiles) {
      final relativePath = path.relative(localFile.path, from: extractedDir.path);
      allFiles.add(ModpackFile(
        path: relativePath,
        isRequired: true,
      ));
    }
    
    allFiles.addAll(manifest.files);
    
    final uniqueFiles = <String, ModpackFile>{};
    for (final file in allFiles) {
      uniqueFiles[file.path] = file;
    }
    
    final filesToProcess = uniqueFiles.values.toList();
    final totalFiles = filesToProcess.length;

    for (int i = 0; i < totalFiles; i++) {
      final file = filesToProcess[i];
      final targetPath = path.join(gameDir.path, file.path);
      final targetFile = File(targetPath);
      
      await targetFile.parent.create(recursive: true);

      if (file.url != null) {
        await _downloadFile(file.url!, targetPath, file.sha1);
      } else {
        final sourcePath = path.join(extractedDir.path, file.path);
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) {
          await sourceFile.copy(targetPath);
        }
      }

      onProgress((i + 1) / totalFiles);
    }
  }

  Future<void> _downloadFile(String url, String savePath, String? checksum) async {
    await _downloadEngine.downloadFile(
      url,
      savePath,
      checksum: checksum,
      checksumType: checksum != null ? 'sha1' : null,
      maxRetries: 3,
      maxThreads: 4,
    );
  }

  Future<void> _exportCurseforgeModpack(Modpack modpack, Directory extractedDir,
      String exportPath, Function(double)? onProgress) async {
    final archive = Archive();

    final manifest = {
      'manifestType': 'minecraftModpack',
      'manifestVersion': 1,
      'name': modpack.name,
      'version': modpack.version,
      'author': modpack.author,
      'description': modpack.description,
      'minecraft': {
        'version': modpack.minecraftVersion,
        'modLoaders':
            modpack.loaderType != null && modpack.loaderVersion != null
                ? [
                    {
                      'id': '${modpack.loaderType}-${modpack.loaderVersion}',
                      'primary': true
                    }
                  ]
                : [],
      },
      'files': [],
      'overrides': 'overrides',
    };

    final manifestFile = ArchiveFile('manifest.json',
        jsonEncode(manifest).length, utf8.encode(jsonEncode(manifest)));
    archive.addFile(manifestFile);

    final files = await extractedDir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    for (final file in files) {
      final relativePath = path.relative(file.path, from: extractedDir.path);
      final content = await file.readAsBytes();
      archive.addFile(
          ArchiveFile('overrides/$relativePath', content.length, content));
    }

    final zipFile = File(exportPath);
    final zipData = ZipEncoder().encode(archive)!;
    await zipFile.writeAsBytes(zipData);
  }

  Future<void> _exportModrinthModpack(Modpack modpack, Directory extractedDir,
      String exportPath, Function(double)? onProgress) async {
    final archive = Archive();

    final index = {
      'formatVersion': 1,
      'game': 'minecraft',
      'versionId': modpack.version,
      'name': modpack.name,
      'summary': modpack.description,
      'author': modpack.author,
      'dependencies': {
        'minecraft': modpack.minecraftVersion,
      },
      'files': [],
    };

    if (modpack.loaderType != null && modpack.loaderVersion != null) {
      (index['dependencies'] as Map<String, dynamic>)[modpack.loaderType!] =
          modpack.loaderVersion!;
    }

    final indexFile = ArchiveFile('modrinth.index.json',
        jsonEncode(index).length, utf8.encode(jsonEncode(index)));
    archive.addFile(indexFile);

    final files = await extractedDir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    for (final file in files) {
      final relativePath = path.relative(file.path, from: extractedDir.path);
      final content = await file.readAsBytes();
      final fileSha1 = sha1.convert(content).toString();

      (index['files'] as List<dynamic>).add({
        'path': relativePath,
        'hashes': {'sha1': fileSha1},
        'fileSize': content.length,
        'downloads': [],
      });

      archive.addFile(ArchiveFile(relativePath, content.length, content));
    }

    final zipFile = File(exportPath);
    final zipData = ZipEncoder().encode(archive)!;
    await zipFile.writeAsBytes(zipData);
  }

  Future<void> _exportMMCModpack(Modpack modpack, Directory extractedDir,
      String exportPath, Function(double)? onProgress) async {
    final archive = Archive();

    final instanceCfg = StringBuffer();
    instanceCfg.writeln('name=${modpack.name}');
    instanceCfg.writeln('author=${modpack.author}');
    instanceCfg.writeln('MCVersion=${modpack.minecraftVersion}');
    
    if (modpack.loaderType != null) {
      String loaderName = modpack.loaderType!;
      if (modpack.loaderVersion != null) {
        loaderName = '$loaderName-${modpack.loaderVersion}';
      }
      instanceCfg.writeln('ModLoader=$loaderName');
    }
    
    instanceCfg.writeln('enableLevelStats=false');
    instanceCfg.writeln('iconKey=default');
    
    final instanceCfgFile = ArchiveFile(
        'instance.cfg', instanceCfg.length, utf8.encode(instanceCfg.toString()));
    archive.addFile(instanceCfgFile);

    final files = await extractedDir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    
    for (final file in files) {
      final relativePath = path.relative(file.path, from: extractedDir.path);
      final content = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, content.length, content));
    }

    final zipFile = File(exportPath);
    final zipData = ZipEncoder().encode(archive)!;
    await zipFile.writeAsBytes(zipData);
  }

  String _generateModpackId(String name, String version) {
    final input = '$name-$version-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  LoaderType _parseLoaderType(String loaderType) {
    switch (loaderType.toLowerCase()) {
      case 'forge':
        return LoaderType.forge;
      case 'fabric':
        return LoaderType.fabric;
      case 'quilt':
        return LoaderType.quilt;
      case 'neoforge':
        return LoaderType.neoForge;
      default:
        throw Exception('Unknown loader type: $loaderType');
    }
  }
}
