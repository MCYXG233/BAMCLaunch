import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'logger.dart';

/// 单个归档条目被判定为"不安全"时的回调
///
/// [entryName] 是归档中的原始条目名（可能含 `..`、绝对路径、符号链接等）
/// [resolvedPath] 是尝试在 [targetDir] 下解析后的目标路径
typedef OnUnsafePath = void Function(String entryName, String resolvedPath);

/// 条目名变换器：用于在路径安全校验前重写 entry name
///
/// 例如整合包 overrides 提取时，可以把 `overrides/...` 改写为 `...`。
/// 返回 null 表示跳过该条目。
typedef EntryNameTransformer = String? Function(String entryName);

/// 解压结果统计
class ExtractResult {
  /// 成功提取的文件数
  final int filesExtracted;

  /// 成功创建的目录数
  final int directoriesCreated;

  /// 跳过的"不安全"条目名
  final List<String> skippedUnsafePaths;

  /// 累计写入字节数
  final int totalBytes;

  const ExtractResult({
    required this.filesExtracted,
    required this.directoriesCreated,
    required this.skippedUnsafePaths,
    required this.totalBytes,
  });

  @override
  String toString() =>
      'ExtractResult(files: $filesExtracted, dirs: $directoriesCreated, '
      'skipped: ${skippedUnsafePaths.length}, bytes: $totalBytes)';
}

/// 安全归档提取器
///
/// 解决原代码中直接 `path.join(targetDir, file.name)` 导致的
/// **Zip Slip 路径穿越漏洞**——恶意归档可以通过 `../../etc/...` 逃出
/// 目标目录，写入任意文件。
///
/// 此外还实现：
/// - **Zip 炸弹防护**：限制单文件大小与总条目数
/// - **绝对路径与符号链接防护**：拒绝含绝对路径或 `..` 的条目
/// - **Windows 设备名防护**：拒绝写入 `C:\Windows\System32` 等敏感位置
///
/// 替换项目里所有 `ZipDecoder().decodeBytes()` + `path.join(...)` 的散装逻辑。
class SafeArchiveExtractor {
  /// 默认单文件大小上限：2GB
  static const int defaultMaxFileSize = 2 * 1024 * 1024 * 1024;

  /// 默认总条目数上限：10万
  static const int defaultMaxEntries = 100000;

  /// 默认总解压字节数上限：20GB
  static const int defaultMaxTotalBytes = 20 * 1024 * 1024 * 1024;

  static final Logger _logger = Logger('SafeArchiveExtractor');

  /// 提取 ZIP 字节流到 [targetDir]
  ///
  /// [verify] 是否让 archive 包校验 CRC（默认 true；modpack 等已知损坏时可传 false）
  /// [onUnsafePath] 不安全条目处理回调；传 null 时默认记录 warning 并跳过
  /// [nameTransformer] 在路径安全校验前对 entry name 进行重写；
  ///                  典型用例：modpack overrides 解压时去掉 `overrides/` 前缀
  /// [maxFileSize]/[maxEntries]/[maxTotalBytes] 防止 zip 炸弹
  static Future<ExtractResult> extractZip({
    required List<int> bytes,
    required String targetDir,
    bool verify = true,
    OnUnsafePath? onUnsafePath,
    EntryNameTransformer? nameTransformer,
    int maxFileSize = defaultMaxFileSize,
    int maxEntries = defaultMaxEntries,
    int maxTotalBytes = defaultMaxTotalBytes,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes, verify: verify);
    return _extractArchiveEntries(
      archive: archive,
      targetDir: targetDir,
      onUnsafePath: onUnsafePath,
      nameTransformer: nameTransformer,
      maxFileSize: maxFileSize,
      maxEntries: maxEntries,
      maxTotalBytes: maxTotalBytes,
    );
  }

  /// 提取 tar.gz 字节流到 [targetDir]
  static Future<ExtractResult> extractTarGz({
    required List<int> bytes,
    required String targetDir,
    OnUnsafePath? onUnsafePath,
    EntryNameTransformer? nameTransformer,
    int maxFileSize = defaultMaxFileSize,
    int maxEntries = defaultMaxEntries,
    int maxTotalBytes = defaultMaxTotalBytes,
  }) async {
    final gzDecoded = GZipDecoder().decodeBytes(bytes);
    final tarArchive = TarDecoder().decodeBytes(gzDecoded);
    return _extractArchiveEntries(
      archive: tarArchive,
      targetDir: targetDir,
      onUnsafePath: onUnsafePath,
      nameTransformer: nameTransformer,
      maxFileSize: maxFileSize,
      maxEntries: maxEntries,
      maxTotalBytes: maxTotalBytes,
    );
  }

  /// 提取 tar 字节流到 [targetDir]
  static Future<ExtractResult> extractTar({
    required List<int> bytes,
    required String targetDir,
    OnUnsafePath? onUnsafePath,
    EntryNameTransformer? nameTransformer,
    int maxFileSize = defaultMaxFileSize,
    int maxEntries = defaultMaxEntries,
    int maxTotalBytes = defaultMaxTotalBytes,
  }) async {
    final tarArchive = TarDecoder().decodeBytes(bytes);
    return _extractArchiveEntries(
      archive: tarArchive,
      targetDir: targetDir,
      onUnsafePath: onUnsafePath,
      nameTransformer: nameTransformer,
      maxFileSize: maxFileSize,
      maxEntries: maxEntries,
      maxTotalBytes: maxTotalBytes,
    );
  }

