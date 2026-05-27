enum CrashType {
  javaVersionIncompatible,
  outOfMemory,
  modConflict,
  missingMod,
  corruptedFiles,
  authError,
  networkError,
  unknown,
}

class CrashAnalysis {
  final CrashType type;
  final String title;
  final String description;
  final List<String> suggestions;
  final bool canAutoFix;

  const CrashAnalysis({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestions,
    this.canAutoFix = false,
  });
}

class CrashAnalyzer {
  static CrashAnalysis analyze(String? exitCode, List<String> logs) {
    final allText = logs.join('\n').toLowerCase();

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

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}
