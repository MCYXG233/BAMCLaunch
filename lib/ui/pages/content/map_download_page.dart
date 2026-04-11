import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import './map_detail_page.dart';

class MapDownloadPage extends StatefulWidget {
  const MapDownloadPage({super.key});

  @override
  State<MapDownloadPage> createState() => _MapDownloadPageState();
}

class _MapDownloadPageState extends State<MapDownloadPage> {
  String _searchQuery = '';
  String? _selectedGameVersion;
  String? _selectedMapType;
  String? _selectedSort;
  bool _isLoading = false;
  List<ContentItem> _maps = [];

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() => _isLoading = true);
    try {
      if (_searchQuery.isNotEmpty) {
        final result = await contentManager.searchContent(
          SearchQuery(
            query: _searchQuery,
            type: ContentType.map,
            gameVersion: _selectedGameVersion,
          ),
        );
        setState(() => _maps = result.items);
      } else {
        // 加载热门地图
        final popular = await contentManager.getPopularContent(ContentType.map);
        setState(() => _maps = popular);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载地图失败: $e')),
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
            hintText: '搜索地图...',
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            suffixIcon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '搜索',
          onPressed: _loadMaps,
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
                  labelText: '地图类型',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedMapType,
                hint: const Text('选择类型'),
                items: const [
                  DropdownMenuItem(value: 'survival', child: Text('生存')),
                  DropdownMenuItem(value: 'creative', child: Text('创造')),
                  DropdownMenuItem(value: 'puzzle', child: Text('解谜')),
                  DropdownMenuItem(value: 'parkour', child: Text('跑酷')),
                  DropdownMenuItem(value: 'rpg', child: Text('RPG')),
                  DropdownMenuItem(value: 'landscape', child: Text('景观')),
                ],
                onChanged: (value) {
                  setState(() => _selectedMapType = value);
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
                  _selectedMapType = null;
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

  Widget _buildMapGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_maps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关地图' : '暂无地图数据',
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
      itemCount: _maps.length,
      itemBuilder: (context, index) {
        final map = _maps[index];
        return _buildMapCard(map);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildMapCard(ContentItem map) {
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
            child: map.iconUrl != null
                ? Image.network(
                    map.iconUrl!,
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
                  map.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '作者: ${map.author}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '地图类型: ${_getMapTypeLabel(_selectedMapType)}',
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
                        onPressed: () => _handleInstallMap(map),
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
                            builder: (context) => MapDetailPage(map: map),
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
        Icons.map,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  String _getMapTypeLabel(String? type) {
    switch (type) {
      case 'survival':
        return '生存';
      case 'creative':
        return '创造';
      case 'puzzle':
        return '解谜';
      case 'parkour':
        return '跑酷';
      case 'rpg':
        return 'RPG';
      case 'landscape':
        return '景观';
      default:
        return '未知';
    }
  }

  void _handleInstallMap(ContentItem map) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装地图'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装地图 ${map.name} 吗？'),
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
              await _installMap(map);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installMap(ContentItem map) async {
    setState(() => _isLoading = true);
    try {
      final result = await contentManager.installContent(
        item: map,
        versionId: 'latest',
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地图 ${map.name} 安装成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安装失败: ${result.errorMessage}')),
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

  void _showMapDetails(ContentItem map) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('地图详情: ${map.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${map.author}'),
            Text('版本: ${map.version}'),
            Text('下载量: ${map.downloadCount}'),
            const SizedBox(height: 16),
            Text('描述: ${map.description}'),
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
            '地图存档下载',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '提供游戏地图/存档的下载、一键安装能力',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 搜索栏
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 筛选器
          _buildFilters(),
          const SizedBox(height: 20),

          // 地图网格
          _buildMapGrid(),
        ],
      ),
    );
  }
}
