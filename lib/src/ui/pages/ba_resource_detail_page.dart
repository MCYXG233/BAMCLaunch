import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../components/ba_notification.dart';
import '../components/ba_instance_select_dialog.dart';
import '../../resource_center/models.dart';
import '../../resource_center/favorite_manager.dart';
import '../../resource_center/modrinth_client.dart';
import '../../resource_center/download_manager.dart';

/// 资源详情页
///
/// 显示资源完整信息，包含：
/// - 基础信息（名称、作者、描述）
/// - 版本兼容性（游戏版本、Mod加载器）
/// - 下载统计、发布时间
/// - 收藏、下载/安装功能
class ResourceDetailPage extends StatefulWidget {
  final Resource resource;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const ResourceDetailPage({
    super.key,
    required this.resource,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> with WindowListener {
  bool _isMaximized = false;
  bool _isFavorite = false;
  bool _isLoadingVersions = false;
  bool _isDownloading = false;
  List<ResourceVersion> _versions = [];

  final ModrinthClient _modrinth = ModrinthClient();
  final DownloadManager _downloadManager = DownloadManager.instance;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _isFavorite = widget.isFavorite;
    _loadVersions();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoadingVersions = true);

    try {
      final versions = await _modrinth.getVersions(widget.resource.id);
      if (mounted) {
        setState(() {
          _versions = versions;
          _isLoadingVersions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVersions = false);
        NotificationManager().showError('加载版本失败', message: e.toString());
      }
    }
  }

  Future<void> _onDownload() async {
    if (_versions.isEmpty) {
      NotificationManager().showWarning('没有可用版本');
      return;
    }

    final result = await InstanceSelectDialog.show(
      context,
      resource: widget.resource,
      versions: _versions,
      instances: ['默认实例', '生存 1.20.4', '创造测试'],
    );

    if (result != null) {
      setState(() => _isDownloading = true);

      try {
        await _downloadManager.download(
          resource: widget.resource,
          version: result.version,
          targetInstance: result.instance,
          targetGameVersion: result.gameVersion,
          autoInstall: result.autoInstall,
          resolveDependencies: result.resolveDependencies,
        );

        if (mounted) {
          NotificationManager().showSuccess(
            '下载任务已添加',
            message: '${widget.resource.name} 正在下载',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('创建下载任务失败', message: e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isDownloading = false);
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!FavoriteManager.instance.isInitialized) {
      await FavoriteManager.instance.initialize();
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      await FavoriteManager.instance.addFavorite(
        widget.resource.id,
        resourceName: widget.resource.name,
      );
    } else {
      await FavoriteManager.instance.removeFavorite(widget.resource.id);
    }

    widget.onFavoriteToggle();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Column(
        children: [
          // 顶部栏
          _buildHeader(context, isLight),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  _buildInfoCard(context, isLight),
                  const SizedBox(height: 20),

                  // 描述
                  if (widget.resource.description.isNotEmpty)
                    _buildDescriptionCard(context, isLight),
                  const SizedBox(height: 20),

                  // 版本列表
                  _buildVersionsCard(context, isLight),
                  const SizedBox(height: 20),

                  // 版本兼容性
                  _buildCompatibilityCard(context, isLight),
                  const SizedBox(height: 20),

                  // 统计数据
                  _buildStatsCard(context, isLight),
                ],
              ),
            ),
          ),

          // 底部操作栏
          _buildBottomBar(context, isLight),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLight) {
    return BAGlassContainer(
      blur: 20,
      opacity: 0.85,
      borderRadius: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 返回按钮
            BAIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
              size: 36,
              iconSize: 18,
            ),
            const SizedBox(width: 12),

            // 标题
            Expanded(
              child: Text(
                widget.resource.name,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1A2744) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // 收藏按钮
            BAIconButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              onTap: _toggleFavorite,
              size: 36,
              iconSize: 18,
              iconColor: _isFavorite ? Colors.red : null,
            ),
            const SizedBox(width: 8),

            // 窗口控制
            Row(
              children: [
                BAIconButton(
                  icon: Icons.remove,
                  onTap: () => windowManager.minimize(),
                  size: 32,
                  iconSize: 16,
                ),
                const SizedBox(width: 6),
                BAIconButton(
                  icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                  onTap: () async {
                    if (_isMaximized) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                  size: 32,
                  iconSize: 16,
                ),
                const SizedBox(width: 6),
                BAWindowButton(
                  icon: Icons.close,
                  onTap: () => windowManager.close(),
                  isClose: true,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isLight) {
    return BASurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 资源图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getTypeColor(widget.resource.type),
                  _getTypeColor(widget.resource.type).withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getTypeColor(widget.resource.type).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getTypeIcon(widget.resource.type),
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),

          // 资源信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(widget.resource.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeName(widget.resource.type),
                    style: TextStyle(
                      color: _getTypeColor(widget.resource.type),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 名称
                Text(
                  widget.resource.name,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 作者
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16,
                        color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8)),
                    const SizedBox(width: 6),
                    Text(
                      widget.resource.authors.isNotEmpty
                          ? widget.resource.authors.map((a) => a.name).join(', ')
                          : '未知作者',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // 支持的游戏版本和加载器
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...widget.resource.supportedGameVersions.take(4).map(
                      (v) => _buildChip(v, BAColors.primaryOf(context)),
                    ),
                    ...widget.resource.supportedLoaders.take(3).map(
                      (l) => _buildChip(l, BAColors.accentPinkOf(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, bool isLight) {
    return BASurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              Text(
                '简介',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1A2744) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.resource.description,
            style: TextStyle(
              color: isLight ? const Color(0xFF1A2744) : const Color(0xFFE0E8F5),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsCard(BuildContext context, bool isLight) {
    return BASurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              Text(
                '可用版本 (${_versions.length})',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1A2744) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingVersions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_versions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '暂无版本信息',
                style: TextStyle(
                  color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                  fontSize: 13,
                ),
              ),
            )
          else
            ..._versions.take(5).map((version) => _buildVersionTile(version, isLight)),
        ],
      ),
    );
  }

  Widget _buildVersionTile(ResourceVersion version, bool isLight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF5F8FF) : const Color(0xFF2A3A5A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${version.versionNumber}',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...version.gameVersions.take(2).map(
                      (v) => Text(
                        v,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    ...version.loaders.take(2).map(
                      (l) => Text(
                        l,
                        style: TextStyle(
                          color: BAColors.accentPinkOf(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: BAColors.primaryOf(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              version.releaseType,
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard(BuildContext context, bool isLight) {
    return BASurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt, size: 18, color: BAColors.accentPinkOf(context)),
              const SizedBox(width: 8),
              Text(
                '兼容性',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1A2744) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBlock(
                  context,
                  '游戏版本',
                  widget.resource.supportedGameVersions.take(3).join(', '),
                  BAColors.primaryOf(context),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFF3A4D7A)),
              Expanded(
                child: _buildStatBlock(
                  context,
                  'Mod加载器',
                  widget.resource.supportedLoaders.join(', '),
                  BAColors.accentPinkOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isLight) {
    return BASurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatBlock(
              context,
              '总下载量',
              _formatNumber(widget.resource.downloads),
              BAColors.primaryOf(context),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
          ),
          Expanded(
            child: _buildStatBlock(
              context,
              '收藏数',
              _formatNumber(widget.resource.likes),
              Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
          ),
          Expanded(
            child: _buildStatBlock(
              context,
              '发布日期',
              widget.resource.publishedDate != null
                  ? '${widget.resource.publishedDate!.year}/${widget.resource.publishedDate!.month.toString().padLeft(2, '0')}'
                  : '未知',
              BAColors.successOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(BuildContext context, String label, String value, Color color) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLight) {
    return BAGlassContainer(
      blur: 20,
      opacity: 0.9,
      borderRadius: 0,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // 收藏按钮
            OutlinedButton.icon(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              label: Text(_isFavorite ? '已收藏' : '收藏'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isLight ? const Color(0xFF1A2744) : Colors.white,
                side: BorderSide(
                  color: _isFavorite ? Colors.red : (isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 下载按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _onDownload,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download, size: 20),
                label: Text(_isDownloading ? '下载中...' : '下载并安装'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        return BAColors.accentPinkOf(context);
      case ResourceType.resourcePack:
        return BAColors.successOf(context);
      case ResourceType.shader:
        return BAColors.warningOf(context);
      case ResourceType.modpack:
        return BAColors.primaryOf(context);
      case ResourceType.dataPack:
        return const Color(0xFF8B7DD9);
    }
  }

  String _getTypeName(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return '模组 (Mod)';
      case ResourceType.resourcePack:
        return '资源包';
      case ResourceType.shader:
        return '光影包';
      case ResourceType.modpack:
        return '整合包';
      case ResourceType.dataPack:
        return '数据包';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
