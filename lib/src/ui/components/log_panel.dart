import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../game/launcher/models.dart';
import '../theme/ba_theme_colors.dart';

/// 日志面板组件
///
/// 提供实时日志显示、日志过滤、自动滚动等功能
class LogPanel extends StatefulWidget {
  /// 日志流
  final Stream<GameLog>? logStream;

  /// 初始日志列表
  final List<GameLog>? initialLogs;

  /// 是否显示工具栏
  final bool showToolbar;

  /// 是否显示状态栏
  final bool showStatusBar;

  /// 最小高度
  final double? minHeight;

  /// 最大高度
  final double? maxHeight;

  /// 高度比例（相对于父容器）
  final double? heightRatio;

  /// 日志改变回调
  final ValueChanged<List<GameLog>>? onLogsChanged;

  const LogPanel({
    super.key,
    this.logStream,
    this.initialLogs,
    this.showToolbar = true,
    this.showStatusBar = true,
    this.minHeight,
    this.maxHeight,
    this.heightRatio,
    this.onLogsChanged,
  });

  @override
  State<LogPanel> createState() => LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  final Logger _logger = Logger('LogPanel');

  final List<GameLog> _logs = [];
  StreamSubscription<GameLog>? _logSubscription;

  Set<GameLogLevel> _visibleLevels = GameLogLevel.values.toSet();
  String _filterText = '';
  bool _autoScroll = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLogs != null) {
      _logs.addAll(widget.initialLogs!);
    }
    _setupLogStream();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _setupLogStream() {
    if (widget.logStream != null) {
      _logSubscription = widget.logStream!.listen(
        _onLogReceived,
        onError: (e) => _logger.error('Log stream error', e),
        onDone: () => _logger.debug('Log stream closed'),
      );
    }
  }

  void _onLogReceived(GameLog log) {
    if (_isPaused) return;

    setState(() {
      _logs.add(log);
      if (_logs.length > 5000) {
        _logs.removeRange(0, 1000);
      }
    });

    widget.onLogsChanged?.call(_logs);

    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    _autoScroll = (maxScroll - currentScroll) < 100;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  List<GameLog> get _filteredLogs {
    var logs = _logs;

    // 按级别过滤
    if (_visibleLevels.length != GameLogLevel.values.length) {
      logs = logs.where((log) => _visibleLevels.contains(log.level)).toList();
    }

    // 按文本过滤
    if (_filterText.isNotEmpty) {
      final lowerFilter = _filterText.toLowerCase();
      logs = logs.where((log) => log.message.toLowerCase().contains(lowerFilter)).toList();
    }

    return logs;
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

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    widget.onLogsChanged?.call(_logs);
  }

  void _onFilterChanged(String value) {
    setState(() {
      _filterText = value;
    });
  }

  int get _infoCount => _logs.where((l) => l.level == GameLogLevel.info).length;
  int get _warnCount => _logs.where((l) => l.level == GameLogLevel.warn).length;
  int get _errorCount => _logs.where((l) => l.level == GameLogLevel.error).length;

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    final ms = local.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
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
        return BAThemeColors.success;
      case GameLogLevel.warn:
        return BAThemeColors.warning;
      case GameLogLevel.error:
        return BAThemeColors.danger;
      case GameLogLevel.debug:
        return BAThemeColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.minHeight ?? 200,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        color: BAThemeColors.backgroundDark,
        borderRadius: BorderRadius.circular(BAThemeData.radius),
        border: Border.all(color: BAThemeColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (widget.showToolbar) _buildToolbar(),
          if (widget.showToolbar) _buildFilterBar(),
          Expanded(child: _buildLogArea()),
          if (widget.showStatusBar) _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          bottom: BorderSide(color: BAThemeColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal,
            size: 18,
            color: BAThemeColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '日志',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isPaused)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BAThemeColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause, size: 14, color: BAThemeColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '已暂停',
                    style: TextStyle(
                      color: BAThemeColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: _isPaused ? Icons.play_arrow : Icons.pause,
            tooltip: _isPaused ? '继续' : '暂停',
            onPressed: _togglePause,
          ),
          _buildToolbarButton(
            icon: Icons.vertical_align_bottom,
            tooltip: '滚动到底部',
            onPressed: _scrollToBottom,
          ),
          _buildToolbarButton(
            icon: Icons.delete_outline,
            tooltip: '清空日志',
            onPressed: _clearLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: BAThemeColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BAThemeColors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: BAThemeColors.border.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: BAThemeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: BAThemeColors.border.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _filterController,
                onChanged: _onFilterChanged,
                style: TextStyle(
                  color: BAThemeColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '过滤日志...',
                  hintStyle: TextStyle(color: BAThemeColors.textDisabled),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: BAThemeColors.textDisabled,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildLevelFilterChip('全部', GameLogLevel.values.toSet()),
          const SizedBox(width: 6),
          _buildLevelFilterChip('INFO', {GameLogLevel.info}),
          const SizedBox(width: 6),
          _buildLevelFilterChip('WARN', {GameLogLevel.warn}),
          const SizedBox(width: 6),
          _buildLevelFilterChip('ERROR', {GameLogLevel.error}),
        ],
      ),
    );
  }

  Widget _buildLevelFilterChip(String label, Set<GameLogLevel> levels) {
    final isSelected = _visibleLevels.length == levels.length ||
        (levels.length == 1 && _visibleLevels.contains(levels.first));

    return GestureDetector(
      onTap: () {
        if (levels.length == GameLogLevel.values.length) {
          setState(() {
            _visibleLevels = GameLogLevel.values.toSet();
          });
        } else {
          setState(() {
            _visibleLevels = levels;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? BAThemeColors.primary.withOpacity(0.15)
              : BAThemeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? BAThemeColors.primary.withOpacity(0.4)
                : BAThemeColors.border.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? BAThemeColors.primaryLight
                : BAThemeColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogArea() {
    final filtered = _filteredLogs;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 36,
              color: BAThemeColors.textDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              _filterText.isEmpty ? '等待日志输出...' : '没有匹配的日志',
              style: TextStyle(
                color: BAThemeColors.textDisabled,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final log = filtered[index];
        return _buildLogLine(log);
      },
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
            fontSize: 12,
            height: 1.4,
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

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          top: BorderSide(color: BAThemeColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildStatusItem(Icons.info_outline, 'INFO', _infoCount, BAThemeColors.success),
          const SizedBox(width: 16),
          _buildStatusItem(Icons.warning_amber_outlined, 'WARN', _warnCount, BAThemeColors.warning),
          const SizedBox(width: 16),
          _buildStatusItem(Icons.error_outline, 'ERROR', _errorCount, BAThemeColors.danger),
          const Spacer(),
          Text(
            '共 ${_filteredLogs.length} 条日志',
            style: TextStyle(
              color: BAThemeColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (_autoScroll) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: BAThemeColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '自动滚动',
                style: TextStyle(
                  color: BAThemeColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 日志导出器
class LogExporter {
  /// 导出日志到文件
  static Future<String?> exportToFile(
    List<GameLog> logs, {
    required String savePath,
    String? header,
  }) async {
    try {
      final file = File(savePath);
      final sink = file.openWrite();

      if (header != null) {
        sink.writeln(header);
        sink.writeln('=' * 60);
        sink.writeln();
      }

      for (final log in logs) {
        sink.writeln(log.format());
      }

      await sink.close();
      return savePath;
    } catch (e) {
      return null;
    }
  }

  /// 获取导出文件名
  static String generateFileName({String? prefix}) {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final name = prefix ?? 'game_log';
    return '${name}_${date}_$time.log';
  }
}
