import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../../version/models.dart';
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import 'models.dart';

class InvalidFile {
  final String path;
  final String? expectedHash;
  final String type;
  final String? url;
  final InvalidFileType invalidType;

  const InvalidFile({
    required this.path,
    this.expectedHash,
    required this.type,
    this.url,
    this.invalidType = InvalidFileType.missing,
  });
}

enum InvalidFileType {
  missing,
  hashMismatch,
  sizeMismatch,
  corrupted,
}

class ValidationProgress {
  final int totalFiles;
  final int validatedFiles;
  final String? currentFile;
  final double progress;

  ValidationProgress({
    required this.totalFiles,
    required this.validatedFiles,
    this.currentFile,
    required this.progress,
  });
}

class GameFileValidator {
  static GameFileValidator? _instance;

  factory GameFileValidator() {
    return _instance ??= GameFileValidator._internal();
  }

  GameFileValidator._internal();

  static GameFileValidator get instance =>
      _instance ??= GameFileValidator._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('GameFileValidator');

  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  Future<List<InvalidFile>> validateAll(
    VersionJson versionJson,
    String gameDirectory,
    FileValidatePolicy policy, {
    void Function(ValidationProgress)? onProgress,
  }) async {
    if (policy == FileValidatePolicy.disable) return [];

    final librariesDir = path.join(gameDirectory, 'libraries');
    final assetsDir = path.join(gameDirectory, 'assets');

    final results = <InvalidFile>[];

    final libraryFiles = await validateLibraryFiles(
      versionJson,
      librariesDir,
      policy,
    );
    results.addAll(libraryFiles);

    final assetFiles = await validateAssetFiles(
      versionJson,
      assetsDir,
      policy,
    );
    results.addAll(assetFiles);

    final clientJar = await validateClientJar(versionJson, gameDirectory);
    results.addAll(clientJar);

    if (policy == FileValidatePolicy.full) {
      final natives = await validateNativeLibraries(
        versionJson,
        gameDirectory,
      );
      results.addAll(natives);
    }

    _logger.info(
      'Validation complete: ${results.length} invalid files found '
      '(libraries: ${libraryFiles.length}, '
      'assets: ${assetFiles.length}, '
      'client: ${clientJar.length})',
    );

    return results;
  }

  Future<List<InvalidFile>> validateQuick(VersionJson versionJson, String gameDirectory) async {
    return await validateAll(versionJson, gameDirectory, FileValidatePolicy.normal);
  }

  Future<List<InvalidFile>> validateFull(VersionJson versionJson, String gameDirectory) async {
    return await validateAll(versionJson, gameDirectory, FileValidatePolicy.full);
  }

  Future<bool> hasInvalidFiles(VersionJson versionJson, String gameDirectory) async {
    final invalid = await validateAll(versionJson, gameDirectory, FileValidatePolicy.normal);
    return invalid.isNotEmpty;
  }

  Future<int> countInvalidFiles(VersionJson versionJson, String gameDirectory, FileValidatePolicy policy) async {
    final invalid = await validateAll(versionJson, gameDirectory, policy);
    return invalid.length;
  }

  Future<List<InvalidFile>> validateLibraryFiles(
    VersionJson versionJson,
    String librariesDir,
    FileValidatePolicy policy,
  ) async {
    if (policy == FileValidatePolicy.disable) return [];

    final invalidFiles = <InvalidFile>[];

    for (final library in versionJson.libraries) {
      if (!_isAllowedByRules(library.rules)) continue;

      if (library.natives != null) continue;

      final artifact = library.downloads?.artifact;
      if (artifact == null) continue;

      final filePath = path.join(librariesDir, artifact.path);
      final file = File(filePath);

      if (!await file.exists()) {
        _logger.debug('Library file missing: $filePath');
        invalidFiles.add(InvalidFile(
          path: filePath,
          expectedHash: artifact.sha1,
          type: 'library',
          url: artifact.url,
        ));
        continue;
      }

      if (policy == FileValidatePolicy.full) {
        final isValid = await _verifySha1(file, artifact.sha1);
        if (!isValid) {
          _logger.debug('Library file hash mismatch: $filePath');
          invalidFiles.add(InvalidFile(
            path: filePath,
            expectedHash: artifact.sha1,
            type: 'library',
            url: artifact.url,
          ));
        }
      }
    }

    return invalidFiles;
  }

