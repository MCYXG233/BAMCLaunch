import '../../core/logger.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import 'models.dart';

/// 游戏就绪检测器
///
/// 从 GameLauncher 拆分出的单一职责组件，负责：
/// - 通过检测输出中的特定关键字判断游戏是否已完全启动
/// - 检测到就绪后发布 [GameReadyEvent] 事件
///
/// 设计原则：
/// - 不持有进程级业务状态（_runningProcesses / _launchingStates 由主类管理）
/// - 通过参数接收所需的进程信息
/// - 可独立单测
class GameReadyDetector {
  final Logger _logger = Logger('GameReadyDetector');

  /// 游戏就绪关键字
  ///
  /// 这些关键字出现在游戏输出中表示游戏已完全启动。
  static const List<String> readyKeywords = [
    'render thread',
    'glfw',
    'setting user',
    'lwjgl',
  ];

  /// 检查游戏是否已就绪
  ///
  /// 通过检测输出中的特定关键字来判断游戏是否已完全启动。
  /// 检测到就绪后会：
  /// 1. 更新 [GameProcessInfo.readyTime]
  /// 2. 触发 [onReady] 回调（主类用于更新 LaunchingState）
  /// 3. 发布 [GameReadyEvent] 事件
  ///
  /// [processId] 进程ID
  /// [line] 输出行
  /// [processInfo] 进程信息（用于检查和更新 readyTime）
  /// [eventBus] 事件总线（用于发布就绪事件）
  /// [onReady] 就绪回调（主类用于更新启动状态）
  void checkGameReady({
    required String processId,
    required String line,
    required GameProcessInfo processInfo,
    required EventBus eventBus,
    required void Function(DateTime readyTime) onReady,
  }) {
    // 如果已经记录了就绪时间，则跳过
    if (processInfo.readyTime != null) return;

    final lower = line.toLowerCase();
    if (readyKeywords.any((keyword) => lower.contains(keyword))) {
      _logger.info('Game is ready');
      final readyTime = DateTime.now();
      processInfo.readyTime = readyTime;
      onReady(readyTime);

      eventBus.publish(
        GameReadyEvent(
          processId: processId,
          version: processInfo.arguments.gameVersion,
          username: processInfo.arguments.account.username,
        ),
      );
    }
  }
}
