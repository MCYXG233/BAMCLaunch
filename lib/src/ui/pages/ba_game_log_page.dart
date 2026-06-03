import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/ba_theme_colors.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../components/log_panel.dart';

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
  Timer? _fileWatcherTimer;
  File? _logFile;
  int _lastFileLength = 0;

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

    // 设置日志文件监控
    _setupLogFileWatcher();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logs.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  void _setupLogFileWatcher() {
    final processInfo = _processInfo;
    if (processInfo == null) return;

    final logDir = Directory('${processInfo.arguments.gameDirectory}/logs');
    if (!logDir.existsSync()) return;

    // 查找最新的日志文件
    try {
      final files = logDir.listSync()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      if (files.isNotEmpty && files.first is File) {
        _logFile = files.first as File;
        _lastFileLength = _logFile!.lengthSync();
      }
    } catch (e) {
      // 忽略错误
    }

    // 每500ms检查日志文件变化
    _fileWatcherTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkLogFileChanges(),
    );
  }

  void _checkLogFileChanges() {
    if (_logFile == null || !_logFile!.existsSync()) return;

    try {
      final currentLength = _logFile!.lengthSync();
      if (currentLength > _lastFileLength) {
        // 有新内容，读取新增的日志
        final raf = _logFile!.openSync(mode: FileMode.read);
        raf.setPositionSync(_lastFileLength);
        final bytes = raf.read(currentLength - _lastFileLength);
        raf.closeSync();
        
        final newContent = String.fromCharCodes(bytes);
        final newLines = newContent.split('\n').where((l) => l.trim().isNotEmpty);
        
        for (final line in newLines) {
          final log = GameLog(
            timestamp: DateTime.now(),
            level: _parseLogLevel(line),
            message: line,
            source: 'file',
          );
          _onLogReceived(log);
        }
        
        _lastFileLength = currentLength;
      }
    } catch (e) {
      // 忽略读取错误
    }
  }

  GameLogLevel _parseLogLevel(String line) {
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

  @override
  void dispose() {
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _durationTimer?.cancel();
    _fileWatcherTimer?.cancel();
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
      if (_logs.length > 5000) {
        _logs.removeRange(0, 1000);
      }
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

    final header = 'BAMCLaunch 游戏日志\n'
        '进程ID: ${widget.processId}\n'
        '版本: ${_processInfo?.arguments.gameVersion ?? "未知"}\n'
        '时间: ${DateTime.now().toIso8601String()}\n';

    final result = await LogExporter.exportToFile(
      _logs,
      savePath: path,
      header: header,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('日志已导出到 $path'),
            backgroundColor: BAThemeColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('导出失败'),
            backgroundColor: BAThemeColors.danger,
          ),
        );
      }
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _showLogDetails(GameLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BAThemeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BAThemeData.radius),
        ),
        title: Row(
          children: [
            Icon(
              _getLevelIcon(log.level),
              color: _levelColor(log.level),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '日志详情',
              style: TextStyle(
                color: BAThemeColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          width: 500,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAThemeColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('时间', _formatTime(log.timestamp)),
              _buildDetailRow('级别', _levelLabel(log.level)),
              _buildDetailRow('来源', log.source),
              const SizedBox(height: 12),
              Text(
                '消息内容:',
                style: TextStyle(
                  color: BAThemeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                log.message,
                style: TextStyle(
                  color: BAThemeColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Consolas',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(color: BAThemeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                color: BAThemeColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: BAThemeColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLevelIcon(GameLogLevel level) {
    switch (level) {
      case GameLogLevel.info:
        return Icons.info_outline;
      case GameLogLevel.warn:
        return Icons.warning_amber_outlined;
      case GameLogLevel.error:
        return Icons.error_outline;
      case GameLogLevel.debug:
        return Icons.bug_report_outlined;
    }
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

  int get _infoCount => _logs.where((l) => l.level == GameLogLevel.info).length;
  int get _warnCount => _logs.where((l) => l.level == GameLogLevel.warn).length;
  int get _errorCount => _logs.where((l) => l.level == GameLogLevel.error).length;

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(_status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(_status),
                  style: TextStyle(
                    color: _statusColor(_status),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: BAThemeColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '$_infoCount',
                style: TextStyle(
                  color: BAThemeColors.success,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.warning_amber_outlined,
                size: 14,
                color: BAThemeColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                '$_warnCount',
                style: TextStyle(
                  color: BAThemeColors.warning,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.error_outline,
                size: 14,
                color: BAThemeColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                '$_errorCount',
                style: TextStyle(
                  color: BAThemeColors.danger,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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

    return InkWell(
      onTap: () => _showLogDetails(log),
      child: Padding(
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
