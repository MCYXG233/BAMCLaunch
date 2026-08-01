import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../download/mirror_manager.dart';
import '../../../../ui/theme/colors.dart';
import '../../../components/ba_buttons.dart';
import '../../../components/ba_dialog.dart';
import '../../../components/ba_notification.dart';

/// 镜像延迟测试对话框
///
/// 调用 [MirrorManager.speedTestAllMirrors] 进行测速，并以列表形式
/// 实时展示每个镜像的测试结果（延迟 / 不可用 / 错误信息）。
///
/// 测试完成后：
/// - 自动按延迟升序排序（不可用的排在最后）
/// - 高亮最快镜像
/// - 提供"设为默认镜像"快捷按钮
class MirrorSpeedTestDialog extends StatefulWidget {
  /// 镜像管理器
  final MirrorManager mirrorManager;

  /// 当前选中的镜像 ID
  final String? selectedMirrorId;

  /// 设为默认镜像回调
  final ValueChanged<MirrorInfo>? onSetDefault;

  const MirrorSpeedTestDialog({
    super.key,
    required this.mirrorManager,
    this.selectedMirrorId,
    this.onSetDefault,
  });

  static Future<void> show({
    required BuildContext context,
    required MirrorManager mirrorManager,
    String? selectedMirrorId,
    ValueChanged<MirrorInfo>? onSetDefault,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => MirrorSpeedTestDialog(
        mirrorManager: mirrorManager,
        selectedMirrorId: selectedMirrorId,
        onSetDefault: onSetDefault,
      ),
    );
  }

  @override
  State<MirrorSpeedTestDialog> createState() => _MirrorSpeedTestDialogState();
}

class _MirrorSpeedTestDialogState extends State<MirrorSpeedTestDialog> {
  List<MirrorInfo> get _mirrors => widget.mirrorManager.allMirrors;

  final Map<String, MirrorSpeedTestResult> _results = {};
  final Set<String> _pending = {};
  bool _testing = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  Future<void> _startTest() async {
    setState(() {
      _testing = true;
      _done = false;
      _results.clear();
      _pending.clear();
      _pending.addAll(_mirrors.map((m) => m.id));
    });

    try {
      // 调用一次性测速，但分批"刷新"结果以呈现进度
      final all = await widget.mirrorManager.speedTestAllMirrors();
      for (final result in all) {
        if (!mounted) break;
        setState(() {
          _results[result.mirror.id] = result;
          _pending.remove(result.mirror.id);
        });
        // 给视觉效果一点延迟，让用户能看到逐个完成
        await Future.delayed(const Duration(milliseconds: 80));
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('测速失败', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
          _done = true;
        });
      }
    }
  }

  List<MirrorInfo> get _sorted {
    final list = List<MirrorInfo>.from(_mirrors);
    list.sort((a, b) {
      final ra = _results[a.id];
      final rb = _results[b.id];
      if (ra == null && rb == null) return 0;
      if (ra == null) return 1;
      if (rb == null) return -1;
      if (!ra.isAvailable && !rb.isAvailable) return 0;
      if (!ra.isAvailable) return 1;
      if (!rb.isAvailable) return -1;
      return ra.latencyMs.compareTo(rb.latencyMs);
    });
    return list;
  }

  MirrorInfo? get _fastest {
    final available = _results.values
        .where((r) => r.isAvailable)
        .toList()
      ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return available.isEmpty ? null : available.first.mirror;
  }

  @override
  Widget build(BuildContext context) {
    final total = _mirrors.length;
    final finished = _results.length;
    final progress = total == 0 ? 0.0 : finished / total;

    return BADialog(
      title: '镜像延迟测试',
      titleIcon: Icons.speed_rounded,
      width: 560,
      onClose: _testing
          ? null
          : () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummary(progress, finished, total),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      actions: [
        if (_done)
          BASecondaryButton(
            text: '重新测试',
            onPressed: _startTest,
          ),
        if (_done) const SizedBox(width: 12),
        BASecondaryButton(
          text: _testing ? '测试中...' : '关闭',
          onPressed: _testing ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSummary(double progress, int finished, int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BAColors.primaryOf(context).withValues(alpha: 0.10),
            BAColors.primaryOf(context).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.primaryOf(context).withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_testing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAColors.primaryOf(context),
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: BAColors.successOf(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: BAColors.successOf(context),
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                _testing
                    ? '正在测试... $finished / $total'
                    : '测试完成，共 $total 个镜像',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_fastest != null && _done)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: BAColors.successOf(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: BAColors.successOf(context).withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '最快：${_fastest!.name}',
                    style: TextStyle(
                      color: BAColors.successOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: BAColors.surfaceVariantOf(context),
              color: BAColors.primaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_mirrors.isEmpty) {
      return Center(
        child: Text(
          '未配置任何镜像',
          style: TextStyle(
            color: BAColors.textDisabledOf(context),
            fontSize: 12,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final mirror = _sorted[i];
        final result = _results[mirror.id];
        final isPending = _pending.contains(mirror.id);
        final isFastest = _fastest?.id == mirror.id && _done;
        final isSelected = mirror.id == widget.selectedMirrorId;
        return _buildMirrorRow(
          mirror,
          result: result,
          isPending: isPending,
          isFastest: isFastest,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildMirrorRow(
    MirrorInfo mirror, {
    required MirrorSpeedTestResult? result,
    required bool isPending,
    required bool isFastest,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFastest
            ? BAColors.successOf(context).withValues(alpha: 0.10)
            : BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFastest
              ? BAColors.successOf(context).withValues(alpha: 0.55)
              : BAColors.borderOf(context),
          width: isFastest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mirror.name,
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      _buildBadge(
                        BAColors.primaryOf(context),
                        '当前',
                      ),
                    if (isFastest) ...[
                      const SizedBox(width: 6),
                      _buildBadge(
                        BAColors.successOf(context),
                        '最快',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mirror.url,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatus(result, isPending),
          if (widget.onSetDefault != null &&
              result != null &&
              result.isAvailable &&
              !isSelected &&
              _done) ...[
            const SizedBox(width: 8),
            BASecondaryButton(
              text: '设为默认',
              onPressed: () {
                widget.onSetDefault!(mirror);
                Navigator.of(context).pop();
              },
              height: 28,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatus(MirrorSpeedTestResult? result, bool isPending) {
    if (isPending) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: BAColors.textSecondaryOf(context),
        ),
      );
    }
    if (result == null) {
      return Text(
        '—',
        style: TextStyle(
          color: BAColors.textDisabledOf(context),
          fontSize: 12,
        ),
      );
    }
    if (!result.isAvailable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: BAColors.dangerOf(context),
          ),
          const SizedBox(width: 4),
          Text(
            '不可用',
            style: TextStyle(
              color: BAColors.dangerOf(context),
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    final latency = result.latencyMs;
    final color = latency < 200
        ? BAColors.successOf(context)
        : latency < 500
        ? BAColors.warningOf(context)
        : BAColors.dangerOf(context);
    return Text(
      '$latency ms',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
