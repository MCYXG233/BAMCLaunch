import 'package:flutter/material.dart';
import 'models.dart';
import 'game_launcher.dart';

/// 启动按钮组件
class LaunchButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLaunching;

  const LaunchButton({super.key, this.onPressed, this.isLaunching = false});

  @override
  State<LaunchButton> createState() => _LaunchButtonState();
}

class _LaunchButtonState extends State<LaunchButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLaunching ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: widget.isLaunching
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('启动游戏'),
    );
  }
}

/// 游戏日志控制台组件
class GameConsole extends StatefulWidget {
  final String processId;

  const GameConsole({super.key, required this.processId});

  @override
  State<GameConsole> createState() => _GameConsoleState();
}

class _GameConsoleState extends State<GameConsole> {
  final List<GameLog> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _subscribeToLogs();
  }

  void _subscribeToLogs() {
    final launcher = GameLauncher();
    launcher.getLogStream(widget.processId).listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 1000) {
            _logs.removeAt(0);
          }
        });
        if (_autoScroll) {
          _scrollToBottom();
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                const Text(
                  '控制台',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                  },
                  tooltip: _autoScroll ? '暂停自动滚动' : '启用自动滚动',
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  tooltip: '清空日志',
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      '等待输出...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Text(
                        log.format(),
                        style: TextStyle(
                          color: _getLogColor(log.level),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(GameLogLevel level) {
    switch (level) {
      case GameLogLevel.error:
        return Colors.red;
      case GameLogLevel.warn:
        return Colors.orange;
      case GameLogLevel.debug:
        return Colors.grey;
      case GameLogLevel.info:
      default:
        return Colors.white;
    }
  }
}

/// 游戏进程卡片组件
class GameProcessCard extends StatelessWidget {
  final GameProcessInfo processInfo;
  final VoidCallback? onStop;

  const GameProcessCard({super.key, required this.processInfo, this.onStop});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minecraft ${processInfo.arguments.gameVersion}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '玩家: ${processInfo.arguments.account.username}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_getStatusText()),
                  backgroundColor: _getStatusColor().withOpacity(0.1),
                  labelStyle: TextStyle(color: _getStatusColor()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('PID: ${processInfo.pid ?? 'N/A'}'),
                const SizedBox(width: 16),
                Text('内存: ${processInfo.arguments.memory}MB'),
                const SizedBox(width: 16),
                Text('运行时间: ${_formatDuration(processInfo.duration)}'),
              ],
            ),
            if (processInfo.isRunning) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (processInfo.status) {
      case GameProcessStatus.starting:
        return Icons.hourglass_empty;
      case GameProcessStatus.running:
        return Icons.play_arrow;
      case GameProcessStatus.stopped:
        return Icons.stop;
      case GameProcessStatus.crashed:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (processInfo.status) {
      case GameProcessStatus.starting:
        return Colors.orange;
      case GameProcessStatus.running:
        return Colors.green;
      case GameProcessStatus.stopped:
        return Colors.grey;
      case GameProcessStatus.crashed:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (processInfo.status) {
      case GameProcessStatus.starting:
        return '启动中';
      case GameProcessStatus.running:
        return '运行中';
      case GameProcessStatus.stopped:
        return '已停止';
      case GameProcessStatus.crashed:
        return '已崩溃';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours时$minutes分$seconds秒';
    } else if (minutes > 0) {
      return '$minutes分$seconds秒';
    } else {
      return '$seconds秒';
    }
  }
}