  Future<List<InvalidFile>> validateAssetFiles(
    VersionJson versionJson,
    String assetsDir,
    FileValidatePolicy policy,
  ) async {
    if (policy == FileValidatePolicy.disable) return [];

    final invalidFiles = <InvalidFile>[];
    final assetIndex = versionJson.assetIndex;
    final indexFilePath = path.join(
      assetsDir,
      'indexes',
      '${assetIndex.id}.json',
    );
    final indexFile = File(indexFilePath);

    if (!await indexFile.exists()) {
      _logger.debug('Asset index file missing: $indexFilePath');
      invalidFiles.add(InvalidFile(
        path: indexFilePath,
        expectedHash: assetIndex.sha1,
        type: 'asset',
        url: assetIndex.url,
      ));
      return invalidFiles;
    }

    final indexContent = await indexFile.readAsString();
    final indexJson = jsonDecode(indexContent) as Map<String, dynamic>;
    final assetIndexFile = AssetIndexFile.fromJson(indexJson);

    for (final entry in assetIndexFile.objects.entries) {
      final assetPath = entry.key;
      final asset = entry.value;
      final hash = asset.hash;

      final objectFilePath = path.join(
        assetsDir,
        'objects',
        hash.substring(0, 2),
        hash,
      );
      final objectFile = File(objectFilePath);

      if (!await objectFile.exists()) {
        _logger.debug('Asset file missing: $objectFilePath');
        invalidFiles.add(InvalidFile(
          path: objectFilePath,
          expectedHash: hash,
          type: 'asset',
          url: null,
        ));
        continue;
      }

      if (policy == FileValidatePolicy.full) {
        final isValid = await _verifySha1(objectFile, hash);
        if (!isValid) {
          _logger.debug('Asset file hash mismatch: $objectFilePath');
          invalidFiles.add(InvalidFile(
            path: objectFilePath,
            expectedHash: hash,
            type: 'asset',
            url: null,
          ));
        }
      }

      final legacyFilePath = path.join(
        assetsDir,
        'virtual',
        'legacy',
        assetPath,
      );
      final legacyFile = File(legacyFilePath);

      if (!await legacyFile.exists()) {
        _logger.debug('Legacy asset file missing: $legacyFilePath');
        invalidFiles.add(InvalidFile(
          path: legacyFilePath,
          expectedHash: hash,
          type: 'asset',
          url: null,
        ));
        continue;
      }

      if (policy == FileValidatePolicy.full) {
        final isValid = await _verifySha1(legacyFile, hash);
        if (!isValid) {
          _logger.debug('Legacy asset file hash mismatch: $legacyFilePath');
          invalidFiles.add(InvalidFile(
            path: legacyFilePath,
            expectedHash: hash,
            type: 'asset',
            url: null,
          ));
        }
      }
    }

    return invalidFiles;
  }

  Future<List<InvalidFile>> validateClientJar(
    VersionJson versionJson,
    String gameDirectory,
  ) async {
    final clientPath = path.join(
      gameDirectory,
      'versions',
      versionJson.id,
      '${versionJson.id}.jar',
    );
    final file = File(clientPath);

    if (!await file.exists()) {
      _logger.debug('Client jar missing: $clientPath');
      final clientDownload = versionJson.downloads?.client;
      return [
        InvalidFile(
          path: clientPath,
          expectedHash: clientDownload?.sha1,
          type: 'client',
          url: clientDownload?.url,
        ),
      ];
    }

    return [];
  }

