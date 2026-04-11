import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import '../../components/lists/bamc_list.dart';
import './mod_detail_page.dart';

class ModDownloadPage extends StatefulWidget {
  const ModDownloadPage({super.key});

  @override
  State<ModDownloadPage> createState() => _ModDownloadPageState();
}

class _ModDownloadPageState extends State<ModDownloadPage> {
  String _searchQuery = '';
  String? _selectedGameVersion;
  String? _selectedLoader;
  String? _selectedCategory;
  String? _selectedAuthor;
  SortType _selectedSortType = SortType.relevance;
  bool _isLoading = false;
  List<ContentItem> _mods = [];

  @override
  void initState() {
    super.initState();
    _loadMods();
  }

  Future<void> _loadMods() async {
    setState(() => _isLoading = true);
    try {
      if (_searchQuery.isNotEmpty) {
        final result = await contentManager.searchContent(
          SearchQuery(
            query: _searchQuery,
            type: ContentType.mod,
            gameVersion: _selectedGameVersion,
            loader: _selectedLoader,
            category: _selectedCategory,
            author: _selectedAuthor,
            sortType: _selectedSortType,
          ),
        );
        setState(() => _mods = result.items);
      } else {
        // 加载热门模组
        final popular = await contentManager.getPopularContent(ContentType.mod);
        setState(() => _mods = popular);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载模组失败: $e')),
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
            hintText: '搜索模组...',
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            suffixIcon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '搜索',
          onPressed: _loadMods,
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
                  labelText: '模组加载器',
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
                  labelText: '分类',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedCategory,
                hint: const Text('选择分类'),
                items: const [
                  DropdownMenuItem(value: 'technology', child: Text('科技')),
                  DropdownMenuItem(value: 'magic', child: Text('魔法')),
                  DropdownMenuItem(value: 'adventure', child: Text('冒险')),
                  DropdownMenuItem(value: 'performance', child: Text('性能优化')),
                  DropdownMenuItem(value: 'utility', child: Text('实用工具')),
                  DropdownMenuItem(value: 'decoration', child: Text('装饰')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BamcInput(
                hintText: '作者名称',
                initialValue: _selectedAuthor,
                onChanged: (value) => setState(() => _selectedAuthor = value),
                suffixIcon: Icons.person,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<SortType>(
                decoration: const InputDecoration(
                  labelText: '排序方式',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedSortType,
                hint: const Text('选择排序'),
                items: const [
                  DropdownMenuItem(
                    value: SortType.relevance,
                    child: Text('相关性'),
                  ),
                  DropdownMenuItem(
                    value: SortType.downloads,
                    child: Text('下载量'),
                  ),
                  DropdownMenuItem(
                    value: SortType.recentlyUpdated,
                    child: Text('最近更新'),
                  ),
                  DropdownMenuItem(
                    value: SortType.recentlyAdded,
                    child: Text('最近添加'),
                  ),
                  DropdownMenuItem(
                    value: SortType.featured,
                    child: Text('推荐'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedSortType = value!);
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
                  _selectedAuthor = null;
                  _selectedSortType = SortType.relevance;
                });
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.medium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            BamcButton(
              text: '高级搜索',
              onPressed: () {
                _showAdvancedSearch();
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.small,
              icon: Icons.filter_alt,
            ),
            const SizedBox(width: 12),
            BamcButton(
              text: '收藏夹',
              onPressed: () {
                _switchToFavorites();
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.small,
              icon: Icons.favorite,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关模组' : '暂无模组数据',
              style: const TextStyle(color: BamcColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return BamcList<ContentItem>(
      items: _mods,
      itemBuilder: (context, mod, index, isSelected) {
        return BamcListItem(
          leading: _buildModIcon(mod),
          title: Text(mod.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('作者: ${mod.author}'),
              Text('版本: ${mod.version} · 下载量: ${mod.downloadCount}'),
            ],
          ),
          trailing: BamcButton(
            text: '安装',
            onPressed: () => _handleInstallMod(mod),
            type: BamcButtonType.primary,
            size: BamcButtonSize.small,
          ),
          selected: isSelected,
        );
      },
      onTap: (mod) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModDetailPage(mod: mod),
          ),
        );
      },
    );
  }

  Widget _buildModIcon(ContentItem mod) {
    if (mod.iconUrl != null) {
      return Image.network(
        mod.iconUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultIcon();
        },
      );
    } else {
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: BamcColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.extension, color: Colors.blue, size: 24),
    );
  }

  void _handleInstallMod(ContentItem mod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装模组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装模组 ${mod.name} 吗？'),
            const SizedBox(height: 16),
            // 这里可以添加版本选择、安装路径等选项
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
              await _installMod(mod);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installMod(ContentItem mod) async {
    setState(() => _isLoading = true);
    try {
      final result = await contentManager.installContent(
        item: mod,
        versionId: 'latest',
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模组 ${mod.name} 安装成功')),
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

  void _showModDetails(ContentItem mod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('模组详情: ${mod.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${mod.author}'),
            Text('版本: ${mod.version}'),
            Text('下载量: ${mod.downloadCount}'),
            const SizedBox(height: 16),
            Text('描述: ${mod.description}'),
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

  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高级搜索'),
        content: const SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 高级搜索选项
              TextField(
                decoration: InputDecoration(
                  labelText: '作者',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '最低下载量',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '最低评分',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '更新时间从',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '更新时间到',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadMods();
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _switchToFavorites() {
    // 切换到收藏夹模式
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('切换到收藏夹模式')),
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
            '模组下载',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '对接CurseForge、Modrinth等平台，提供全量模组搜索下载',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 搜索栏
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 筛选器
          _buildFilters(),
          const SizedBox(height: 20),

          // 模组列表
          _buildModList(),
        ],
      ),
    );
  }
}
