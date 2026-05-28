import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:path/path.dart' as path;
import '../../version/models.dart';
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';

class NativeLibraryManager {
  static NativeLibraryManager? _instance;

  factory NativeLibraryManager() {
    return _instance ??= NativeLibraryManager._internal();
  }

  NativeLibraryManager._internal();

  static NativeLibraryManager get instance =>
      _instance ??= NativeLibraryManager._internal();

  static void reset() {
    _instance = null;
  }

  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final Logger _logger = Logger('NativeLibraryManager');

  Future<void> extractNativeLibraries(
    VersionJson versionJson,
    String librariesDir,
    String nativesDir, {
    bool useNativeGlfw = false,
    bool useNativeOpenal = false,
  }) async {
    try {
      _logger.info('Extracting native libraries...');

      final nativesDirectory = Directory(nativesDir);
      if (!await nativesDirectory.exists()) {
        await nativesDirectory.create(recursive: true);
      }

      final platformKey = _getPlatformKey();
      if (platformKey == null) {
        _logger.warn('Unsupported platform for native extraction');
        return;
      }

      final extensions = _getNativeExtensions();

      for (final library in versionJson.libraries) {
        if (library.natives == null) continue;

        final classifier = library.natives![platformKey];
        if (classifier == null) continue;

        if (!_isAllowedByRules(library.rules)) continue;

        if (library.name.contains('org.lwjgl:lwjgl-openal') &&
            !useNativeOpenal) {
          _logger.info('Skipping OpenAL native: ${library.name}');
          continue;
        }

        if (library.name.contains('org.lwjgl:lwjgl-glfw') && !useNativeGlfw) {
          _logger.info(
            'Using system GLFW instead of native: ${library.name}',
          );
        }

        if (library.downloads?.classifiers == null) continue;

        final classifierEntry = library.downloads!.classifiers![classifier];
        if (classifierEntry == null) continue;

        final jarPath = path.join(librariesDir, classifierEntry.path);
        final jarFile = File(jarPath);

        if (!await jarFile.exists()) {
          _logger.warn('Native library JAR not found: $jarPath');
          continue;
        }

        await _extractJar(jarFile, nativesDir, extensions);
        _logger.info('Extracted native library: ${library.name}');
      }

      _logger.info('Native library extraction complete');
    } catch (e, stackTrace) {
      _logger.error('Failed to extract native libraries', e, stackTrace);
      rethrow;
    }
  }

  String? detectLwjglVersion(VersionJson versionJson) {
    for (final library in versionJson.libraries) {
      final name = library.name;
      if (name.startsWith('org.lwjgl:lwjgl:')) {
        final parts = name.split(':');
        if (parts.length == 3) {
          return parts[2];
        }
      }
    }
    return null;
  }

  bool shouldInjectLwjglUnsafeAgent(
    VersionJson versionJson,
    int javaMajorVersion,
  ) {
    if (javaMajorVersion < 25) return false;
    final lwjglVersion = detectLwjglVersion(versionJson);
    if (lwjglVersion == null) return false;
    return lwjglVersion.startsWith('3.4.');
  }

  String getUnsafeAgentPath(String gameDirectory) {
    return path.join(
      gameDirectory,
      'libraries',
      'org',
      'lwjgl',
      'lwjgl-unsafe-agent',
      '3.4.0',
      'lwjgl-unsafe-agent-3.4.0.jar',
    );
  }

  String? _getPlatformKey() {
    if (_platformAdapter.isWindows) return 'windows';
    if (_platformAdapter.isLinux) return 'linux';
    if (_platformAdapter.isMacOS) return 'osx';
    return null;
  }

  List<String> _getNativeExtensions() {
    if (_platformAdapter.isWindows) return ['.dll', '.exe'];
    if (_platformAdapter.isLinux) return ['.so'];
    if (_platformAdapter.isMacOS) return ['.dylib'];
    return [];
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

  Future<void> _extractJar(
    File jarFile,
    String nativesDir,
    List<String> extensions,
  ) async {
    final bytes = await jarFile.readAsBytes();
    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    for (final file in zipArchive.files) {
      if (!file.isFile) continue;

      final fileName = path.basename(file.name);
      final ext = path.extension(fileName).toLowerCase();

      if (extensions.contains(ext)) {
        final outputPath = path.join(nativesDir, fileName);
        await File(outputPath).writeAsBytes(file.content as List<int>);
      }
    }
  }
}
