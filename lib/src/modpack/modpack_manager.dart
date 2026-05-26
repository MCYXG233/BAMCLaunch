import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../download/download_engine.dart';
import '../download/models.dart';
import '../event/event_bus.dart';
import '../event/event.dart';
import '../core/logger.dart';

class ModpackManager {
  static ModpackManager? _instance;
  
  factory ModpackManager() {
    _instance ??= ModpackManager._internal();
    return _instance!;
  }
  
  ModpackManager._internal();
  
  static ModpackManager get instance => _instance ??= ModpackManager._internal();
  
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
  
  final EventBus _eventBus = EventBus.instance;
  final Logger _logger = Logger();
  final DownloadEngine _downloadEngine = DownloadEngine();
  
  final Map<String, Modpack> _loadedModpacks = {};
  final DependencyResolver _dependencyResolver = DependencyResolver();
  
  Future<Modpack> importModpack(String sourcePath, {String? targetDirectory}) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw ModpackException('源文件不存在: $sourcePath');
    }
    
    _eventBus.publish(ModpackImportStartedEvent(sourcePath));
    
    try {
      final targetDir = targetDirectory ?? _getDefaultModpacksDirectory();
      final modpackDir = Directory(targetDir);
      
      if (!await modpackDir.exists()) {
        await modpackDir.create(recursive: true);
      }
      
      final manifest = await _extractManifest(sourcePath);
      final modpackId = manifest.id ?? 'modpack_${DateTime.now().millisecondsSinceEpoch}';
      final modpackPath = path.join(targetDir, modpackId);
      
      await _extractModpack(sourcePath, modpackPath);
      
      final modpack = await _parseManifest(path.join(modpackPath, 'modpack.json'), manifest);
      _loadedModpacks[modpackId] = modpack;
      
      await _saveModpackData(modpack);
      
      _eventBus.publish(ModpackImportCompletedEvent(modpack));
      
      return modpack;
    } catch (e, stackTrace) {
      _logger.error('导入整合包失败', e, stackTrace);
      _eventBus.publish(ModpackImportFailedEvent(sourcePath, e.toString()));
      throw ModpackException('导入整合包失败: $e');
    }
  }
  
  Future<void> exportModpack(String modpackId, String targetPath, {ExportFormat format = ExportFormat.zip}) async {
    final modpack = _loadedModpacks[modpackId];
    if (modpack == null) {
      throw ModpackException('整合包不存在: $modpackId');
    }
    
    _eventBus.publish(ModpackExportStartedEvent(modpackId, targetPath));
    
    try {
      final archive = Archive();
      
      final manifestJson = jsonEncode(modpack.toJson());
      archive.addFile(ArchiveFile(
        'modpack.json',
        manifestJson.length,
        utf8.encode(manifestJson),
      ));
      
      await _addFilesToArchive(archive, modpack.modsDirectory);
      await _addFilesToArchive(archive, modpack.configDirectory);
      await _addFilesToArchive(archive, modpack.scriptsDirectory);
      
      final outputFile = File(targetPath);
      final List<int> encodedArchive;
      
      if (format == ExportFormat.zip) {
        encodedArchive = ZipEncoder().encode(archive) ?? [];
      } else if (format == ExportFormat.tar) {
        encodedArchive = TarEncoder().encode(archive);
      } else {
        encodedArchive = ZipEncoder().encode(archive) ?? [];
      }
      
      await outputFile.writeAsBytes(encodedArchive);
      
      _eventBus.publish(ModpackExportCompletedEvent(modpackId, targetPath));
    } catch (e, stackTrace) {
      _logger.error('导出整合包失败', e, stackTrace);
      _eventBus.publish(ModpackExportFailedEvent(modpackId, e.toString()));
      throw ModpackException('导出整合包失败: $e');
    }
  }
  
  Future<void> installModpack(String modpackId, String gameVersionDirectory) async {
    final modpack = _loadedModpacks[modpackId];
    if (modpack == null) {
      throw ModpackException('整合包不存在: $modpackId');
    }
    
    _eventBus.publish(ModpackInstallStartedEvent(modpack));
    
    try {
      final modsDir = Directory(modpack.modsDirectory);
      if (await modsDir.exists()) {
        final targetModsDir = Directory(path.join(gameVersionDirectory, 'mods'));
        if (!await targetModsDir.exists()) {
          await targetModsDir.create(recursive: true);
        }
        
        await _copyDirectory(modsDir, targetModsDir);
      }
      
      final configDir = Directory(modpack.configDirectory);
      if (await configDir.exists()) {
        final targetConfigDir = Directory(path.join(gameVersionDirectory, 'config'));
        if (!await targetConfigDir.exists()) {
          await targetConfigDir.create(recursive: true);
        }
        
        await _copyDirectory(configDir, targetConfigDir);
      }
      
      await _downloadMods(modpack.mods);
      
      _eventBus.publish(ModpackInstallCompletedEvent(modpack));
    } catch (e, stackTrace) {
      _logger.error('安装整合包失败', e, stackTrace);
      _eventBus.publish(ModpackInstallFailedEvent(modpackId, e.toString()));
      throw ModpackException('安装整合包失败: $e');
    }
  }
  
  Future<void> updateModpack(String modpackId, {bool updateDependencies = true}) async {
    final modpack = _loadedModpacks[modpackId];
    if (modpack == null) {
      throw ModpackException('整合包不存在: $modpackId');
    }
    
    _eventBus.publish(ModpackUpdateStartedEvent(modpackId));
    
    try {
      for (final mod in modpack.mods) {
        if (mod.updateUrl != null) {
          final requests = <DownloadRequest>[];
          
          requests.add(DownloadRequest(
            url: mod.updateUrl!,
            savePath: path.join(modpack.modsDirectory, mod.fileName),
            hash: mod.hash,
            hashType: HashType.sha1,
          ));
          
          await _downloadEngine.downloadBatch(requests);
        }
      }
      
      if (updateDependencies) {
        await _resolveAndDownloadDependencies(modpack);
      }
      
      await _saveModpackData(modpack);
      
      _eventBus.publish(ModpackUpdateCompletedEvent(modpackId));
    } catch (e, stackTrace) {
      _logger.error('更新整合包失败', e, stackTrace);
      _eventBus.publish(ModpackUpdateFailedEvent(modpackId, e.toString()));
      throw ModpackException('更新整合包失败: $e');
    }
  }
  
  List<ModDependency> resolveDependencies(List<ModInfo> mods) {
    return _dependencyResolver.resolve(mods);
  }
  
  Future<List<ModInfo>> checkForUpdates(List<ModInfo> mods) async {
    final updates = <ModInfo>[];
    
    for (final mod in mods) {
      if (mod.updateUrl != null) {
        try {
          final tempFile = await _downloadEngine.download(
            mod.updateUrl!,
            path.join(_getTempDirectory(), 'temp_${mod.id}.tmp'),
          );
          
          final currentHash = await _calculateFileHash(tempFile);
          if (currentHash != mod.hash) {
            updates.add(mod.copyWith(
              version: 'newer_version',
              hash: currentHash,
            ));
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    return updates;
  }
  
  Future<ModpackManifest> _extractManifest(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final manifestFile = archive.findFile('modpack.json');
      if (manifestFile != null) {
        final content = utf8.decode(manifestFile.content as List<int>);
        return ModpackManifest.fromJson(jsonDecode(content));
      }
      
      final mmcPackFile = archive.findFile('mmc-pack.json');
      if (mmcPackFile != null) {
        final content = utf8.decode(mmcPackFile.content as List<int>);
        return _convertMMCManifest(jsonDecode(content));
      }
      
      final overridesFile = archive.findFile('manifest.json');
      if (overridesFile != null) {
        final content = utf8.decode(overridesFile.content as List<int>);
        return _convertCurseforgeManifest(jsonDecode(content));
      }
      
      return ModpackManifest(
        name: 'Unknown Modpack',
        version: '1.0.0',
        author: 'Unknown',
      );
    } catch (e) {
      throw ModpackException('无法解析整合包清单: $e');
    }
  }
  
  Future<void> _extractModpack(String sourcePath, String targetPath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final targetDir = Directory(targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    for (final file in archive) {
      final filePath = path.join(targetPath, file.name);
      
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }
  
  Future<void> _addFilesToArchive(Archive archive, String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: directoryPath);
        final content = await entity.readAsBytes();
        archive.addFile(ArchiveFile(
          relativePath.replaceAll('\\', '/'),
          content.length,
          content,
        ));
      }
    }
  }
  
  Future<void> _downloadMods(List<ModInfo> mods) async {
    for (final mod in mods) {
      if (mod.downloadUrl != null) {
        final requests = <DownloadRequest>[];
        
        requests.add(DownloadRequest(
          url: mod.downloadUrl!,
          savePath: path.join(_getDefaultModsDirectory(), mod.fileName),
          hash: mod.hash,
          hashType: HashType.sha1,
        ));
        
        await _downloadEngine.downloadBatch(requests);
      }
    }
  }
  
  Future<void> _resolveAndDownloadDependencies(Modpack modpack) async {
    final allDependencies = resolveDependencies(modpack.mods);
    final missingDependencies = allDependencies.where((dep) => !dep.isInstalled).toList();
    
    for (final dep in missingDependencies) {
      if (dep.downloadUrl != null) {
        final requests = <DownloadRequest>[];
        
        requests.add(DownloadRequest(
          url: dep.downloadUrl!,
          savePath: path.join(_getDefaultModsDirectory(), dep.fileName),
        ));
        
        await _downloadEngine.downloadBatch(requests);
      }
    }
  }
  
  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    
    await for (final entity in source.list()) {
      if (entity is File) {
        final targetPath = path.join(target.path, path.basename(entity.path));
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        final newTarget = Directory(path.join(target.path, path.basename(entity.path)));
        await _copyDirectory(entity, newTarget);
      }
    }
  }
  
  ModpackManifest _convertMMCManifest(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown';
    final version = json['version'] as String? ?? '1.0.0';
    
    return ModpackManifest(
      name: name,
      version: version,
      author: 'Unknown',
    );
  }
  
  ModpackManifest _convertCurseforgeManifest(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown';
    final version = json['version'] as String? ?? '1.0.0';
    final author = (json['author'] as String?) ?? 'Unknown';
    
    return ModpackManifest(
      name: name,
      version: version,
      author: author,
    );
  }
  
  Future<Modpack> _parseManifest(String manifestPath, ModpackManifest manifest) async {
    final mods = <ModInfo>[];
    final manifestFile = File(manifestPath);
    
    if (await manifestFile.exists()) {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      if (json.containsKey('mods')) {
        final modsJson = json['mods'] as List<dynamic>;
        for (final modJson in modsJson) {
          mods.add(ModInfo.fromJson(modJson as Map<String, dynamic>));
        }
      }
    }
    
    return Modpack(
      id: manifest.id ?? 'modpack_${DateTime.now().millisecondsSinceEpoch}',
      name: manifest.name,
      version: manifest.version,
      author: manifest.author,
      description: manifest.description,
      mods: mods,
      modsDirectory: path.dirname(manifestPath),
      configDirectory: path.join(path.dirname(manifestPath), 'config'),
      scriptsDirectory: path.join(path.dirname(manifestPath), 'scripts'),
    );
  }
  
  Future<void> _saveModpackData(Modpack modpack) async {
    final dataDir = Directory(_getModpacksDataDirectory());
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    
    final dataFile = File(path.join(dataDir.path, '${modpack.id}.json'));
    await dataFile.writeAsString(jsonEncode(modpack.toJson()));
  }
  
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  String _getDefaultModpacksDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['LOCALAPPDATA'] ?? '.'}\\BAMCLauncher\\modpacks';
    }
    return '${Platform.environment['HOME'] ?? '.'}/.bacmlauncher/modpacks';
  }
  
  String _getModpacksDataDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['LOCALAPPDATA'] ?? '.'}\\BAMCLauncher\\modpacks_data';
    }
    return '${Platform.environment['HOME'] ?? '.'}/.bacmlauncher/modpacks_data';
  }
  
  String _getDefaultModsDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['APPDATA'] ?? '.'}\\.minecraft\\mods';
    }
    return '${Platform.environment['HOME'] ?? '.'}/.minecraft/mods';
  }
  
  String _getTempDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['TEMP'] ?? '.'}\\BAMCLauncher';
    }
    return '/tmp/bacmlauncher';
  }
  
  void dispose() {
    _loadedModpacks.clear();
  }
}

