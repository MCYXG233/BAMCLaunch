import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/ba_theme_colors.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';

class BAGameLogPage extends StatefulWidget {
  final String processId;

  const BAGameLogPage({super.key, required this.processId});

  @override
  State<BAGameLogPage> createState() => _BAGameLogPageState();
}

class _BAGameLogPageState extends State<BAGameLogPage> {
  final GameLauncher _launcher = GameLauncher();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<GameLog>? _logSubscription;
  StreamSubscription<GameProcessStatus>? _statusSubscription;

  final List<GameLog> _logs = [];
  GameProcessStatus _status = GameProcessStatus.starting;
  Set<GameLogLevel> _visibleLevels = GameLogLevel.values.toSet();
  bool _autoScroll = true;
  bool _processExists = true;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  GameProcessInfo? get _processInfo =>
      _launcher.runningProcesses[widget.processId];

  @override
  void initState() {
    super.initState();

    final processInfo = _processInfo;
    if (processInfo == null) {
      _processExists = false;
    } else {
      _logs.addAll(processInfo.logs);
      _status = processInfo.status;
      _elapsed = processInfo.duration;
    }

    _scrollController.addListener(_onScroll);

    _logSubscription = _launcher
        .getLogStream(widget.processId)
        .listen(_onLogReceived);

    _statusSubscription = _launcher
        .getStatusStream(widget.processId)
        .listen(_onStatusChanged);

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDuration(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logs.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _durationTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    _autoScroll = (maxScroll - currentScroll) < 100;
  }

  void _onLogReceived(GameLog log) {
    setState(() {
      _logs.add(log);
    });
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onStatusChanged(GameProcessStatus status) {
    setState(() {
      _status = status;
    });
  }

  void _updateDuration() {
    final processInfo = _processInfo;
    if (processInfo == null) return;
    setState(() {
      _elapsed = processInfo.duration;
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  List<GameLog> get _filteredLogs {
    if (_visibleLevels.length == GameLogLevel.values.length) return _logs;
    return _logs.where((log) => _visibleLevels.contains(log.level)).toList();
  }

  void _toggleLevel(GameLogLevel level) {
    setState(() {
      if (_visibleLevels.contains(level)) {
        if (_visibleLevels.length > 1) {
          _visibleLevels.remove(level);
        }
      } else {
        _visibleLevels.add(level);
      }
    });
  }

  Future<void> _stopGame() async {
    await _launcher.stop(widget.processId);
  }

  Future<void> _exportLogs() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出游戏日志',
      fileName: 'game_log_${widget.processId}.log',
      type: FileType.custom,
      allowedExtensions: ['log'],
    );
    if (path == null) return;

    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(log.format());
    }

    final file = File(path);
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志已导出到 $path'),
          backgroundColor: BAThemeColors.success,
        ),
      );
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String _levelLabel(GameLogLevel level) {
    switch (level) {
      case GameLogLevel.debug:
        return 'DEBUG';
      case GameLogLevel.info:
        return 'INFO';
      case GameLogLevel.warn:
        return 'WARN';
      case GameLogLevel.error:
        return 'ERROR';
    }
  }

  Color _levelColor(GameLogLevel level) {
    switch (level) {
      case GameLogLevel.info:
        return BAThemeColors.textPrimary;
      case GameLogLevel.warn:
        return BAThemeColors.warning;
      case GameLogLevel.error:
        return BAThemeColors.danger;
      case GameLogLevel.debug:
        return BAThemeColors.textDisabled;
    }
  }

  Color _statusColor(GameProcessStatus status) {
    switch (status) {
      case GameProcessStatus.starting:
        return BAThemeColors.info;
      case GameProcessStatus.running:
        return BAThemeColors.success;
      case GameProcessStatus.stopped:
        return BAThemeColors.textSecondary;
      case GameProcessStatus.crashed:
        return BAThemeColors.danger;
    }
  }

  String _statusLabel(GameProcessStatus status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    if (!_processExists) {
      return _buildNotFound();
    }

    return Container(
      color: BAThemeColors.background,
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(child: _buildLogArea()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      color: BAThemeColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: BAThemeColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              '进程不存在',
              style: TextStyle(
                color: BAThemeColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '该游戏进程可能已结束或未找到',
              style: TextStyle(
                color: BAThemeColors.textDisabled,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          bottom: BorderSide(color: BAThemeColors.border.withOpacity(0.4)),
        ),
        boxShadow: [
          BoxShadow(
            color: BAThemeColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BAThemeColors.primary, BAThemeColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: BAThemeColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.terminal, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            '游戏日志',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(_status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _statusColor(_status).withOpacity(0.4),
              ),
            ),
            child: Text(
              _statusLabel(_status),
              style: TextStyle(
                color: _statusColor(_status),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (_status == GameProcessStatus.starting ||
              _status == GameProcessStatus.running)
            _buildStopButton(),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: _stopGame,
        icon: const Icon(Icons.stop, size: 16),
        label: const Text('停止游戏'),
        style: ElevatedButton.styleFrom(
          backgroundColor: BAThemeColors.danger,
          foregroundColor: BAThemeColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: BAThemeColors.surface.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: BAThemeColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '级别过滤:',
            style: TextStyle(
              color: BAThemeColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterChip('全部', _visibleLevels.length == GameLogLevel.values.length, () {
            setState(() {
              _visibleLevels = GameLogLevel.values.toSet();
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('INFO', _visibleLevels.contains(GameLogLevel.info) && _visibleLevels.length == 1, () {
            setState(() {
              _visibleLevels = {GameLogLevel.info};
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('WARN', _visibleLevels.contains(GameLogLevel.warn) && _visibleLevels.length == 1, () {
            setState(() {
              _visibleLevels = {GameLogLevel.warn};
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('ERROR', _visibleLevels.contains(GameLogLevel.error) && _visibleLevels.length == 1, () {
            setState(() {
              _visibleLevels = {GameLogLevel.error};
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? BAThemeColors.primary.withOpacity(0.15)
              : BAThemeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? BAThemeColors.primary
                : BAThemeColors.border.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? BAThemeColors.primaryLight
                : BAThemeColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogArea() {
    final filtered = _filteredLogs;

    if (filtered.isEmpty) {
      return Container(
        color: BAThemeColors.backgroundDark,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 48,
                color: BAThemeColors.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                '等待游戏输出...',
                style: TextStyle(
                  color: BAThemeColors.textDisabled,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: BAThemeColors.backgroundDark,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final log = filtered[index];
          return _buildLogLine(log);
        },
      ),
    );
  }

  Widget _buildLogLine(GameLog log) {
    final color = _levelColor(log.level);
    final levelStr = _levelLabel(log.level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Consolas',
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '[${_formatTime(log.timestamp)}] ',
              style: TextStyle(color: BAThemeColors.textDisabled),
            ),
            TextSpan(
              text: '[$levelStr] ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: log.message,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          top: BorderSide(color: BAThemeColors.border.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, size: 16, color: BAThemeColors.textDisabled),
          const SizedBox(width: 6),
          Text(
            '共 ${_filteredLogs.length} 条日志',
            style: TextStyle(
              color: BAThemeColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 20),
          Icon(Icons.timer_outlined, size: 16, color: BAThemeColors.textDisabled),
          const SizedBox(width: 6),
          Text(
            '运行 ${_formatDuration(_elapsed)}',
            style: TextStyle(
              color: BAThemeColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: _exportLogs,
              icon: const Icon(Icons.save_alt, size: 15),
              label: const Text('导出日志'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BAThemeColors.textSecondary,
                side: BorderSide(color: BAThemeColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: _clearLogs,
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('清空日志'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BAThemeColors.textSecondary,
                side: BorderSide(color: BAThemeColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
