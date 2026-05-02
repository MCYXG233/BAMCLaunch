import 'dart:io';

/// Minecraft 崩溃原因枚举
///
/// 参考 PCL2 的 CrashReason，覆盖常见 Minecraft 崩溃场景
enum MinecraftCrashReason {
  // Java 相关
  javaVersionIncompatible,  // Java 版本不兼容
  javaOutOfMemory,          // 内存不足
  javaCorrupted,            // Java 损坏

  // 模组相关
  modConflict,              // 模组冲突
  modMissingDependency,     // 缺少依赖
  modIncompatible,          // 模组不兼容
  modCorrupted,             // 模组损坏

  // 游戏相关
  gameCorrupted,            // 游戏文件损坏
  shaderError,              // 光影错误
  resourcePackError,        // 资源包错误

  // 系统相关
  graphicsDriverError,      // 显卡驱动错误
  permissionDenied,         // 权限不足
  diskFull,                 // 磁盘空间不足

  // 未知
  unknown,
}

/// Minecraft 崩溃分析结果
class MinecraftCrashAnalysisResult {
  final MinecraftCrashReason reason;
  final String description;
  final List<String> possibleCauses;
  final List<String> suggestions;
  final String? relatedMod;

  const MinecraftCrashAnalysisResult({
    required this.reason,
    required this.description,
    required this.possibleCauses,
    required this.suggestions,
    this.relatedMod,
  });
}

/// Minecraft 崩溃分析器
///
/// 3 阶段分析：
/// 1. 高优先级精确匹配（内存不足、Java 版本、模组缺失依赖）
/// 2. 堆栈跟踪分析（提取模组信息）
/// 3. 低优先级模式匹配（驱动、权限、磁盘）
class MinecraftCrashAnalyzer {
  /// 分析崩溃日志
  static Future<MinecraftCrashAnalysisResult> analyze({
    required String logContent,
    String? crashReport,
  }) async {
    // 阶段 1：高优先级精确匹配
    final result1 = _analyzeHighPriority(logContent, crashReport);
    if (result1 != null) return result1;

    // 阶段 2：堆栈跟踪分析
    final result2 = _analyzeStackTrace(logContent);
    if (result2 != null) return result2;

    // 阶段 3：低优先级模式匹配
    final result3 = _analyzeLowPriority(logContent);
    if (result3 != null) return result3;

    // 未知崩溃
    return const MinecraftCrashAnalysisResult(
      reason: MinecraftCrashReason.unknown,
      description: '无法确定崩溃原因',
      possibleCauses: ['可能是未知的模组冲突或系统问题'],
      suggestions: ['尝试移除最近安装的模组', '检查游戏文件完整性'],
    );
  }

  static MinecraftCrashAnalysisResult? _analyzeHighPriority(
      String log, String? crashReport) {
    // 内存不足
    if (log.contains('java.lang.OutOfMemoryError')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.javaOutOfMemory,
        description: 'Java 内存不足',
        possibleCauses: ['分配的内存不足', '模组过多导致内存占用过高'],
        suggestions: [
          '增加最大内存分配（建议 4GB+）',
          '减少模组数量',
          '使用内存优化模组'
        ],
      );
    }

