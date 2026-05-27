import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import 'mod_info.dart';
import 'mod_parser.dart';

class ModScanner {
  static final Logger _logger = Logger('ModScanner');

  Future<List<ModInfo>> scanMods(String instancePath) async {
    final modsDir = Directory(path.join(instancePath, 'mods'));

    if (!await modsDir.exists()) {
      return [];
    }

    final List<ModInfo> mods = [];
    final entries = modsDir.listSync();

    for (final entry in entries) {
      if (entry is! File) continue;

      final fileName = path.basename(entry.path);
      final lowerName = fileName.toLowerCase();

      if (!lowerName.endsWith('.jar') && !lowerName.endsWith('.jar.disabled')) {
        continue;
      }

      final isEnabled = !lowerName.endsWith('.disabled');
      final modInfo = await ModParser.parseJarFile(entry.path, isEnabled);

      if (modInfo != null) {
        mods.add(modInfo);
      }
    }

    mods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _logger.info('Scanned ${mods.length} mods in $instancePath');
    return mods;
  }
}
