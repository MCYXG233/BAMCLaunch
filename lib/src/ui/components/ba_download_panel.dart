import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../resource_center/download_manager.dart';
import 'ba_common_widgets.dart';

/// 下载面板（右下角弹出式）
///
/// 显示当前下载任务和已完成任务。参考 PC 启动器的风格：
/// - 右下角浮动显示
/// - 点击可展开/收起
/// - 显示每个任务的进度条、状态图标、资源名、目标实例
/// - 显示当前速度和剩余时间
/// - 点击任务可查看详情或取消
///
/// ## 使用方式
///
/// ```dart
/// Stack(
///   children: [
///     // ... 其他内容
///     DownloadPanel(),
///   ],
/// )
/// ```
class DownloadPanel extends StatefulWidget {
  const DownloadPanel({
    super.key,
  });

  @override
  State<DownloadPanel> createState() => _DownloadPanelState();
}

class _DownloadPanelState extends State<DownloadPanel> {
  final DownloadManager _manager = DownloadManager.instance;
  late StreamSubscription<DownloadTask> _subscription;

  bool _isExpanded = false;
  List<DownloadTask> _activeTasks = [];
  List<DownloadTask> _completedTasks = [];

  @override
  void initState() {
    super.initState();

    _subscription = _manager.onTaskUpdate.listen((task) {
      if (!mounted) return;
      setState(() {
        // 更新任务列表
        if (task.status == DownloadTaskStatus.completed ||
            task.status == DownloadTaskStatus.failed ||
            task.status == DownloadTaskStatus.cancelled) {
          _activeTasks.removeWhere((t) => t.id == task.id);
          if (!_completedTasks.any((t) => t.id == task.id)) {
            _completedTasks.insert(0, task);
          }
        } else {
          final index = _activeTasks.indexWhere((t) => t.id == task.id);
          if (index >= 0) {
            _activeTasks[index] = task;
          } else {
            _activeTasks.add(task);
          }
        }
      });
    });

    // 初始同步
    _activeTasks = List.from(_manager.activeTasks);
    _completedTasks = List.from(_manager.completedTasks);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // 只有有任务时才显示
    final showPanel = _activeTasks.isNotEmpty || _completedTasks.isNotEmpty;
    if (!showPanel && !_isExpanded) return const SizedBox.shrink();

    return Positioned(
      right: 20,
      bottom: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 320,
        height: _isExpanded ? 400 : 80,
        decoration: BoxDecoration(
          color: isLight
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF1E2A44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight
                ? const Color(0xFFD0D8EE)
                : const Color(0xFF3A4D7A),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              _buildHeader(context, isLight),

              // 内容区域
              if (_isExpanded)
                _buildContent(context, isLight)
              else
                // 收起状态只显示整体进度
                _buildCollapsedSummary(context, isLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLight) {
    final activeCount = _activeTasks.length;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              BacolorsAccentPink,
              const Color(0xFF6A7FD9),
            ],
          ),
        ),
        child: Row(
          children: [
            // 下载图标
            Icon(
              _activeTasks.isEmpty ? Icons.download_done : Icons.downloading,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),

            // 标题
            Text(
              activeCount > 0 ? '下载中 ($activeCount)' : '下载管理',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            // 清除按钮（仅展开时可见）
            if (_isExpanded && _completedTasks.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _manager.clearCompleted();
                    _completedTasks.clear();
                  });
                },
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
              ),

            const SizedBox(width: 8),

            // 展开/收起箭头
            Icon(
              _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSummary(BuildContext context, bool isLight) {
    final activeTasks = _activeTasks;
    if (activeTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: BacolorsSuccess,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${_completedTasks.length} 个任务已完成',
              style: TextStyle(
                color: isLight ? const Color(0xFF1A2744) : Colors.white,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '点击展开',
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF8899B5)
                    : const Color(0xFFA0B0C8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // 显示第一个任务的进度
    final task = activeTasks.first;
    final overallProgress = _calculateOverallProgress();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.resource.name,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(overallProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: BacolorsAccentPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 整体进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              backgroundColor: isLight
                  ? const Color(0xFFD0D8EE)
                  : const Color(0xFF3A4D7A),
              valueColor: AlwaysStoppedAnimation<Color>(BacolorsPrimary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isLight) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _activeTasks.length + _completedTasks.length + 2,
        itemBuilder: (context, index) {
          if (_activeTasks.isNotEmpty && index == 0) {
            return _buildSectionHeader(
              '正在下载 (${_activeTasks.length})',
              isLight,
            );
          }
          if (index <= _activeTasks.length && _activeTasks.isNotEmpty) {
            return _buildTaskTile(_activeTasks[index - 1], isLight);
          }
          if (index == _activeTasks.length + 1 && _completedTasks.isNotEmpty) {
            return _buildSectionHeader(
              '已完成 (${_completedTasks.length})',
              isLight,
            );
          }
          if (_completedTasks.isNotEmpty) {
            final completedIndex =
                index - _activeTasks.length - (_activeTasks.isNotEmpty ? 2 : 1);
            if (completedIndex >= 0 && completedIndex < _completedTasks.length) {
              return _buildTaskTile(_completedTasks[completedIndex], isLight);
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        title,
        style: TextStyle(
          color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTaskTile(DownloadTask task, bool isLight) {
    final isActive = task.status == DownloadTaskStatus.downloading ||
        task.status == DownloadTaskStatus.pending;
    final titleColor = isLight ? const Color(0xFF1A2744) : Colors.white;
    final subtitleColor =
        isLight ? const Color(0xFF6A7BA5) : const Color(0xFFA0B0C8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF5F8FF)
            : const Color(0xFF1E2747),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight
              ? const Color(0xFFD0D8EE)
              : const Color(0xFF2A3A5A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 资源类型图标
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getTypeColor(task.resource.type),
                      _getTypeColor(task.resource.type).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(task.resource.type),
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),

              // 资源名
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.resource.name,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${task.version.versionNumber} · ${task.targetInstance}',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 状态图标或取消按钮
              if (task.status == DownloadTaskStatus.completed)
                Icon(Icons.check_circle, color: BacolorsSuccess, size: 20)
              else if (task.status == DownloadTaskStatus.failed)
                Tooltip(
                  message: task.errorMessage ?? '下载失败',
                  child: Icon(Icons.error, color: BacolorsDanger, size: 20),
                )
              else if (task.status == DownloadTaskStatus.cancelled)
                Icon(Icons.cancel, color: subtitleColor, size: 20)
              else if (task.status == DownloadTaskStatus.installing)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: BacolorsPrimary,
                    strokeWidth: 2,
                  ),
                )
              else
                // 下载中/等待 - 显示取消按钮
                GestureDetector(
                  onTap: () => _manager.cancelTask(task.id),
                  child: Icon(
                    Icons.close,
                    color: subtitleColor,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 进度条
          if (isActive) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0.0, 1.0),
                backgroundColor: isLight
                    ? const Color(0xFFD0D8EE)
                    : const Color(0xFF3A4D7A),
                valueColor: AlwaysStoppedAnimation<Color>(BacolorsPrimary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${task.progress * 100 >= 10 ? (task.downloadedBytes / 1024 / 1024).toStringAsFixed(1) : (task.downloadedBytes / 1024).toStringAsFixed(1)} MB / ${(task.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${(task.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: BacolorsAccentPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else if (task.status == DownloadTaskStatus.installing) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                color: BacolorsPrimary,
                backgroundColor: isLight
                    ? const Color(0xFFD0D8EE)
                    : const Color(0xFF3A4D7A),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '正在安装...',
              style: TextStyle(color: subtitleColor, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateOverallProgress() {
    if (_activeTasks.isEmpty) return 0.0;
    var total = 0.0;
    for (final task in _activeTasks) {
      total += task.progress;
    }
    return total / _activeTasks.length;
  }

  IconData _getTypeIcon(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return Icons.extension;
      case ResourceType.resourcePack:
        return Icons.palette;
      case ResourceType.shader:
        return Icons.lightbulb;
      case ResourceType.modpack:
        return Icons.inventory_2;
      case ResourceType.dataPack:
        return Icons.folder;
    }
  }

  Color _getTypeColor(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return BacolorsAccentPink;
      case ResourceType.resourcePack:
        return BacolorsSuccess;
      case ResourceType.shader:
        return BacolorsWarning;
      case ResourceType.modpack:
        return BacolorsPrimary;
      case ResourceType.dataPack:
        return const Color(0xFF8B7DD9);
    }
  }
}