  Future<void> prepareLegacyAssets(
    String rootDir,
    String assetsDir,
    String assetIndexId,
  ) async {
    final legacyDir = Directory(path.join(assetsDir, 'virtual', 'legacy'));
    if (!await legacyDir.exists()) {
      await legacyDir.create(recursive: true);
    }

    final indexFilePath = path.join(assetsDir, 'indexes', '$assetIndexId.json');
    final indexFile = File(indexFilePath);

    if (!await indexFile.exists()) {
      _logger.warn('Asset index file not found for legacy copy: $indexFilePath');
      return;
    }

    final indexContent = await indexFile.readAsString();
    final indexJson = jsonDecode(indexContent) as Map<String, dynamic>;
    final assetIndexFile = AssetIndexFile.fromJson(indexJson);

    for (final entry in assetIndexFile.objects.entries) {
      final assetPath = entry.key;
      final asset = entry.value;
      final hash = asset.hash;

      final sourcePath = path.join(
        assetsDir,
        'objects',
        hash.substring(0, 2),
        hash,
      );
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        _logger.debug('Source asset file missing for legacy copy: $sourcePath');
        continue;
      }

      final destPath = path.join(assetsDir, 'virtual', 'legacy', assetPath);
      final destFile = File(destPath);
      final destParent = destFile.parent;

      if (!await destParent.exists()) {
        await destParent.create(recursive: true);
      }

      if (!await destFile.exists()) {
        try {
          if (_platformAdapter.isWindows) {
            await sourceFile.copy(destPath);
          } else {
            await Link(destPath).create(sourcePath);
          }
        } catch (e) {
          _logger.debug('Failed to create legacy asset link, falling back to copy: $destPath');
          await sourceFile.copy(destPath);
        }
      }
    }

    _logger.info('Legacy assets prepared for index $assetIndexId');
  }

  bool _isAllowedByRules(List<Rule>? rules) {
    if (rules == null || rules.isEmpty) return true;

    bool allowed = false;
    for (final rule in rules) {
      if (_matchesCurrentPlatform(rule.os)) {
        allowed = rule.action == 'allow';
      }
    }
    return allowed;
  }

  bool _matchesCurrentPlatform(OsRule? os) {
    if (os == null) return true;
    if (os.name != null) {
      if (os.name == 'windows' && !_platformAdapter.isWindows) return false;
      if (os.name == 'linux' && !_platformAdapter.isLinux) return false;
      if (os.name == 'osx' && !_platformAdapter.isMacOS) return false;
    }
    return true;
  }

  Future<bool> _verifySha1(File file, String expectedHash) async {
    try {
      final bytes = await file.readAsBytes();
      final actualHash = sha1.convert(bytes).toString();
      return actualHash == expectedHash;
    } catch (e, stackTrace) {
      _logger.error('Failed to compute SHA1 for ${file.path}', e, stackTrace);
      return false;
    }
  }

  Future<List<InvalidFile>> validateNativeLibraries(
    VersionJson versionJson,
    String gameDirectory,
  ) async {
    final invalidFiles = <InvalidFile>[];
    final nativesDir = path.join(gameDirectory, 'versions', versionJson.id, 'natives');

    if (!await Directory(nativesDir).exists()) {
      _logger.debug('Native libraries directory not found: $nativesDir');
      return invalidFiles;
    }

    for (final library in versionJson.libraries) {
      if (!_isAllowedByRules(library.rules)) continue;
      if (library.natives == null || library.downloads?.classifiers == null) continue;

      String nativeClassifier;
      if (_platformAdapter.isWindows) {
        nativeClassifier = 'natives-windows';
      } else if (_platformAdapter.isLinux) {
        nativeClassifier = 'natives-linux';
      } else if (_platformAdapter.isMacOS) {
        nativeClassifier = 'natives-macos';
      } else {
        continue;
      }

      final nativeArtifact = library.downloads!.classifiers![nativeClassifier];
      if (nativeArtifact == null) continue;

      final nativeFilePath = path.join(nativesDir, path.basename(nativeArtifact.path));
      final file = File(nativeFilePath);

      if (!await file.exists()) {
        _logger.debug('Native library missing: $nativeFilePath');
        invalidFiles.add(InvalidFile(
          path: nativeFilePath,
          expectedHash: nativeArtifact.sha1,
          type: 'native',
          url: nativeArtifact.url,
          invalidType: InvalidFileType.missing,
        ));
        continue;
      }

      final isValid = await _verifySha1(file, nativeArtifact.sha1);
      if (!isValid) {
        _logger.debug('Native library hash mismatch: $nativeFilePath');
        invalidFiles.add(InvalidFile(
          path: nativeFilePath,
          expectedHash: nativeArtifact.sha1,
          type: 'native',
          url: nativeArtifact.url,
          invalidType: InvalidFileType.hashMismatch,
        ));
      }
    }

    return invalidFiles;
  }

  Future<bool> verifySingleFile(String filePath, String expectedHash) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    return await _verifySha1(file, expectedHash);
  }

  Future<bool> verifyFileSize(String filePath, int expectedSize) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size == expectedSize;
  }
}
