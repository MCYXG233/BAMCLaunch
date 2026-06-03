/// 崩溃类型枚举
///
/// 定义了 Minecraft 游戏可能出现的各种崩溃类型，
/// 用于分类和识别不同类型的错误。
enum CrashType {
  /// Java 版本不兼容
  ///
  /// 当游戏或模组要求的 Java 版本与当前安装的版本不匹配时发生。
  /// 例如：1.16+ 版本需要 Java 17，1.20.5+ 需要 Java 21。
  javaVersionIncompatible,

  /// 内存不足
  ///
  /// 游戏运行时 JVM 内存耗尽，可能是分配的内存不够或模组过多导致。
  outOfMemory,

  /// 模组冲突
  ///
  /// 存在功能重复或互相冲突的模组，需要移除冲突模组。
  modConflict,

  /// 缺少模组依赖
  ///
  /// 某些模组的前置依赖未安装或版本不正确。
  missingMod,

  /// 文件损坏或缺失
  ///
  /// 游戏核心文件或模组文件可能损坏或不完整。
  corruptedFiles,

  /// 账户验证失败
  ///
  /// 登录验证出现问题，可能需要重新登录 Microsoft 账户或外置登录服务。
  authError,

  /// 网络连接问题
  ///
  /// 游戏无法连接到服务器，可能是网络或服务器问题。
  networkError,

  /// 未知错误
  ///
  /// 无法识别的崩溃类型，需要进一步分析日志。
  unknown,
}

/// 崩溃分析结果
///
/// 包含崩溃类型、标题、描述和建议修复方案的详细信息。
/// 该类用于存储崩溃分析后的诊断结果，供用户界面展示。
class CrashAnalysis {
  /// 崩溃类型
  final CrashType type;

  /// 崩溃标题，简短描述问题
  final String title;

  /// 崩溃描述，详细说明问题原因
  final String description;

  /// 修复建议列表，提供用户可操作的解决方案
  final List<String> suggestions;

  /// 是否可以自动修复
  ///
  /// 如果为 true，表示启动器可以自动尝试修复此问题。
  /// 例如：内存不足可以通过自动调整 JVM 内存参数来修复。
  final bool canAutoFix;

  /// 构造函数
  ///
  /// [type] 崩溃类型（必填）
  /// [title] 崩溃标题（必填）
  /// [description] 崩溃描述（必填）
  /// [suggestions] 修复建议列表（必填）
  /// [canAutoFix] 是否可以自动修复，默认为 false
  const CrashAnalysis({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestions,
    this.canAutoFix = false,
  });
}

