import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../../version/models.dart';
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';

/// 原生库提取模式
enum NativeExtractionMode {
  /// 普通模式
  normal,

  /// 快速模式（跳过已存在的文件）
  fast,

  /// 完全模式（始终重新提取）
  full,
}

/// 原生库提取结果
class NativeExtractionResult {
  /// 成功提取的库数量
  final int successCount;

  /// 跳过的库数量
  final int skippedCount;

  /// 失败的库数量
  final int failedCount;

  /// 提取的库名称列表
  final List<String> extractedLibraries;

  /// 失败的库名称列表
  final List<String> failedLibraries;

  /// 错误信息
  final Map<String, String> errors;

  NativeExtractionResult({
    required this.successCount,
    required this.skippedCount,
    required this.failedCount,
    required this.extractedLibraries,
    required this.failedLibraries,
    required this.errors,
  });

  bool get hasErrors => failedCount > 0;
  bool get isFullySuccessful => failedCount == 0 && skippedCount == 0;
}

/// 原生库提取器
///
/// 从JAR文件中提取原生库（.dll/.so/.dylib）到natives目录
class NativeExtractor {
  static NativeExtractor? _instance;

  factory NativeExtractor() {
    return _instance ??= NativeExtractor._internal();
  }

  NativeExtractor._internal();

  static NativeExtractor get instance =>
      _instance ??= NativeExtractor._internal();

  static void reset() {
    _instance = null;
  }

  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final Logger _logger = Logger('NativeExtractor');

