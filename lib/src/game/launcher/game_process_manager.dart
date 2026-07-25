import 'dart:async';
import 'dart:io';
import '../../core/logger.dart';

/// 游戏进程管理器
///
/// 从 GameLauncher 拆分出的单一职责组件，负责：
/// - 启动游戏进程（[Process.start]）
/// - 停止游戏进程（跨平台终止）
/// - 清理进程资源（关闭流控制器、移除映射）
///
/// 设计原则：
/// - 不持有业务状态（_runningProcesses / _launchingStates 由主类管理）
/// - 通过回调通知主类进程退出事件
/// - 可独立单测（mock Process）
class GameProcessManager {
  final Logger _logger = Logger('GameProcessManager');

  /// 启动游戏进程
  ///
  /// [command] 启动命令（第一个元素为可执行文件，其余为参数）
  /// [workingDirectory] 工作目录
  ///
  /// 返回启动成功的 [Process] 实例。
  ///
  /// 抛出 [ProcessStartFailedError] 当进程启动失败时。
  Future<Process> startProcess({
    required List<String> command,
    required String workingDirectory,
  }) async {
    if (command.isEmpty) {
      throw ArgumentError('Command cannot be empty');
    }
    try {
      final process = await Process.start(
        command.first,
        command.sublist(1),
        workingDirectory: workingDirectory,
        mode: ProcessStartMode.normal,
      );
      _logger.info('Process started with PID: ${process.pid}');
      return process;
    } catch (e, stackTrace) {
      _logger.error('Failed to start game process', e, stackTrace);
      throw ProcessStartFailedError(originalError: e, stackTrace: stackTrace);
    }
  }

  /// 停止指定的游戏进程
  ///
  /// 根据操作系统使用不同的方式终止进程：
  /// - Windows: 使用 taskkill 命令强制终止
  /// - 其他系统: 发送 SIGTERM 信号
  ///
  /// [process] 要停止的进程对象
  void stop(Process process) {
    if (Platform.isWindows) {
      // Windows 使用 taskkill 强制终止进程
      unawaited(
        Process.run('taskkill', ['/F', '/PID', process.pid.toString()]),
      );
    } else {
      // 其他平台发送终止信号
      process.kill(ProcessSignal.sigterm);
    }
    _logger.info('Stop signal sent to process PID: ${process.pid}');
  }
}

/// 进程启动失败异常
class ProcessStartFailedError implements Exception {
  final Object? originalError;
  final StackTrace? stackTrace;

  const ProcessStartFailedError({this.originalError, this.stackTrace});

  @override
  String toString() => 'ProcessStartFailedError: $originalError';
}