    // Java 版本不兼容
    if (log.contains('UnsupportedClassVersionError') ||
        log.contains('java.lang.UnsupportedOperationException')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.javaVersionIncompatible,
        description: 'Java 版本不兼容',
        possibleCauses: ['使用的 Java 版本与游戏版本不匹配'],
        suggestions: [
          'MC 1.17+ 需要 Java 17+',
          'MC 1.16 及以下需要 Java 8'
        ],
      );
    }

    // 模组缺失依赖
    if (log.contains('Missing or unsupported mandatory dependencies')) {
      final modMatch = RegExp(r'Mod ID: (\w+)').firstMatch(log);
      return MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.modMissingDependency,
        description: '模组缺少必需的依赖',
        possibleCauses: ['安装的模组缺少前置模组'],
        suggestions: ['检查模组的依赖要求', '安装缺失的前置模组'],
        relatedMod: modMatch?.group(1),
      );
    }

    // 模组冲突
    if (log.contains('DuplicateModsFoundException') ||
        log.contains('ModResolutionException')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.modConflict,
        description: '模组冲突',
        possibleCauses: ['安装了重复或不兼容的模组'],
        suggestions: ['移除重复的模组', '检查模组版本兼容性'],
      );
    }

    // Forge/Fabric 版本不匹配
    if (log.contains('ModResolutionException') &&
        log.contains('requires version')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.modIncompatible,
        description: '模组版本不兼容',
        possibleCauses: ['模组版本与游戏版本或加载器版本不匹配'],
        suggestions: ['更新模组到兼容版本', '检查模组支持的游戏版本'],
      );
    }

    return null;
  }

  static MinecraftCrashAnalysisResult? _analyzeStackTrace(String log) {
    // 从堆栈跟踪中提取模组信息
    final modPatterns = [
      RegExp(r'at com\.([\w]+)\.([\w]+)'),
      RegExp(r'Mixin apply for mod (\w+)'),
      RegExp(r'from mod (\w+)'),
    ];

    for (final pattern in modPatterns) {
      final matches = pattern.allMatches(log);
      if (matches.isNotEmpty) {
        final modId = matches.first.group(1);
        return MinecraftCrashAnalysisResult(
          reason: MinecraftCrashReason.modCorrupted,
          description: '模组导致崩溃',
          possibleCauses: ['模组 $modId 可能已损坏或版本不兼容'],
          suggestions: ['尝试更新或移除模组 $modId'],
          relatedMod: modId,
        );
      }
    }

    return null;
  }

  static MinecraftCrashAnalysisResult? _analyzeLowPriority(String log) {
    // 显卡驱动问题
    if (log.contains('GLFW error') || log.contains('OpenGL')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.graphicsDriverError,
        description: '显卡驱动错误',
        possibleCauses: ['显卡驱动过旧', '不支持所需的 OpenGL 版本'],
        suggestions: ['更新显卡驱动', '检查显卡是否支持 OpenGL 4.4+'],
      );
    }

    // 权限问题
    if (log.contains('AccessDeniedException') ||
        log.contains('Permission denied')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.permissionDenied,
        description: '权限不足',
        possibleCauses: ['没有文件写入权限', '杀毒软件阻止访问'],
        suggestions: [
          '以管理员身份运行',
          '检查杀毒软件设置',
          '将游戏目录加入白名单'
        ],
      );
    }

    // 磁盘空间不足
    if (log.contains('No space left on device') ||
        log.contains('Disk full')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.diskFull,
        description: '磁盘空间不足',
        possibleCauses: ['磁盘剩余空间不足'],
        suggestions: ['清理磁盘空间', '将游戏移动到其他磁盘'],
      );
    }

    // 资源包错误
    if (log.contains('ResourcePackLoadingFailure') ||
        log.contains('Invalid resource pack')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.resourcePackError,
        description: '资源包加载失败',
        possibleCauses: ['资源包损坏或不兼容'],
        suggestions: ['移除有问题的资源包', '重新下载资源包'],
      );
    }

    // 光影错误
    if (log.contains('ShaderError') ||
        log.contains('Shader compilation failed')) {
      return const MinecraftCrashAnalysisResult(
        reason: MinecraftCrashReason.shaderError,
        description: '光影加载失败',
        possibleCauses: ['光影文件损坏或不兼容', '显卡不支持该光影'],
        suggestions: ['移除有问题的光影', '更新显卡驱动'],
      );
    }

    return null;
  }

  /// 从崩溃报告文件中提取信息
  static Future<MinecraftCrashAnalysisResult?> analyzeCrashReportFile(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      return await analyze(logContent: content, crashReport: content);
    } catch (e) {
      return null;
    }
  }
}