  /// 提取所有原生库
  ///
  /// [versionJson] 版本JSON信息
  /// [librariesDir] 库文件目录
  /// [versionId] 版本ID
  /// [nativesDir] 原生库输出目录
  /// [mode] 提取模式
  /// [useNativeGlfw] 是否使用原生GLFW
  /// [useNativeOpenal] 是否使用原生OpenAL
  Future<NativeExtractionResult> extractAll({
    required VersionJson versionJson,
    required String librariesDir,
    required String versionId,
    required String nativesDir,
    NativeExtractionMode mode = NativeExtractionMode.normal,
    bool useNativeGlfw = false,
    bool useNativeOpenal = false,
  }) async {
    _logger.info('Starting native library extraction for version: $versionId');

    int successCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    final List<String> extractedLibraries = [];
    final List<String> failedLibraries = [];
    final Map<String, String> errors = {};

    final nativesDirectory = Directory(nativesDir);
    if (!await nativesDirectory.exists()) {
      await nativesDirectory.create(recursive: true);
    }

    final platformKey = _getPlatformKey();
    if (platformKey == null) {
      _logger.warn('Unsupported platform for native extraction');
      return NativeExtractionResult(
        successCount: 0,
        skippedCount: 0,
        failedCount: 0,
        extractedLibraries: [],
        failedLibraries: [],
        errors: {'platform': 'Unsupported platform'},
      );
    }

    final extensions = _getNativeExtensions();
    final arch = _getArchitecture();

    for (final library in versionJson.libraries) {
      if (library.natives == null) continue;

      final classifier = library.natives![platformKey];
      if (classifier == null) continue;

      if (!_isAllowedByRules(library.rules)) continue;

      // 检查是否跳过特定库
      if (library.name.contains('org.lwjgl:lwjgl-openal') && !useNativeOpenal) {
        _logger.info('Skipping OpenAL native: ${library.name}');
        skippedCount++;
        continue;
      }

      if (library.name.contains('org.lwjgl:lwjgl-glfw') && !useNativeGlfw) {
        _logger.info('Skipping GLFW native (using system GLFW): ${library.name}');
        skippedCount++;
        continue;
      }

      if (library.downloads?.classifiers == null) continue;

      final classifierEntry = library.downloads!.classifiers![classifier];
      if (classifierEntry == null) continue;

      final jarPath = path.join(librariesDir, classifierEntry.path);
      final jarFile = File(jarPath);

      if (!await jarFile.exists()) {
        _logger.warn('Native library JAR not found: $jarPath');
        failedCount++;
        failedLibraries.add(library.name);
        errors[library.name] = 'JAR file not found: $jarPath';
        continue;
      }

      try {
        final extracted = await _extractFromJar(
          jarFile: jarFile,
          nativesDir: nativesDir,
          extensions: extensions,
          arch: arch,
          mode: mode,
          libraryName: library.name,
        );

        if (extracted) {
          successCount++;
          extractedLibraries.add(library.name);
        } else {
          skippedCount++;
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to extract native library: ${library.name}', e, stackTrace);
        failedCount++;
        failedLibraries.add(library.name);
        errors[library.name] = e.toString();
      }
    }

    _logger.info(
      'Native extraction complete: $successCount extracted, $skippedCount skipped, $failedCount failed',
    );

    return NativeExtractionResult(
      successCount: successCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      extractedLibraries: extractedLibraries,
      failedLibraries: failedLibraries,
      errors: errors,
    );
  }

  /// 从单个JAR文件提取原生库
  Future<bool> _extractFromJar({
    required File jarFile,
    required String nativesDir,
    required List<String> extensions,
    required String arch,
    required NativeExtractionMode mode,
    required String libraryName,
  }) async {
    final bytes = await jarFile.readAsBytes();
    final zipArchive = ZipDecoder().decodeBytes(bytes);

    bool anyExtracted = false;

    for (final file in zipArchive.files) {
      if (!file.isFile) continue;

      final fileName = path.basename(file.name);
      final ext = path.extension(fileName).toLowerCase();

      // 检查扩展名
      if (!extensions.contains(ext)) continue;

      // 检查架构（对于包含架构信息的文件）
      if (!_matchesArchitecture(fileName, arch)) continue;

      final outputPath = path.join(nativesDir, fileName);
      final outputFile = File(outputPath);

      // 根据模式检查是否需要提取
      if (mode == NativeExtractionMode.fast) {
        if (await outputFile.exists()) {
          // 检查文件大小是否匹配
          final existingSize = await outputFile.length();
          final newSize = file.size;
          if (existingSize == newSize) {
            _logger.debug('Skipping existing file: $fileName');
            continue;
          }
        }
      } else if (mode == NativeExtractionMode.normal) {
        if (await outputFile.exists()) {
          _logger.debug('Skipping existing file: $fileName');
          continue;
        }
      }

      // 解压文件
      await outputFile.writeAsBytes(file.content as List<int>);
      _logger.debug('Extracted native: $fileName');
      anyExtracted = true;
    }

    return anyExtracted;
  }

  /// 检查文件名是否匹配架构
  bool _matchesArchitecture(String fileName, String arch) {
    // 如果文件名包含架构信息，检查是否匹配
    final lowerName = fileName.toLowerCase();

    // ARM架构检查
    if (arch == 'arm64') {
      if (lowerName.contains('arm64') || lowerName.contains('aarch64')) {
        return true;
      }
      // 如果不包含任何架构标识，假设通用
      if (!lowerName.contains('x64') && !lowerName.contains('amd64') &&
          !lowerName.contains('x86') && !lowerName.contains('i386')) {
        return true;
      }
      return false;
    }

    // x64架构检查
    if (arch == 'x64') {
      if (lowerName.contains('x64') || lowerName.contains('amd64') ||
          lowerName.contains('x86_64')) {
        return true;
      }
      // 如果不包含任何架构标识，假设通用
      if (!lowerName.contains('arm64') && !lowerName.contains('aarch64') &&
          !lowerName.contains('x86') && !lowerName.contains('i386')) {
        return true;
      }
      return false;
    }

    return true;
  }

  /// 获取平台键
  String? _getPlatformKey() {
    if (_platformAdapter.isWindows) return 'windows';
    if (_platformAdapter.isLinux) return 'linux';
    if (_platformAdapter.isMacOS) return 'osx';
    return null;
  }

  /// 获取原生库扩展名列表
  List<String> _getNativeExtensions() {
    if (_platformAdapter.isWindows) return ['.dll', '.exe'];
    if (_platformAdapter.isLinux) return ['.so'];
    if (_platformAdapter.isMacOS) return ['.dylib'];
    return [];
  }

  /// 获取架构
  String _getArchitecture() {
    // 检测系统架构
    final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ??
                 Platform.environment['HOSTTYPE'] ??
                 'x64';

    if (arch.toLowerCase().contains('arm64') || arch.toLowerCase().contains('aarch64')) {
      return 'arm64';
    }
    return 'x64';
  }

  /// 检查规则是否允许
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

  /// 匹配当前平台
  bool _matchesCurrentPlatform(OsRule? os) {
    if (os == null) return true;
    if (os.name != null) {
      if (os.name == 'windows' && !_platformAdapter.isWindows) return false;
      if (os.name == 'linux' && !_platformAdapter.isLinux) return false;
      if (os.name == 'osx' && !_platformAdapter.isMacOS) return false;
    }
    if (os.arch != null) {
      final currentArch = _getArchitecture();
      // 如果规则指定了特定架构但当前架构不匹配，则不匹配
      if (os.arch == 'arm64' && currentArch != 'arm64') return false;
      if (os.arch == 'x64' && currentArch != 'x64') return false;
    }
    return true;
  }

  /// 清理natives目录
  Future<void> cleanNatives(String nativesDir) async {
    final directory = Directory(nativesDir);
    if (!await directory.exists()) return;

    final extensions = _getNativeExtensions();
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (extensions.contains(ext)) {
          await entity.delete();
          _logger.debug('Deleted native: ${entity.path}');
        }
      }
    }
    _logger.info('Cleaned natives directory: $nativesDir');
  }

  /// 获取natives目录大小
  Future<int> getNativesSize(String nativesDir) async {
    final directory = Directory(nativesDir);
    if (!await directory.exists()) return 0;

    int totalSize = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// 验证natives目录完整性
  Future<List<String>> verifyNatives({
    required VersionJson versionJson,
    required String librariesDir,
    required String nativesDir,
  }) async {
    final missingLibraries = <String>[];

    final platformKey = _getPlatformKey();
    if (platformKey == null) return missingLibraries;

    final extensions = _getNativeExtensions();

    for (final library in versionJson.libraries) {
      if (library.natives == null) continue;

      final classifier = library.natives![platformKey];
      if (classifier == null) continue;

      if (!_isAllowedByRules(library.rules)) continue;

      if (library.downloads?.classifiers == null) continue;

      final classifierEntry = library.downloads!.classifiers![classifier];
      if (classifierEntry == null) continue;

      final jarPath = path.join(librariesDir, classifierEntry.path);
      final jarFile = File(jarPath);

      if (!await jarFile.exists()) {
        missingLibraries.add(library.name);
        continue;
      }

      // 检查JAR中的原生文件是否都存在于natives目录
      try {
        final missingFiles = await _verifyJarNatives(
          jarFile: jarFile,
          nativesDir: nativesDir,
          extensions: extensions,
        );
        if (missingFiles.isNotEmpty) {
          missingLibraries.add(library.name);
        }
      } catch (e) {
        missingLibraries.add(library.name);
      }
    }

    return missingLibraries;
  }

  /// 验证JAR中的原生文件
  Future<List<String>> _verifyJarNatives({
    required File jarFile,
    required String nativesDir,
    required List<String> extensions,
  }) async {
    final bytes = await jarFile.readAsBytes();
    final zipArchive = ZipDecoder().decodeBytes(bytes);

    final missingFiles = <String>[];

    for (final file in zipArchive.files) {
      if (!file.isFile) continue;

      final fileName = path.basename(file.name);
      final ext = path.extension(fileName).toLowerCase();

      if (!extensions.contains(ext)) continue;

      final outputPath = path.join(nativesDir, fileName);
      final outputFile = File(outputPath);

      if (!await outputFile.exists()) {
        missingFiles.add(fileName);
      }
    }

    return missingFiles;
  }
}
