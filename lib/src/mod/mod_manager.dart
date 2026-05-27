import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../core/logger.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';
import 'mod_info.dart';
import 'mod_scanner.dart';

class ModManager {
  static ModManager? _instance;

  factory ModManager() {
    _instance ??= ModManager._internal();
    return _instance!;
  }

  ModManager._internal();

  static ModManager get instance => _instance ??= ModManager._internal();

  final Logger _logger = Logger('ModManager');
  final InstanceManager _instanceManager = InstanceManager.instance;
  final ModScanner _scanner = ModScanner();

  Future<String> _getInstancePath(String instanceId) async {
    if (!_instanceManager.isInitialized) {
      await _instanceManager.initialize();
    }

    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final directory = _instanceManager.directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found for instance: $instanceId'),
    );

    return path.join(directory.path, 'instances', instanceId);
  }

  Future<List<ModInfo>> getMods(String instanceId) async {
    try {
      final instancePath = await _getInstancePath(instanceId);
      return await _scanner.scanMods(instancePath);
    } catch (e, stackTrace) {
      _logger.error('Failed to get mods for instance: $instanceId', e, stackTrace);
      return [];
    }
  }

  Future<void> toggleMod(ModInfo mod) async {
    try {
      final file = File(mod.filePath);
      if (!await file.exists()) {
        throw FileSystemException('模组文件不存在', mod.filePath);
      }

      if (mod.isEnabled) {
        final newPath = '${mod.filePath}.disabled';
        await file.rename(newPath);
        _logger.info('Disabled mod: ${mod.name}');
      } else {
        final originalPath = mod.filePath.replaceAll('.disabled', '');
        await file.rename(originalPath);
        _logger.info('Enabled mod: ${mod.name}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to toggle mod: ${mod.name}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMod(ModInfo mod) async {
    try {
      final file = File(mod.filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Deleted mod: ${mod.name} (${mod.fileName})');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to delete mod: ${mod.name}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> openModsFolder(String instancePath) async {
    try {
      final modsDir = Directory(path.join(instancePath, 'mods'));
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }
      final uri = Uri.directory(modsDir.path);
      if (!await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Process.run('explorer', [modsDir.path]);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to open mods folder', e, stackTrace);
      rethrow;
    }
  }
}