class Modpack {
  final String id;
  final String name;
  final String version;
  final String author;
  final String? description;
  final List<ModInfo> mods;
  final String modsDirectory;
  final String configDirectory;
  final String scriptsDirectory;
  
  Modpack({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    this.description,
    required this.mods,
    required this.modsDirectory,
    required this.configDirectory,
    required this.scriptsDirectory,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'author': author,
    'description': description,
    'mods': mods.map((m) => m.toJson()).toList(),
    'modsDirectory': modsDirectory,
    'configDirectory': configDirectory,
    'scriptsDirectory': scriptsDirectory,
  };
  
  factory Modpack.fromJson(Map<String, dynamic> json) {
    return Modpack(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      mods: (json['mods'] as List<dynamic>)
          .map((m) => ModInfo.fromJson(m as Map<String, dynamic>))
          .toList(),
      modsDirectory: json['modsDirectory'] as String,
      configDirectory: json['configDirectory'] as String,
      scriptsDirectory: json['scriptsDirectory'] as String,
    );
  }
}

class ModpackManifest {
  final String? id;
  final String name;
  final String version;
  final String author;
  final String? description;
  
  ModpackManifest({
    this.id,
    required this.name,
    required this.version,
    required this.author,
    this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'author': author,
    'description': description,
  };
  
  factory ModpackManifest.fromJson(Map<String, dynamic> json) {
    return ModpackManifest(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown',
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? 'Unknown',
      description: json['description'] as String?,
    );
  }
}

class ModInfo {
  final String id;
  final String name;
  final String version;
  final String fileName;
  final String? hash;
  final String? hashType;
  final String? downloadUrl;
  final String? updateUrl;
  final List<String> requiredDependencies;
  final List<String> optionalDependencies;
  
  ModInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.fileName,
    this.hash,
    this.hashType,
    this.downloadUrl,
    this.updateUrl,
    this.requiredDependencies = const [],
    this.optionalDependencies = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'fileName': fileName,
    'hash': hash,
    'hashType': hashType,
    'downloadUrl': downloadUrl,
    'updateUrl': updateUrl,
    'requiredDependencies': requiredDependencies,
    'optionalDependencies': optionalDependencies,
  };
  
  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      id: json['id'] as String? ?? json['name'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      fileName: json['fileName'] as String,
      hash: json['hash'] as String?,
      hashType: json['hashType'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      updateUrl: json['updateUrl'] as String?,
      requiredDependencies: (json['requiredDependencies'] as List<dynamic>?)
          ?.cast<String>() ?? [],
      optionalDependencies: (json['optionalDependencies'] as List<dynamic>?)
          ?.cast<String>() ?? [],
    );
  }
  
  ModInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? fileName,
    String? hash,
    String? hashType,
    String? downloadUrl,
    String? updateUrl,
    List<String>? requiredDependencies,
    List<String>? optionalDependencies,
  }) {
    return ModInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      fileName: fileName ?? this.fileName,
      hash: hash ?? this.hash,
      hashType: hashType ?? this.hashType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      updateUrl: updateUrl ?? this.updateUrl,
      requiredDependencies: requiredDependencies ?? this.requiredDependencies,
      optionalDependencies: optionalDependencies ?? this.optionalDependencies,
    );
  }
}

