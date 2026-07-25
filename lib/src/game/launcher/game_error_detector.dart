import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/logger.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import 'models.dart';

/// 游戏错误检测器
///
/// 从 GameLauncher 拆分出的单一职责组件，负责：
/// - 扫描输出行中的错误关键字
/// - 与已知故障模式库匹配
/// - 生成崩溃诊断报告
///
/// 设计原则：
/// - 不持有进程级业务状态（_runningProcesses 由主类管理）
/// - 通过参数接收所需的进程信息
/// - 可独立单测
class GameErrorDetector {
  final Logger _logger = Logger('GameErrorDetector');

  /// 已知故障模式库
  ///
  /// 键为错误特征字符串，值为对应的诊断建议。
  static const Map<String, String> knownCrashPatterns = {
    'OutOfMemoryError': '内存不足。请在设置中增加分配的内存，或关闭其他程序释放内存。',
    'java.lang.OutOfMemoryError': 'Java 堆内存不足。请在设置中增加分配的内存。',
    'ClassNotFoundException': '缺少必要的类文件。请检查游戏完整性或重新安装。',
    'NoClassDefFoundError': '缺少必要的类文件。请检查 Mod 兼容性或重新安装。',
    'IncompatibleClassChangeError': '类版本冲突。请检查 Mod 兼容性。',
    'UnsupportedClassVersionError': 'Java 版本不兼容。请检查是否使用了正确版本的 Java。',
    'GLFW error 65542': 'GLFW 错误：显卡驱动不兼容。请更新显卡驱动。',
    'GLFW error 65548': 'GLFW 错误：OpenGL 版本过低。请更新显卡驱动。',
    'Could not create the Java Virtual Machine':
        '无法创建 Java 虚拟机。请检查 Java 路径和 JVM 参数。',
    'java.lang.StackOverflowError': '栈溢出。请检查是否有无限递归或增加栈大小。',
    'LWJGL error': 'LWJGL 初始化失败。请更新显卡驱动或检查 OpenGL 支持。',
    'Shaders not supported': '显卡不支持着色器。请关闭着色器或更新显卡驱动。',
    'Failed to authenticate': '认证失败。请重新登录账户。',
    'Session ID is null': '会话 ID 为空。请重新登录账户。',
    'TimeoutException': '连接超时。请检查网络连接。',
    'SocketException': '网络连接失败。请检查网络设置。',
    'java.net.ConnectException': '连接被拒绝。请检查服务器地址和端口。',
  };

  /// 已检测到的崩溃模式（按进程ID分组）
  final Map<String, Map<String, String>> _detectedCrashPatterns = {};

  /// 检查输出中的错误信息
  ///
  /// 扫描输出行中是否包含错误关键字，与已知故障模式库进行匹配。
  /// 匹配到的模式会被记录到 [_detectedCrashPatterns] 中。
  ///
  /// [processId] 进程ID
  /// [line] 输出行
  void checkForErrors(String processId, String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('exception') ||
        lower.contains('crash') ||
        lower.contains('failed') ||
        lower.contains('fatal')) {
      _logger.warn('Potential error detected in game output: $line');

      for (final entry in knownCrashPatterns.entries) {
        if (line.contains(entry.key)) {
          _detectedCrashPatterns.putIfAbsent(processId, () => {});
          final patterns = _detectedCrashPatterns[processId]!;
          if (!patterns.containsKey(entry.key)) {
            patterns[entry.key] = entry.value;
            _logger.warn(
              'Crash pattern matched: ${entry.key} -> ${entry.value}',
            );
          }
        }
      }
    }
  }

  /// 查找最新的崩溃报告文件
  ///
  /// 在游戏目录的 `crash-reports/` 子目录中查找最新的 `.txt` 崩溃报告文件，
  /// 并读取其最后 50 行内容。
  Future<String?> findLatestCrashReport(String gameDir) async {
    try {
      final crashDir = Directory(path.join(gameDir, 'crash-reports'));
      if (!await crashDir.exists()) return null;

      File? latestFile;
      DateTime? latestTime;

      await for (final entity in crashDir.list()) {
        if (entity is File && entity.path.endsWith('.txt')) {
          final stat = await entity.stat();
          if (latestTime == null || stat.modified.isAfter(latestTime)) {
            latestTime = stat.modified;
            latestFile = entity;
          }
        }
      }

      if (latestFile != null) {
        final lines = await latestFile.readAsLines();
        final tailLines = lines.length > 50
            ? lines.sublist(lines.length - 50)
            : lines;
        return tailLines.join('\n');
      }
    } catch (e) {
      _logger.warn('Failed to read crash report: $e');
    }
    return null;
  }

  /// 分析崩溃日志，生成诊断报告
  ///
  /// 收集进程的最后 [maxLogLines] 行日志，结合已匹配的故障模式，
  /// 生成格式化的诊断报告并通过 [CrashDiagnosticEvent] 发布到 EventBus。
  ///
  /// [processId] 进程ID
  /// [processInfo] 进程信息（用于收集日志和元数据）
  /// [eventBus] 事件总线（用于发布诊断事件）
  /// [maxLogLines] 收集的最大日志行数
  Future<String> analyzeCrashLog({
    required String processId,
    required GameProcessInfo processInfo,
    required EventBus eventBus,
    int maxLogLines = 50,
  }) async {
    final matchedPatterns = _detectedCrashPatterns[processId] ?? {};
    final buffer = StringBuffer();

    buffer.writeln('========== 崩溃诊断报告 ==========');
    buffer.writeln('进程ID: $processId');
    buffer.writeln('分析时间: ${DateTime.now().toLocal()}');
    buffer.writeln('游戏版本: ${processInfo.arguments.gameVersion}');
    buffer.writeln('退出码: ${processInfo.exitCode ?? "未知"}');
    buffer.writeln('运行时长: ${processInfo.duration.inSeconds} 秒');

    buffer.writeln();
    if (matchedPatterns.isNotEmpty) {
      buffer.writeln('--- 匹配到的故障模式 ---');
      for (final entry in matchedPatterns.entries) {
        buffer.writeln('  [${entry.key}]');
        buffer.writeln('    建议: ${entry.value}');
      }
    } else {
      buffer.writeln('--- 未匹配到已知故障模式 ---');
      buffer.writeln('  请查看下方日志输出以获取更多线索。');
    }

    buffer.writeln();
    buffer.writeln('--- 最近 $maxLogLines 行日志 ---');

    // 检查 crash-reports 目录中的最新崩溃报告
    final crashReport = await findLatestCrashReport(
      processInfo.arguments.gameDirectory,
    );
    if (crashReport != null) {
      buffer.writeln();
      buffer.writeln('--- crash-reports 最新报告 ---');
      buffer.writeln(crashReport);
      buffer.writeln('--- crash-reports 报告结束 ---');
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('--- 最近 $maxLogLines 行游戏日志 ---');
    final recentLogs = processInfo.getRecentLogs(maxLogLines);
    for (final log in recentLogs) {
      buffer.writeln(log.format());
    }

    buffer.writeln('====================================');

    final report = buffer.toString();
    _logger.info('Crash diagnostic report generated for process $processId');

    eventBus.publish(
      CrashDiagnosticEvent(
        processId: processId,
        matchedPatterns: Map.unmodifiable(matchedPatterns),
        diagnosticReport: report,
      ),
    );

    return report;
  }

  /// 清理指定进程的崩溃模式记录
  void clear(String processId) {
    _detectedCrashPatterns.remove(processId);
  }
}
