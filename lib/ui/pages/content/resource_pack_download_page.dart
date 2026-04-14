import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import './resource_pack_detail_page.dart';

class ResourcePackDownloadPage extends StatefulWidget {
  const ResourcePackDownloadPage({super.key});

  @override
  State<ResourcePackDownloadPage> createState() =>
      _ResourcePackDownloadPageState();
}

class _ResourcePackDownloadPageState extends State<ResourcePackDownloadPage> {
  String _searchQuery = '';
  String? _selectedGameVersion;
  String? _selectedResolution;
  String? _selectedStyle;
  String? _selectedSort;
  bool _isLoading = false;
  List<ContentItem> _resourcePacks = [];

  @override
  void initState() {
    super.initState();
    _loadResourcePacks();
  }

  Future<void> _loadResourcePacks() async {
    setState(() => _isLoading = true);
    try {
      if (_searchQuery.isNotEmpty) {
        final result = await contentManager.searchContent(
          query: _searchQuery,
          type: ContentType.resourcePack,
          gameVersion: _selectedGameVersion,
        );
        setState(() => _resourcePacks = result);
      } else {
        // 加载热门资源包
        final popular = await contentManager.getPopularContent(
          type: ContentType.resourcePack,
        );
        setState(() => _resourcePacks = popular);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载资源包失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: BamcInput(
            hintText: '搜索资源包...',
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            suffixIcon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '搜索',
          onPressed: _loadResourcePacks,
          type: BamcButtonType.primary,
          size: BamcButtonSize.medium,
          icon: Icons.search,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '游戏版本',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedGameVersion,
                hint: const Text('选择版本'),
                items: const [
                  DropdownMenuItem(value: '1.20.1', child: Text('1.20.1')),
                  DropdownMenuItem(value: '1.19.4', child: Text('1.19.4')),
                  DropdownMenuItem(value: '1.18.2', child: Text('1.18.2')),
                  DropdownMenuItem(value: '1.17.1', child: Text('1.17.1')),
                  DropdownMenuItem(value: '1.16.5', child: Text('1.16.5')),
                ],
                onChanged: (value) {
                  setState(() => _selectedGameVersion = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '分辨率',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedResolution,
                hint: const Text('选择分辨率'),
                items: const [
                  DropdownMenuItem(value: '16x', child: Text('16x')),
                  DropdownMenuItem(value: '32x', child: Text('32x')),
                  DropdownMenuItem(value: '64x', child: Text('64x')),
                  DropdownMenuItem(value: '128x', child: Text('128x')),
                  DropdownMenuItem(value: '256x', child: Text('256x+')),
                ],
                onChanged: (value) {
                  setState(() => _selectedResolution = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '风格',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedStyle,
                hint: const Text('选择风格'),
                items: const [
                  DropdownMenuItem(value: 'realistic', child: Text('写实')),
                  DropdownMenuItem(value: 'cartoon', child: Text('卡通')),
                  DropdownMenuItem(value: 'pbr', child: Text('PBR')),
                  DropdownMenuItem(value: 'minimalist', child: Text('极简')),
                  DropdownMenuItem(value: 'nostalgic', child: Text('怀旧')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStyle = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '排序',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedSort,
                hint: const Text('选择排序'),
                items: const [
                  DropdownMenuItem(value: 'popular', child: Text('热度')),
                  DropdownMenuItem(value: 'downloads', child: Text('下载量')),
                  DropdownMenuItem(value: 'updated', child: Text('更新时间')),
                  DropdownMenuItem(value: 'rating', child: Text('评分')),
                ],
                onChanged: (value) {
                  setState(() => _selectedSort = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            BamcButton(
              text: '重置',
              onPressed: () {
                setState(() {
                  _selectedGameVersion = null;
                  _selectedResolution = null;
                  _selectedStyle = null;
                  _selectedSort = null;
                });
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.medium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourcePackGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_resourcePacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关资源包' : '暂无资源包数据',
              style: const TextStyle(color: BamcColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _resourcePacks.length,
      itemBuilder: (context, index) {
        final resourcePack = _resourcePacks[index];
        return _buildResourcePackCard(resourcePack);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildResourcePackCard(ContentItem resourcePack) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预览图
          Container(
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color: BamcColors.surface,
            ),
            child: resourcePack.iconUrl != null
                ? Image.network(
                    resourcePack.iconUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultPreview();
                    },
                  )
                : _buildDefaultPreview(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resourcePack.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '作者: ${resourcePack.author}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '分辨率: ${_selectedResolution ?? '未知'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BamcButton(
                        text: '安装',
                        onPressed: () =>
                            _handleInstallResourcePack(resourcePack),
                        type: BamcButtonType.primary,
                        size: BamcButtonSize.small,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BamcButton(
                      text: '详情',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResourcePackDetailPage(
                                resourcePack: resourcePack),
                          ),
                        );
                      },
                      type: BamcButtonType.outline,
                      size: BamcButtonSize.small,
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

  Widget _buildDefaultPreview() {
    return Container(
      color: BamcColors.surface,
      child: const Icon(
        Icons.image,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  void _handleInstallResourcePack(ContentItem resourcePack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装资源包'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装资源包 ${resourcePack.name} 吗？'),
            const SizedBox(height: 16),
            // 这里可以添加安装路径选择等选项
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _installResourcePack(resourcePack);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installResourcePack(ContentItem resourcePack) async {
    setState(() => _isLoading = true);
    try {
      final platformAdapter = PlatformAdapterFactory.getInstance();
      final destination = '${platformAdapter.gameDirectory}/resourcepacks';
      final result = await contentManager.installContent(
        resourcePack.id,
        resourcePack.version,
        destination,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('资源包 ${resourcePack.name} 安装成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('安装失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('安装失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResourcePackDetails(ContentItem resourcePack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('资源包详情: ${resourcePack.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${resourcePack.author}'),
            Text('版本: ${resourcePack.version}'),
            Text('下载量: ${resourcePack.downloadCount}'),
            const SizedBox(height: 16),
            Text('描述: ${resourcePack.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '资源包下载',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '提供游戏材质/资源包的下载、一键安装能力',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 搜索栏
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 筛选器
          _buildFilters(),
          const SizedBox(height: 20),

          // 资源包网格
          _buildResourcePackGrid(),
        ],
      ),
    );
  }
}
