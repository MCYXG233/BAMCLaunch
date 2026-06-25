import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_progress.dart';

class DownloadTaskInfo {
  final String id;
  final String name;
  double progress;
  String status;
  String? speed;
  String? errorMessage;

  DownloadTaskInfo({
    required this.id,
    required this.name,
    this.progress = 0.0,
    this.status = 'downloading',
    this.speed,
    this.errorMessage,
  });
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();

  factory DownloadManager() => _instance;

  DownloadManager._internal();

  final List<DownloadTaskInfo> _tasks = [];

  VoidCallback? onUpdate;

  List<DownloadTaskInfo> get tasks => List.unmodifiable(_tasks);

  int get activeCount =>
      _tasks.where((t) => t.status == 'downloading').length;

  bool get hasActiveTasks => activeCount > 0;

  void addTask(DownloadTaskInfo task) {
    _tasks.add(task);
    onUpdate?.call();
    notifyListeners();
  }

  void updateTask(
    String id, {
    double? progress,
    String? status,
    String? speed,
    String? errorMessage,
  }) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _tasks[index];
    if (progress != null) task.progress = progress;
    if (status != null) task.status = status;
    if (speed != null) task.speed = speed;
    if (errorMessage != null) task.errorMessage = errorMessage;

    onUpdate?.call();
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    onUpdate?.call();
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere(
      (t) => t.status == 'completed' || t.status == 'failed' || t.status == 'cancelled',
    );
    onUpdate?.call();
    notifyListeners();
  }

  void cancelAll() {
    for (final task in _tasks) {
      if (task.status == 'downloading') {
        task.status = 'cancelled';
      }
    }
    onUpdate?.call();
    notifyListeners();
  }
}

class BADownloadIndicator extends StatefulWidget {
  final bool hideWhenEmpty;

  const BADownloadIndicator({
    super.key,
    this.hideWhenEmpty = true,
  });

  @override
  State<BADownloadIndicator> createState() => _BADownloadIndicatorState();
}

class _BADownloadIndicatorState extends State<BADownloadIndicator>
    with SingleTickerProviderStateMixin {
  final DownloadManager _manager = DownloadManager();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _manager.addListener(_onManagerUpdate);
    _updatePulse();
  }

  void _onManagerUpdate() {
    _updatePulse();
  }

  void _updatePulse() {
    if (_manager.hasActiveTasks) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        if (widget.hideWhenEmpty && !_manager.hasActiveTasks && _manager.tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _showDownloadPanel(context),
          child: _buildIndicator(context),
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final activeCount = _manager.activeCount;

    if (activeCount > 0) {
      return _buildActiveIndicator(context, activeCount);
    }

    return _buildIdleIndicator(context);
  }

  Widget _buildActiveIndicator(BuildContext context, int count) {
    double totalProgress = 0;
    int downloadingCount = 0;
    for (final task in _manager.tasks) {
      if (task.status == 'downloading') {
        totalProgress += task.progress;
        downloadingCount++;
      }
    }
    final avgProgress = downloadingCount > 0 ? totalProgress / downloadingCount : 0.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context),
          borderRadius: BATheme.borderRadiusSmall,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: avgProgress,
                strokeWidth: 3,
                backgroundColor: BAColors.borderOf(context),
                valueColor: AlwaysStoppedAnimation<Color>(BAColors.primaryOf(context)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download,
                  color: BAColors.primaryOf(context),
                  size: 14,
                ),
                Text(
                  '$count',
                  style: BATypography.labelSmall.copyWith(
                    color: BAColors.primaryOf(context),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleIndicator(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BATheme.borderRadiusSmall,
      ),
      child: Icon(
        Icons.download_done,
        color: BAColors.textSecondaryOf(context),
        size: 20,
      ),
    );
  }

  void _showDownloadPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _DownloadListPanel(),
    );
  }
}