/// 崩溃分析器
///
/// 用于分析 Minecraft 游戏崩溃日志，识别崩溃原因并提供修复建议。
/// 通过检查日志中的关键错误信息，匹配已知的崩溃模式。
///
/// 使用示例：
/// ```dart
/// final analysis = CrashAnalyzer.analyze('1', crashLogs);
/// print(analysis.title); // 输出崩溃标题
/// print(analysis.suggestions); // 输出修复建议
/// ```
class CrashAnalyzer {
  /// 分析崩溃日志
  ///
  /// 根据退出码和日志内容，识别崩溃类型并返回分析结果。
  ///
  /// 参数：
  /// - [exitCode] 游戏退出码，可能为 null
  /// - [logs] 游戏日志行列表
  ///
  /// 返回：
  /// - [CrashAnalysis] 包含崩溃类型、描述和修复建议的分析结果
  ///
  /// 分析流程：
  /// 1. 将所有日志合并为小写字符串，便于不区分大小写匹配
  /// 2. 按优先级依次检查各种已知的崩溃模式
  /// 3. 如果匹配到已知模式，返回对应的分析结果
  /// 4. 如果未匹配到任何模式，返回未知错误类型
  static CrashAnalysis analyze(String? exitCode, List<String> logs) {
    // 将所有日志合并为一行，并转换为小写，便于关键词匹配
    final allText = logs.join('\n').toLowerCase();

    // 检测 Java 版本不兼容问题
    // 这类错误通常发生在使用错误版本的 Java 运行游戏时
    if (_containsAny(allText, [
      'unsupportedclassversionerror',
      'class file version',
      'classnotfoundexception',
    ])) {
      return CrashAnalysis(
        type: CrashType.javaVersionIncompatible,
        title: 'Java 版本不兼容',
        description: '当前 Java 版本与游戏/模组要求的版本不匹配。请安装正确版本的 Java。',
        suggestions: [
          '检查游戏版本所需的 Java 版本（1.16+ 通常需要 Java 17，1.20.5+ 需要 Java 21）',
          '在设置中切换到正确版本的 Java',
          '从 Eclipse Adoptium 或 Oracle 官网下载对应版本的 Java',
        ],
      );
    }

    // 检测内存不足问题
    // 这类错误通常发生在 JVM 堆内存耗尽时
    // canAutoFix 设为 true，启动器可以自动调整内存参数
    if (_containsAny(allText, [
      'outofmemoryerror',
      'java heap space',
      'gc overhead limit exceeded',
      'unable to create new native thread',
      'java.lang.OutOfMemoryError',
    ])) {
      return CrashAnalysis(
        type: CrashType.outOfMemory,
        title: '内存不足',
        description: '游戏运行时内存耗尽，可能是分配的内存不够或模组过多。',
        suggestions: [
          '增大 JVM 最大内存设置（建议至少 4096 MB）',
          '减少同时运行的模组数量',
          '关闭其他占用内存的程序',
          '在 JVM 参数中添加 -XX:+UseG1GC 优化垃圾回收',
        ],
        canAutoFix: true,
      );
    }

    // 检测缺少模组依赖问题
    // 这类错误通常发生在模组的前置依赖未安装或版本不正确时
    if (_containsAny(allText, [
      'modresolutionexception',
      'missing or unsupported mandatory dependencies',
      'requires mod',
      'missing mods',
      'mod加载失败',
    ])) {
      return CrashAnalysis(
        type: CrashType.missingMod,
        title: '缺少模组依赖',
        description: '某些模组的前置依赖未安装或版本不正确。',
        suggestions: [
          '检查报错日志中提到的缺失模组名称',
          '下载并安装缺失的前置模组（如 Fabric API、Forge 等）',
          '确保所有模组版本与游戏版本一致',
          '从模组官网或 CurseForge/Modrinth 下载正确版本',
        ],
      );
    }

    // 检测模组冲突问题
    // 这类错误通常发生在存在功能重复或互相冲突的模组时
    if (_containsAny(allText, [
      'duplicatemodsfoundexception',
      'mod conflict',
      'duplicate mod',
      'conflicting mods',
    ])) {
      return CrashAnalysis(
        type: CrashType.modConflict,
        title: '模组冲突',
        description: '存在功能重复或互相冲突的模组，需要移除冲突模组。',
        suggestions: [
          '检查日志中提到的冲突模组，移除其中一个',
          '查看模组兼容性列表，确认哪些模组不兼容',
          '尝试逐个移除最近添加的模组以定位冲突',
          '更新所有模组到最新版本',
        ],
      );
    }

    // 检测文件损坏或缺失问题
    // 这类错误通常发生在游戏核心文件或模组文件损坏时
    if (_containsAny(allText, [
      'corrupted',
      'ioexception',
      'zipfile',
      'zip exception',
      'corrupt',
      'malformed',
      'file not found',
      'filenotfoundexception',
      'nosuchfile',
    ])) {
      return CrashAnalysis(
        type: CrashType.corruptedFiles,
        title: '文件损坏或缺失',
        description: '游戏核心文件或模组文件可能损坏或不完整。',
        suggestions: [
          '尝试重新安装游戏版本',
          '重新下载损坏的模组文件',
          '检查磁盘是否有坏道或存储空间不足',
          '如果使用了修改器或优化工具，尝试关闭后重新启动',
        ],
      );
    }

    // 检测账户验证失败问题
    // 这类错误通常发生在登录验证出现问题时
    if (_containsAny(allText, [
      'authentication',
      'auth',
      'invalid session',
      'unauthorized',
      '403',
      'login failed',
    ])) {
      return CrashAnalysis(
        type: CrashType.authError,
        title: '账户验证失败',
        description: '登录验证出现问题，可能需要重新登录。',
        suggestions: [
          '重新登录 Microsoft 账户',
          '检查网络连接是否正常',
          '如果是外置登录，检查外置登录服务器配置',
          '等待一段时间后重试（可能是服务器暂时不可用）',
        ],
      );
    }

    // 检测网络连接问题
    // 这类错误通常发生在游戏无法连接到服务器时
    if (_containsAny(allText, [
      'connection refused',
      'timed out',
      'unknown host',
      'connectexception',
      'sockettimeoutexception',
      'network',
    ])) {
      return CrashAnalysis(
        type: CrashType.networkError,
        title: '网络连接问题',
        description: '游戏无法连接到服务器，可能是网络或服务器问题。',
        suggestions: [
          '检查网络连接是否正常',
          '确认服务器地址和端口是否正确',
          '检查防火墙是否阻止了游戏的网络访问',
          '如果使用代理，请检查代理设置',
        ],
      );
    }

    // 如果未匹配到任何已知模式，返回未知错误
    // 在标题中包含退出码信息（如果有）
    String exitInfo = '';
    if (exitCode != null && exitCode != '0') {
      exitInfo = '（退出码: $exitCode）';
    }

    return CrashAnalysis(
      type: CrashType.unknown,
      title: '未知错误$exitInfo',
      description: '游戏因未知原因崩溃，请查看日志获取更多信息。',
      suggestions: [
        '查看完整的游戏日志以获取详细的错误信息',
        '尝试重新启动游戏',
        '如果是模组相关问题，尝试移除最近添加的模组',
        '在社区或 GitHub 上搜索类似的问题',
      ],
    );
  }

  /// 检查文本是否包含关键词列表中的任意一个
  ///
  /// 这是一个私有辅助方法，用于快速检查文本中是否包含多个关键词中的任意一个。
  ///
  /// 参数：
  /// - [text] 要检查的文本
  /// - [keywords] 关键词列表
  ///
  /// 返回：
  /// - 如果文本包含任意一个关键词，返回 true
  /// - 如果文本不包含任何关键词，返回 false
  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}