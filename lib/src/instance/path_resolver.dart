import 'dart:io';
import 'package:path/path.dart' as path;

/// Minecraft 游戏目录路径解析器
///
/// 负责生成候选路径列表（用于自动检测游戏目录），支持：
/// - 用户自定义路径（通过额外候选列表传入）
/// - 平台默认路径（Windows/macOS/Linux）
/// - 常用盘符上的 Minecraft 目录
///
/// 替代原先硬编码 `E:\TSSForsunshine\Minecraft` 的方案。
class MinecraftPathResolver {
  /// 自定义候选路径（由调用方从 ConfigManager 传入）
  final List<String> customCandidates;

  const MinecraftPathResolver({this.customCandidates = const []});

  /// 解析所有候选路径（含用户自定义 + 平台默认）
  ///
  /// 路径去重（基于规范化后的绝对路径），并过滤空值。
  List<String> resolveCandidates() {
    final result = <String>[];

    // 1. 用户自定义候选（最高优先级）
    for (final p in customCandidates) {
      if (p.isNotEmpty) result.add(p);
    }

    // 2. 平台默认路径
    result.addAll(_platformDefaultCandidates());

    // 3. 常用盘符候选（仅 Windows）
    if (Platform.isWindows) {
      result.addAll(_windowsDriveCandidates());
    }

    return _deduplicate(result);
  }

  /// 平台默认候选路径
  List<String> _platformDefaultCandidates() {
    if (Platform.isWindows) {
      // %APPDATA%/.minecraft
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return [path.join(appData, '.minecraft')];
      }
      return [];
    }

    if (Platform.isMacOS) {
      // ~/Library/Application Support/minecraft
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return [path.join(home, 'Library', 'Application Support', 'minecraft')];
      }
      return [];
    }

    if (Platform.isLinux) {
      // ~/.minecraft
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return [path.join(home, '.minecraft')];
      }
      return [];
    }

    return [];
  }

  /// Windows 上常见盘符的候选路径
  List<String> _windowsDriveCandidates() {
    final candidates = <String>[];
    // 仅检查 C: 和 D: 盘，避免枚举所有盘符造成 I/O 开销
    for (final drive in ['C', 'D']) {
      candidates.add('$drive:\\Minecraft');
    }
    return candidates;
  }

  /// 路径去重（基于规范化）
  List<String> _deduplicate(List<String> paths) {
    final seen = <String>{};
    final result = <String>[];
    for (final p in paths) {
      final normalized = path.normalize(p);
      if (seen.add(normalized)) {
        result.add(p);
      }
    }
    return result;
  }

  /// 从候选路径中找出第一个存在的目录
  ///
  /// [predicate] 可选过滤函数（用于选择"哪个目录"是有效的游戏目录），
  /// 例如要求目录内含 `mods` 或 `versions` 等子目录。
  Future<String?> findFirstExisting({
    Future<bool> Function(Directory dir)? predicate,
  }) async {
    for (final candidate in resolveCandidates()) {
      try {
        final dir = Directory(candidate);
        if (!await dir.exists()) continue;
        if (predicate != null && !await predicate(dir)) continue;
        return candidate;
      } catch (_) {
        // I/O 错误（如权限不足）跳过该候选
        continue;
      }
    }
    return null;
  }
}
