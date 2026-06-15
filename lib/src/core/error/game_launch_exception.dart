import 'app_exception.dart';

/// 游戏启动错误类型
enum GameLaunchErrorType {
  /// Java 未安装或版本不匹配
  javaNotFound,
  
  /// Java 版本不兼容
  javaVersionIncompatible,
  
  /// 游戏进程启动失败
  processFailed,
  
  /// JVM 崩溃
  jvmCrash,
  
  /// 内存不足
  outOfMemory,
  
  /// 游戏文件损坏
  corruptedFiles,
  
  /// 实例配置无效
  invalidInstance,
  
  /// 认证失败
  authenticationFailed,
  
  /// 窗口创建失败
  windowFailed,
  
  /// 未知错误
  unknown,
}

/// 游戏启动异常
/// 
/// 当游戏启动失败时抛出。
final class GameLaunchException extends AppException {
  /// Java 路径（如果有）
  final String? javaPath;

  /// 实例 ID（如果有）
  final String? instanceId;

  /// 进程退出码（如果有）
  final int? exitCode;

  /// 游戏版本（如果有）
  final String? gameVersion;

  /// 控制台输出（最后几行）
  final String? consoleOutput;

  /// 错误类型
  final GameLaunchErrorType errorType;

  const GameLaunchException({
    required String message,
    this.javaPath,
    this.instanceId,
    this.exitCode,
    this.gameVersion,
    this.consoleOutput,
    this.errorType = GameLaunchErrorType.unknown,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userFriendlyMessage {
    switch (errorType) {
      case GameLaunchErrorType.javaNotFound:
        return '未找到 Java，请安装或选择 Java 运行环境';
      case GameLaunchErrorType.javaVersionIncompatible:
        return 'Java 版本不兼容，请选择正确的 Java 版本';
      case GameLaunchErrorType.processFailed:
        return '游戏启动失败，请检查配置';
      case GameLaunchErrorType.jvmCrash:
        return '游戏崩溃（内存不足或 Mod 冲突）';
      case GameLaunchErrorType.outOfMemory:
        return '内存不足，请增加内存分配';
      case GameLaunchErrorType.corruptedFiles:
        return '游戏文件损坏，请重新下载';
      case GameLaunchErrorType.invalidInstance:
        return '实例配置无效';
      case GameLaunchErrorType.authenticationFailed:
        return '登录失败，请检查账户信息';
      case GameLaunchErrorType.windowFailed:
        return '窗口创建失败';
      case GameLaunchErrorType.unknown:
        return '游戏启动失败，请查看诊断信息';
    }
  }

  @override
  String get debugDescription {
    final buffer = StringBuffer('GameLaunchException: $userFriendlyMessage');
    buffer.write(', errorType=$errorType');
    if (javaPath != null) buffer.write(', javaPath=$javaPath');
    if (instanceId != null) buffer.write(', instanceId=$instanceId');
    if (exitCode != null) buffer.write(', exitCode=$exitCode');
    if (gameVersion != null) buffer.write(', gameVersion=$gameVersion');
    return buffer.toString();
  }

  @override
  FailureSeverity get severity => FailureSeverity.critical;

  /// 获取诊断信息
  /// 
  /// 用于显示给用户的完整诊断信息，包含可复制的内容。
  String get diagnosticInfo {
    final buffer = StringBuffer();
    buffer.writeln('=== 游戏启动诊断信息 ===');
    buffer.writeln('错误类型: $errorType');
    buffer.writeln('错误消息: $userFriendlyMessage');
    if (javaPath != null) buffer.writeln('Java 路径: $javaPath');
    if (instanceId != null) buffer.writeln('实例 ID: $instanceId');
    if (exitCode != null) buffer.writeln('退出码: $exitCode');
    if (gameVersion != null) buffer.writeln('游戏版本: $gameVersion');
    if (consoleOutput != null) {
      buffer.writeln('\n=== 控制台输出 ===');
      buffer.writeln(consoleOutput);
    }
    return buffer.toString();
  }

  /// 工厂方法：从崩溃日志创建
  factory GameLaunchException.fromCrashLog(
    String crashLog, {
    String? instanceId,
    String? javaPath,
    StackTrace? stackTrace,
  }) {
    final log = crashLog.toLowerCase();
    GameLaunchErrorType errorType;

    if (log.contains('outofmemoryerror') || log.contains('内存不足')) {
      errorType = GameLaunchErrorType.outOfMemory;
    } else if (log.contains('java.lang.runtimeexception') && 
                log.contains('couldn\'t create window')) {
      errorType = GameLaunchErrorType.windowFailed;
    } else if (log.contains('exitcode') && log.contains('-1')) {
      errorType = GameLaunchErrorType.authenticationFailed;
    } else {
      errorType = GameLaunchErrorType.jvmCrash;
    }

    // 提取最后 50 行作为控制台输出
    final lines = crashLog.split('\n');
    final lastLines = lines.length > 50 
        ? lines.sublist(lines.length - 50).join('\n')
        : crashLog;

    return GameLaunchException(
      message: errorType == GameLaunchErrorType.outOfMemory
          ? 'JVM 崩溃：内存不足'
          : 'JVM 崩溃',
      javaPath: javaPath,
      instanceId: instanceId,
      consoleOutput: lastLines,
      errorType: errorType,
      stackTrace: stackTrace,
    );
  }
}