class ModDependency {
  final String id;
  final String name;
  final String version;
  final String fileName;
  final String? downloadUrl;
  final bool isInstalled;
  final bool isRequired;
  
  ModDependency({
    required this.id,
    required this.name,
    required this.version,
    required this.fileName,
    this.downloadUrl,
    this.isInstalled = false,
    this.isRequired = true,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'fileName': fileName,
    'downloadUrl': downloadUrl,
    'isInstalled': isInstalled,
    'isRequired': isRequired,
  };
}

class DependencyResolver {
  List<ModDependency> resolve(List<ModInfo> mods) {
    final dependencies = <String, ModDependency>{};
    final processedIds = <String>{};
    
    for (final mod in mods) {
      _resolveModDependencies(mod, mods, dependencies, processedIds, true);
      _resolveModDependencies(mod, mods, dependencies, processedIds, false);
    }
    
    return dependencies.values.toList();
  }
  
  void _resolveModDependencies(
    ModInfo mod,
    List<ModInfo> allMods,
    Map<String, ModDependency> dependencies,
    Set<String> processedIds,
    bool required,
  ) {
    final depIds = required ? mod.requiredDependencies : mod.optionalDependencies;
    
    for (final depId in depIds) {
      if (processedIds.contains(depId)) continue;
      processedIds.add(depId);
      
      final depMod = allMods.where((m) => m.id == depId).firstOrNull;
      
      dependencies[depId] = ModDependency(
        id: depId,
        name: depMod?.name ?? depId,
        version: depMod?.version ?? 'unknown',
        fileName: depMod?.fileName ?? '$depId.jar',
        downloadUrl: depMod?.downloadUrl,
        isInstalled: depMod != null,
        isRequired: required,
      );
    }
  }
}

class ModpackException implements Exception {
  final String message;
  ModpackException(this.message);
  
