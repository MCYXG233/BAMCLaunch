import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class VersionDetailPage extends StatefulWidget {
  final Version version;
  final IVersionManager versionManager;

  const VersionDetailPage({
    super.key,
    required this.version,
    required this.versionManager,
  });

  @override
  State<VersionDetailPage> createState() => _VersionDetailPageState();
}

class _VersionDetailPageState extends State<VersionDetailPage> {
  bool _isCheckingIntegrity = false;
  bool _isRepairing = false;

  Future<void> _checkIntegrity() async {
    setState(() => _isCheckingIntegrity = true);
    try {
      final isIntegrity =
          await widget.versionManager.checkVersionIntegrity(widget.version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIntegrity ? '版本完整性正常' : '版本文件损坏'),
            backgroundColor:
                isIntegrity ? BamcColors.success : BamcColors.error,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to check integrity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingIntegrity = false);
    }
  }

  Future<void> _repairVersion() async {
    setState(() => _isRepairing = true);
    try {
      await widget.versionManager.repairVersion(widget.version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('版本修复成功'),
            backgroundColor: BamcColors.success,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to repair version: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修复失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isRepairing = false);
    }
  }

  Future<void> _uninstallVersion() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BamcColors.surface,
        title: const Text('确认卸载'),
        content: Text('确定要卸载版本 ${widget.version.id} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('卸载'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.versionManager.uninstallVersion(widget.version.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        logger.error('Failed to uninstall version: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('卸载失败: $e'),
              backgroundColor: BamcColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: BamcColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Text(
                '版本详情 - ${widget.version.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 版本信息卡片
          Container(
            decoration: BoxDecoration(
              color: BamcColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BamcColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('版本ID', widget.version.id),
                _buildInfoRow('版本类型', _getVersionTypeText(widget.version.type)),
                _buildInfoRow('发布时间', widget.version.releaseTime.toString()),
                _buildInfoRow('主类', widget.version.mainClass),
                _buildInfoRow(
                    '继承自',
                    widget.version.inheritsFrom.isNotEmpty
                        ? widget.version.inheritsFrom
                        : '无'),
                _buildInfoRow('状态', _getStatusText(widget.version.status)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              BamcButton(
                text: '检查完整性',
                onPressed: _isCheckingIntegrity ? null : _checkIntegrity,
                type: BamcButtonType.outline,
                size: BamcButtonSize.medium,
              ),
              const SizedBox(width: 12),
              BamcButton(
                text: '修复版本',
                onPressed: _isRepairing ? null : _repairVersion,
                type: BamcButtonType.outline,
                size: BamcButtonSize.medium,
              ),
              const SizedBox(width: 12),
              BamcButton(
                text: '卸载版本',
                onPressed: _uninstallVersion,
                type: BamcButtonType.warning,
                size: BamcButtonSize.medium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BamcColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: BamcColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVersionTypeText(VersionType type) {
    switch (type) {
      case VersionType.release:
        return '正式版';
      case VersionType.snapshot:
        return '快照版';
      case VersionType.old_alpha:
        return '远古Alpha';
      case VersionType.old_beta:
        return '远古Beta';
      case VersionType.custom:
        return '自定义版本';
    }
  }

  String _getStatusText(VersionStatus status) {
    switch (status) {
      case VersionStatus.not_installed:
        return '未安装';
      case VersionStatus.installed:
        return '已安装';
      case VersionStatus.installing:
        return '安装中';
      case VersionStatus.corrupted:
        return '损坏';
    }
  }
}
