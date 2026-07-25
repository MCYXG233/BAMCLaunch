import 'dart:async';
import 'dart:io';
import '../../core/logger.dart';
import 'models.dart';

/// 游戏输出监听器
///
/// 从 GameLauncher 拆分出的单一职责组件，负责：
/// - 监听进程的 stdout / stderr 输出
/// - 将输出解析为 [GameLog] 并发送到日志流
/// - 将日志写入文件
///
/// 设计原则：
/// - 不持有进程级业务状态
/// - 通过回调通知主类每行输出（用于错误检测 / 就绪检测）
/// - 可独立单测
class GameOutputMonitor {
  final Logger _logger = Logger('GameOutputMonitor');

  /// 开始监听进程输出
  ///
  /// 设置 stdout / stderr 监听，将输出转发到 [onLog] 回调。
  /// 进程退出时自动关闭订阅和日志文件。
  ///
  /// [process] 要监听的进程
  /// [processId] 进程ID（用于日志标识）
  /// [gameDirectory] 游戏目录（用于创建日志文件）
  /// [logController] 日志流控制器
  /// [onLog] 每行日志的回调（用于错误检测 / 就绪检测）
  void startMonitoring({
    required Process process,
    required String processId,
    required String gameDirectory,
    required StreamController<GameLog> logController,
    required void Function(GameLog log) onLog,
  }) {
    // 尝试创建日志文件
    IOSink? logSink;
    try {
      final logDir = Directory('$gameDirectory/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      final logFile = File(
        '$gameDirectory/logs/launcher_$processId.log',
      );
      logSink = logFile.openWrite(mode: FileMode.append);
      logSink.writeln(
        '=== Launcher Log - Process $processId - ${DateTime.now().toIso8601String()} ===',
      );
    } catch (e) {
      _logger.warn('Failed to open log file: $e');
    }

    // 监听标准输出
    final stdoutSubscription = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(
            data: data,
            source: 'stdout',
            logSink: logSink,
            logController: logController,
            onLog: onLog,
          ),
          onError: (e) => _logger.error('Stdout stream error: $e'),
          onDone: () => _logger.debug('Stdout stream closed'),
        );

    // 监听错误输出
    final stderrSubscription = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(
            data: data,
            source: 'stderr',
            logSink: logSink,
            logController: logController,
            onLog: onLog,
          ),
          onError: (e) => _logger.error('Stderr stream error: $e'),
          onDone: () => _logger.debug('Stderr stream closed'),
        );

    // 进程退出时清理订阅和日志文件
    process.exitCode.then((_) {
      stdoutSubscription.cancel();
      stderrSubscription.cancel();
      logSink?.writeln(
        '=== Log ended - ${DateTime.now().toIso8601String()} ===',
      );
      logSink?.close();
    });
  }

  /// 处理进程输出
  ///
  /// 将输出按行解析为 [GameLog]，发送到流和日志文件，并触发 [onLog] 回调。
  void _handleOutput({
    required String data,
    required String source,
    required IOSink? logSink,
    required StreamController<GameLog> logController,
    required void Function(GameLog log) onLog,
  }) {
    final lines = data.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final log = GameLog(
        timestamp: DateTime.now(),
        level: parseLogLevel(line),
        message: line,
        source: source,
      );

      logController.add(log);

      // 写入日志文件
      if (logSink != null) {
        try {
          logSink.writeln(log.format());
        } catch (e) {
          _logger.warn('Failed to write to log file: $e');
        }
      }

      // 通知主类做错误检测 / 就绪检测
      onLog(log);
    }
  }

  /// 解析日志级别
  ///
  /// 根据输出内容判断日志级别。
  GameLogLevel parseLogLevel(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return GameLogLevel.error;
    } else if (lower.contains('warn') || lower.contains('warning')) {
      return GameLogLevel.warn;
    } else if (lower.contains('debug')) {
      return GameLogLevel.debug;
    }
    return GameLogLevel.info;
  }
}