  @override
  String toString() => 'ModpackException: $message';
}

enum ExportFormat {
  zip,
  tar,
  tarGz,
}

class path {
  static String join(String part1, String part2) {
    if (part1.endsWith('/') || part1.endsWith('\\')) {
      return '$part1$part2';
    }
    return '$part1/$part2';
  }
  
  static String dirname(String filePath) {
    final parts = filePath.split(RegExp(r'[/\\]'));
    if (parts.length <= 1) return '.';
    return parts.sublist(0, parts.length - 1).join('/');
  }
  
  static String basename(String filePath) {
    final parts = filePath.split(RegExp(r'[/\\]'));
    return parts.last;
  }
  
  static String relative(String filePath, {required String from}) {
    return filePath;
  }
}

class sha1 {
  static Digest convert(List<int> data) {
    return Digest(_simpleHash(data));
  }
}

class Digest {
  final List<int> bytes;
  Digest(this.bytes);
}

List<int> _simpleHash(List<int> data) {
  final result = <int>[];
  for (int i = 0; i < 16; i++) {
    int sum = 0;
    for (int j = 0; j < data.length; j++) {
      sum = (sum + data[j] * (i + j + 1)) % 256;
    }
    result.add(sum);
  }
  return result;
}

class ModpackImportStartedEvent extends Event {
  final String sourcePath;
  ModpackImportStartedEvent(this.sourcePath);
}

class ModpackImportCompletedEvent extends Event {
  final Modpack modpack;
  ModpackImportCompletedEvent(this.modpack);
}

class ModpackImportFailedEvent extends Event {
  final String sourcePath;
  final String error;
  ModpackImportFailedEvent(this.sourcePath, this.error);
}

class ModpackExportStartedEvent extends Event {
  final String modpackId;
  final String targetPath;
  ModpackExportStartedEvent(this.modpackId, this.targetPath);
}

class ModpackExportCompletedEvent extends Event {
  final String modpackId;
  final String targetPath;
  ModpackExportCompletedEvent(this.modpackId, this.targetPath);
}

class ModpackExportFailedEvent extends Event {
  final String modpackId;
  final String error;
  ModpackExportFailedEvent(this.modpackId, this.error);
}

class ModpackInstallStartedEvent extends Event {
  final Modpack modpack;
  ModpackInstallStartedEvent(this.modpack);
}

class ModpackInstallCompletedEvent extends Event {
  final Modpack modpack;
  ModpackInstallCompletedEvent(this.modpack);
}

class ModpackInstallFailedEvent extends Event {
  final String modpackId;
  final String error;
  ModpackInstallFailedEvent(this.modpackId, this.error);
}

class ModpackUpdateStartedEvent extends Event {
  final String modpackId;
  ModpackUpdateStartedEvent(this.modpackId);
}

class ModpackUpdateCompletedEvent extends Event {
  final String modpackId;
  ModpackUpdateCompletedEvent(this.modpackId);
}

class ModpackUpdateFailedEvent extends Event {
  final String modpackId;
  final String error;
  ModpackUpdateFailedEvent(this.modpackId, this.error);
}