class _DownloadListPanel extends StatelessWidget {
  const _DownloadListPanel();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadiusLarge,
          border: Border.all(color: BAColors.borderOf(context), width: 1),
          boxShadow: BATheme.darkShadowsLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Divider(height: 1, color: BAColors.borderOf(context)),
            Flexible(child: _buildTaskList(context)),
            Divider(height: 1, color: BAColors.borderOf(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.downloading, color: BAColors.primaryOf(context), size: 20),
          const SizedBox(width: 10),
          Text(
            '下载管理',
            style: BATypography.titleSmall.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: DownloadManager(),
            builder: (context, _) {
              final activeCount = DownloadManager().activeCount;
              if (activeCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount 个任务进行中',
                    style: BATypography.labelSmall.copyWith(
                      color: BAColors.primaryOf(context),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close,
                color: BAColors.textSecondaryOf(context),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return ListenableBuilder(
      listenable: DownloadManager(),
      builder: (context, _) {
        final tasks = DownloadManager().tasks;

        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_download_outlined,
                    color: BAColors.textDisabledOf(context),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无下载任务',
                    style: BATypography.bodyMedium.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shrinkWrap: true,
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _DownloadTaskItem(task: tasks[index]);
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListenableBuilder(
        listenable: DownloadManager(),
        builder: (context, _) {
          final manager = DownloadManager();
          return Row(
            children: [
              if (manager.hasActiveTasks)
                _buildFooterButton(
                  context,
                  icon: Icons.cancel_outlined,
                  label: '取消全部',
                  color: BAColors.dangerOf(context),
                  onTap: () {
                    manager.cancelAll();
                  },
                ),
              if (manager.hasActiveTasks) const SizedBox(width: 8),
              _buildFooterButton(
                context,
                icon: Icons.cleaning_services_outlined,
                label: '清除已完成',
                color: BAColors.textSecondaryOf(context),
                onTap: () {
                  manager.clearCompleted();
                },
              ),
              const Spacer(),
              Text(
                '共 ${manager.tasks.length} 个任务',
                style: BATypography.bodySmall.copyWith(
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: BATypography.label.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadTaskItem extends StatelessWidget {
  final DownloadTaskInfo task;

  const _DownloadTaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(
          color: _getStatusBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(context),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: BATypography.bodyMedium.copyWith(
                        color: BAColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _buildSubtitle(context),
                  ],
                ),
              ),
              if (task.status == 'downloading')
                GestureDetector(
                  onTap: () {
                    DownloadManager().updateTask(task.id, status: 'cancelled');
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: BAColors.dangerOf(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: BAColors.dangerOf(context),
                      size: 14,
                    ),
                  ),
                ),
              if (task.status == 'completed' || task.status == 'failed' || task.status == 'cancelled')
                GestureDetector(
                  onTap: () {
                    DownloadManager().removeTask(task.id);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: BAColors.textSecondaryOf(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: BAColors.textSecondaryOf(context),
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          if (task.status == 'downloading') ...[
            const SizedBox(height: 10),
            BAProgressBar(
              value: task.progress,
              height: 8,
              showPercentage: false,
              color: BAColors.primaryOf(context),
              backgroundColor: BAColors.surfaceTertiaryOf(context),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: BATypography.labelSmall.copyWith(
                    color: BAColors.primaryOf(context),
                  ),
                ),
                if (task.speed != null)
                  Text(
                    task.speed!,
                    style: BATypography.labelSmall.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (task.status) {
      case 'downloading':
        icon = Icons.downloading;
        color = BAColors.primaryOf(context);
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = BAColors.successOf(context);
        break;
      case 'failed':
        icon = Icons.error;
        color = BAColors.dangerOf(context);
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = BAColors.textSecondaryOf(context);
        break;
      default:
        icon = Icons.downloading;
        color = BAColors.textSecondaryOf(context);
    }

    return Icon(icon, color: color, size: 18);
  }

  Widget _buildSubtitle(BuildContext context) {
    String text;
    Color color;

    switch (task.status) {
      case 'downloading':
        text = task.speed != null ? '下载中 - ${task.speed}' : '下载中...';
        color = BAColors.textSecondaryOf(context);
        break;
      case 'completed':
        text = '下载完成';
        color = BAColors.successOf(context);
        break;
      case 'failed':
        text = task.errorMessage ?? '下载失败';
        color = BAColors.dangerOf(context);
        break;
      case 'cancelled':
        text = '已取消';
        color = BAColors.textSecondaryOf(context);
        break;
      default:
        text = task.status;
        color = BAColors.textSecondaryOf(context);
    }

    return Text(
      text,
      style: BATypography.caption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _getStatusBorderColor(BuildContext context) {
    switch (task.status) {
      case 'downloading':
        return BAColors.primaryOf(context).withOpacity(0.3);
      case 'completed':
        return BAColors.successOf(context).withOpacity(0.3);
      case 'failed':
        return BAColors.dangerOf(context).withOpacity(0.3);
      default:
        return BAColors.borderOf(context);
    }
  }
}
