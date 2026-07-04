import 'package:flutter/material.dart';
import '../core/utils.dart';
import 'models.dart';

/// 版本卡片组件
class VersionCard extends StatelessWidget {
  /// 游戏版本
  final GameVersion version;

  /// 是否已安装
  final bool isInstalled;

  /// 点击回调
  final VoidCallback? onTap;

  /// 安装回调
  final VoidCallback? onInstall;

  /// 卸载回调
  final VoidCallback? onUninstall;

  /// 创建版本卡片
  const VersionCard({
    super.key,
    required this.version,
    this.isInstalled = false,
    this.onTap,
    this.onInstall,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 版本图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getVersionColor(version.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVersionIcon(version.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 版本信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.id,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTypeChip(version.type),
                        const SizedBox(width: 8),
                        if (isInstalled) _buildInstalledChip(),
                      ],
                    ),
                  ],
                ),
              ),
              // 操作按钮
              Row(
                children: [
                  if (isInstalled)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onUninstall,
                      tooltip: '卸载',
                    ),
                  if (!isInstalled)
                    FilledButton.icon(
                      onPressed: onInstall,
                      icon: const Icon(Icons.download),
                      label: const Text('安装'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取版本类型颜色
  Color _getVersionColor(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Colors.green;
      case VersionType.snapshot:
        return Colors.orange;
      case VersionType.oldBeta:
        return Colors.purple;
      case VersionType.oldAlpha:
        return Colors.red;
    }
  }

  /// 获取版本类型图标
  IconData _getVersionIcon(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Icons.check_circle;
      case VersionType.snapshot:
        return Icons.science;
      case VersionType.oldBeta:
        return Icons.history;
      case VersionType.oldAlpha:
        return Icons.history_edu;
    }
  }

  /// 构建版本类型标签
  Widget _buildTypeChip(VersionType type) {
    String label;
    Color color;

    switch (type) {
      case VersionType.release:
        label = '正式版';
        color = Colors.green;
        break;
      case VersionType.snapshot:
        label = '快照版';
        color = Colors.orange;
        break;
      case VersionType.oldBeta:
        label = 'Beta';
        color = Colors.purple;
        break;
      case VersionType.oldAlpha:
        label = 'Alpha';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建已安装标签
  Widget _buildInstalledChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Text(
        '已安装',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 版本列表组件
class VersionList extends StatelessWidget {
  /// 版本列表
  final List<GameVersion> versions;

  /// 已安装版本列表
  final List<String> installedVersions;

  /// 搜索查询
  final String searchQuery;

  /// 版本类型过滤
  final VersionType? filterType;

  /// 点击回调
  final Function(GameVersion)? onVersionTap;

  /// 安装回调
  final Function(GameVersion)? onInstall;

  /// 卸载回调
  final Function(GameVersion)? onUninstall;

  /// 是否正在加载
  final bool isLoading;

  /// 创建版本列表
  const VersionList({
    super.key,
    required this.versions,
    this.installedVersions = const [],
    this.searchQuery = '',
    this.filterType,
    this.onVersionTap,
    this.onInstall,
    this.onUninstall,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载版本列表...'),
          ],
        ),
      );
    }

    final filteredVersions = _filterVersions();

    if (filteredVersions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有找到匹配的版本'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredVersions.length,
      itemBuilder: (context, index) {
        final version = filteredVersions[index];
        final isInstalled = installedVersions.contains(version.id);

        return VersionCard(
          version: version,
          isInstalled: isInstalled,
          onTap: () => onVersionTap?.call(version),
          onInstall: () => onInstall?.call(version),
          onUninstall: () => onUninstall?.call(version),
        );
      },
    );
  }

  /// 过滤版本列表
  List<GameVersion> _filterVersions() {
    var filtered = versions;

    // 应用搜索过滤
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((version) {
        return version.id.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // 应用类型过滤
    if (filterType != null) {
      filtered = filtered.where((version) {
        return version.type == filterType;
      }).toList();
    }

    return filtered;
  }
}

/// 安装进度对话框
class InstallProgressDialog extends StatelessWidget {
  /// 版本ID
  final String versionId;

  /// 进度（0.0 - 1.0）
  final double progress;

  /// 当前阶段
  final String stage;

  /// 当前文件
  final String? currentFile;

  /// 已下载字节数
  final int downloadedBytes;

  /// 总字节数
  final int totalBytes;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 创建安装进度对话框
  const InstallProgressDialog({
    super.key,
    required this.versionId,
    required this.progress,
    required this.stage,
    this.currentFile,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.downloading, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '正在安装 $versionId',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),
            const SizedBox(height: 8),
            // 进度百分比
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalBytes > 0)
                  Text(
                    '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            // 当前文件
            if (currentFile != null) ...[
              const SizedBox(height: 8),
              Text(
                currentFile!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            // 取消按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
