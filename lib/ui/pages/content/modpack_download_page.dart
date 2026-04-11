import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/modpack/models/modpack_models.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import './modpack_detail_page.dart';

class ModpackDownloadPage extends StatefulWidget {
  const ModpackDownloadPage({super.key});

  @override
  State<ModpackDownloadPage> createState() => _ModpackDownloadPageState();
}

class _ModpackDownloadPageState extends State<ModpackDownloadPage> {
  String _searchQuery = '';
  String? _selectedGameVersion;
  String? _selectedLoader;
  String? _selectedCategory;
  String? _selectedSort;
  bool _isLoading = false;
  List<ContentItem> _modpacks = [];
  List<ContentItem> _featuredModpacks = [];

  @override
  void initState() {
    super.initState();
    _loadModpacks();
    _loadFeaturedModpacks();
  }

  Future<void> _loadModpacks() async {
    setState(() => _isLoading = true);
    try {
      if (_searchQuery.isNotEmpty) {
        final result = await contentManager.searchContent(
          SearchQuery(
            query: _searchQuery,
            type: ContentType.modpack,
            gameVersion: _selectedGameVersion,
            loader: _selectedLoader,
          ),
        );
        setState(() => _modpacks = result.items);
      } else {
        // 加载热门整合包
        final popular =
            await contentManager.getPopularContent(ContentType.modpack);
        setState(() => _modpacks = popular);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载整合包失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFeaturedModpacks() async {
    try {
      // 模拟加载热门推荐整合包
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _featuredModpacks = [
          ContentItem(
            id: 'featured-1',
            name: '科技魔法整合包',
            author: 'BAMC Team',
            version: '1.0.0',
            description: '一个融合科技与魔法的整合包',
            downloadCount: 15000,
            iconUrl: 'https://example.com/modpacks/tech-magic.jpg',
            downloadUrl: 'https://example.com/modpacks/tech-magic.zip',
            type: ContentType.modpack,
            source: ContentSource.curseforge,
            status: ContentStatus.notInstalled,
            gameVersions: ['1.20.1'],
            loaders: ['forge'],
            dependencies: [],
            conflicts: [],
          ),
          ContentItem(
            id: 'featured-2',
            name: '冒险生存整合包',
            author: 'Adventure Team',
            version: '2.1.0',
            description: '充满挑战的冒险生存体验',
            downloadCount: 12000,
            iconUrl: 'https://example.com/modpacks/adventure.jpg',
            downloadUrl: 'https://example.com/modpacks/adventure.zip',
            type: ContentType.modpack,
            source: ContentSource.modrinth,
            status: ContentStatus.notInstalled,
            gameVersions: ['1.19.4'],
            loaders: ['fabric'],
            dependencies: [],
            conflicts: [],
          ),
        ];
      });
    } catch (e) {
      print('加载热门整合包失败: $e');
    }
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: BamcInput(
            hintText: '搜索整合包...',
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            suffixIcon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '搜索',
          onPressed: _loadModpacks,
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
                  labelText: '加载器类型',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedLoader,
                hint: const Text('选择加载器'),
                items: const [
                  DropdownMenuItem(value: 'forge', child: Text('Forge')),
                  DropdownMenuItem(value: 'fabric', child: Text('Fabric')),
                  DropdownMenuItem(value: 'quilt', child: Text('Quilt')),
                  DropdownMenuItem(value: 'neoforge', child: Text('NeoForge')),
                ],
                onChanged: (value) {
                  setState(() => _selectedLoader = value);
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
                  labelText: '整合包分类',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedCategory,
                hint: const Text('选择分类'),
                items: const [
                  DropdownMenuItem(value: 'technology', child: Text('科技')),
                  DropdownMenuItem(value: 'magic', child: Text('魔法')),
                  DropdownMenuItem(value: 'lightweight', child: Text('轻量')),
                  DropdownMenuItem(value: 'hardcore', child: Text('硬核')),
                  DropdownMenuItem(value: 'rpg', child: Text('RPG')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
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
                  _selectedLoader = null;
                  _selectedCategory = null;
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

  Widget _buildModpackGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_modpacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.widgets_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关整合包' : '暂无整合包数据',
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
      itemCount: _modpacks.length,
      itemBuilder: (context, index) {
        final modpack = _modpacks[index];
        return _buildModpackCard(modpack);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildModpackCard(ContentItem modpack) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图
          Container(
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color: BamcColors.surface,
            ),
            child: modpack.iconUrl != null
                ? Image.network(
                    modpack.iconUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCover();
                    },
                  )
                : _buildDefaultCover(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modpack.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '作者: ${modpack.author}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本: ${modpack.version}',
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
                        onPressed: () => _handleInstallModpack(modpack),
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
                            builder: (context) =>
                                ModpackDetailPage(modpack: modpack),
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

  Widget _buildDefaultCover() {
    return Container(
      color: BamcColors.surface,
      child: const Icon(
        Icons.widgets,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  void _handleInstallModpack(ContentItem modpack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装整合包'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装整合包 ${modpack.name} 吗？'),
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
              await _installModpack(modpack);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installModpack(ContentItem modpack) async {
    setState(() => _isLoading = true);
    try {
      // 使用整合包管理器安装
      // 创建Modpack对象
      final modpackObj = Modpack(
        id: modpack.id,
        name: modpack.name,
        author: modpack.author,
        version: modpack.version,
        description: modpack.description,
        minecraftVersion: modpack.gameVersions.first,
        loaderType: modpack.loaders.first,
        fileCount: 0,
        size: 0,
        format: ModpackFormat.curseforge,
        status: ModpackStatus.installed,
        createdAt: DateTime.now(),
      );

      final result = await modpackManager.installModpack(
        modpack: modpackObj,
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('整合包 ${modpack.name} 安装成功')),
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

  void _showModpackDetails(ContentItem modpack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('整合包详情: ${modpack.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${modpack.author}'),
            Text('版本: ${modpack.version}'),
            Text('下载量: ${modpack.downloadCount}'),
            const SizedBox(height: 16),
            Text('描述: ${modpack.description}'),
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
            '整合包下载',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '提供整合包搜索、下载、一键安装，自动处理依赖冲突',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 搜索栏
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 筛选器
          _buildFilters(),
          const SizedBox(height: 20),

          // 整合包网格
          _buildModpackGrid(),
        ],
      ),
    );
  }
}
