import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../mod/conflict_detector.dart';
import '../../../../mod/dependency_resolver.dart';

/// 冲突卡片 - 展示单个冲突信息
class ConflictCard extends StatelessWidget {
  final ModConflict conflict;

  const ConflictCard({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    final color = conflict.isError ? BAColors.dangerOf(context) : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conflict.isError ? Icons.error : Icons.warning,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                conflict.title,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflict.description,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '建议: ${conflict.suggestion}',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 缺失依赖卡片
class MissingDependencyCard extends StatelessWidget {
  final MissingDependency dep;

  const MissingDependencyCard({super.key, required this.dep});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_off, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${dep.dependentModName} 需要 ${dep.missingModId}',
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 冲突检测结果 Dialog
class ConflictsDialog extends StatelessWidget {
  final List<ModConflict> conflicts;
  final List<MissingDependency> missingDependencies;
  final void Function(ConflictSolution) onResolve;

  const ConflictsDialog({
    super.key,
    required this.conflicts,
    required this.missingDependencies,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BAColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            _buildHeader(context),
            Divider(height: 1, color: BAColors.borderOf(context)),
            Expanded(child: _buildContent(context)),
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
          Icon(Icons.warning, color: BAColors.dangerOf(context), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '冲突检测结果',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${conflicts.length} 个冲突，${missingDependencies.length} 个缺失依赖',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conflicts.isNotEmpty) ...[
            Text(
              '冲突',
              style: TextStyle(
                color: BAColors.dangerOf(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...conflicts.map((c) => ConflictCard(conflict: c)),
            const SizedBox(height: 20),
          ],
          if (missingDependencies.isNotEmpty) ...[
            Text(
              '缺失依赖',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...missingDependencies.map((d) => MissingDependencyCard(dep: d)),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