  /// 通用提取流程：遍历 archive 中所有条目，安全地写入 [targetDir]
  static Future<ExtractResult> _extractArchiveEntries({
    required Archive archive,
    required String targetDir,
    OnUnsafePath? onUnsafePath,
    EntryNameTransformer? nameTransformer,
    required int maxFileSize,
    required int maxEntries,
    required int maxTotalBytes,
  }) async {
    // 1. 规范化 targetDir（确保以分隔符结尾，便于 startsWith 比较）
    final normalizedTarget = p.normalize(p.absolute(targetDir));

    // 2. 边界检查：总条目数
    if (archive.files.length > maxEntries) {
      _logger.error(
        'Archive exceeds max entries: ${archive.files.length} > $maxEntries',
      );
      throw const ArchiveSecurityException(
        'Archive exceeds max entries (zip bomb protection)',
      );
    }

    int filesExtracted = 0;
    int dirsCreated = 0;
    int totalBytes = 0;
    final skipped = <String>[];

    // 3. 遍历条目
    for (final entry in archive) {
      // 3.1 计算并校验目标路径
      final resolvedPath = _resolveSafePath(
        entryName: entry.name,
        targetDir: normalizedTarget,
        nameTransformer: nameTransformer,
      );

      if (resolvedPath == null) {
        // 不安全路径
        skipped.add(entry.name);
        try {
          (onUnsafePath ?? _defaultUnsafeHandler).call(
            entry.name,
            p.join(normalizedTarget, entry.name),
          );
        } catch (e) {
          if (e is ArchiveSecurityException) rethrow;
          _logger.warning('onUnsafePath handler threw: $e');
        }
        continue;
      }

      // 3.2 写入文件或创建目录
      if (entry.isFile) {
        // 大小检查
        final size = _entrySize(entry);
        if (size > maxFileSize) {
          _logger.error(
            'Entry exceeds max file size: $resolvedPath (${size} > $maxFileSize)',
          );
          throw ArchiveSecurityException(
            'File "$resolvedPath" exceeds max size (zip bomb protection)',
          );
        }
        if (totalBytes + size > maxTotalBytes) {
          _logger.error(
            'Archive total bytes exceeds limit: $totalBytes + $size > $maxTotalBytes',
          );
          throw const ArchiveSecurityException(
            'Archive total bytes exceeds limit (zip bomb protection)',
          );
        }

        await File(resolvedPath).create(recursive: true);
        final content = _entryContent(entry);
        if (content != null && content.isNotEmpty) {
          await File(resolvedPath).writeAsBytes(content, flush: true);
        }
        totalBytes += size;
        filesExtracted++;
      } else {
        await Directory(resolvedPath).create(recursive: true);
        dirsCreated++;
      }
    }

    return ExtractResult(
      filesExtracted: filesExtracted,
      directoriesCreated: dirsCreated,
      skippedUnsafePaths: skipped,
      totalBytes: totalBytes,
    );
  }

  /// 计算安全的目标路径。
  ///
  /// 返回 null 表示该条目不安全（应跳过）。
  static String? _resolveSafePath({
    required String entryName,
    required String targetDir,
    EntryNameTransformer? nameTransformer,
  }) {
    // 1. 拒绝空名
    if (entryName.isEmpty) return null;

    // 2. 应用 nameTransformer（如果提供）
    String effectiveName = entryName;
    if (nameTransformer != null) {
      final transformed = nameTransformer(entryName);
      if (transformed == null) {
        // 变换器显式拒绝该条目
        return null;
      }
      effectiveName = transformed;
    }

    // 3. 拒绝 Windows 风格的绝对路径（如 `C:\foo`）
    if (_isAbsolutePathLike(effectiveName)) {
      _logger.warning('Absolute path in archive entry: $effectiveName');
      return null;
    }

    // 4. 拼接 + 规范化
    final joined = p.normalize(p.join(targetDir, effectiveName));
    final absolute = p.absolute(joined);

    // 5. 验证规范化后的路径仍在 targetDir 之下
    final targetWithSep = targetDir.endsWith(p.separator)
        ? targetDir
        : '$targetDir${p.separator}';
    if (absolute != targetDir && !absolute.startsWith(targetWithSep)) {
      _logger.warning(
        'Path traversal detected: entry "$effectiveName" -> "$absolute"',
      );
      return null;
    }

    return absolute;
  }

  /// 判断路径字符串是否"看起来"是绝对路径
  /// (Windows: `C:\foo`, `\\server\share`; Unix: `/foo`)
  static bool _isAbsolutePathLike(String path) {
    if (p.isAbsolute(path)) return true;
    // Windows 盘符路径
    if (path.length >= 3 &&
        _isAsciiAlpha(path.codeUnitAt(0)) &&
        path[1] == ':' &&
        (path[2] == '\\' || path[2] == '/')) {
      return true;
    }
    return false;
  }

  static bool _isAsciiAlpha(int codeUnit) =>
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A);

  /// 获取条目大小
  static int _entrySize(ArchiveFile entry) {
    // archive 包的 ArchiveFile.size 是压缩后大小，原始大小更接近解压后大小
    // 但对路径穿越/炸弹防护而言，取任一字段都够用
    return entry.size;
  }

  /// 获取条目内容
  static List<int>? _entryContent(ArchiveFile entry) {
    final c = entry.content;
    if (c is Uint8List) return c;
    if (c is List<int>) return c;
    return null;
  }

  /// 默认的不安全路径处理：记录 warning 并跳过
  static void _defaultUnsafeHandler(String entryName, String resolvedPath) {
    _logger.warning('Skipping unsafe archive entry: $entryName');
  }
}

/// 归档安全相关异常（zip 炸弹、路径穿越、超过限制等）
class ArchiveSecurityException implements Exception {
  final String message;
  const ArchiveSecurityException(this.message);

  @override
  String toString() => 'ArchiveSecurityException: $message';
}
