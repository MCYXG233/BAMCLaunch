import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
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
          query: _searchQuery,
          type: ContentType.mod,
          gameVersion: _selectedGameVersion,
        );
        setState(() => _mods = result);
      } else {
        // 加载热门模组
        final popular = await contentManager.getPopularContent(
          type: ContentType.mod,
        );
        setState(() => _mods = popular);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载模组失败: $e')),
        );
      }
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BamcColors.border.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.border,
                      width: 1,
                    ),
                    color: BamcColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedGameVersion,
                    hint: const Text(
                      '选择游戏版本',
                      style: TextStyle(
                        color: BamcColors.textSecondary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
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
                    style: const TextStyle(
                      color: BamcColors.textPrimary,
                      fontFamily: 'Minecraft',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.border,
                      width: 1,
                    ),
                    color: BamcColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedLoader,
                    hint: const Text(
                      '选择模组加载器',
                      style: TextStyle(
                        color: BamcColors.textSecondary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'forge', child: Text('Forge')),
                      DropdownMenuItem(value: 'fabric', child: Text('Fabric')),
                      DropdownMenuItem(value: 'quilt', child: Text('Quilt')),
                      DropdownMenuItem(
                          value: 'neoforge', child: Text('NeoForge')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedLoader = value);
                    },
                    style: const TextStyle(
                      color: BamcColors.textPrimary,
                      fontFamily: 'Minecraft',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.border,
                      width: 1,
                    ),
                    color: BamcColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text(
                      '选择分类',
                      style: TextStyle(
                        color: BamcColors.textSecondary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'technology', child: Text('科技')),
                      DropdownMenuItem(value: 'magic', child: Text('魔法')),
                      DropdownMenuItem(value: 'adventure', child: Text('冒险')),
                      DropdownMenuItem(
                          value: 'performance', child: Text('性能优化')),
                      DropdownMenuItem(value: 'utility', child: Text('实用工具')),
                      DropdownMenuItem(value: 'decoration', child: Text('装饰')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                    style: const TextStyle(
                      color: BamcColors.textPrimary,
                      fontFamily: 'Minecraft',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BamcInput(
                  hintText: '作者名称',
                  initialValue: _selectedAuthor,
                  onChanged: (value) => setState(() => _selectedAuthor = value),
                  suffixIcon: Icons.person,
                  fillColor: BamcColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.border,
                      width: 1,
                    ),
                    color: BamcColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<SortType>(
                    value: _selectedSortType,
                    hint: const Text(
                      '选择排序方式',
                      style: TextStyle(
                        color: BamcColors.textSecondary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
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
                    style: const TextStyle(
                      color: BamcColors.textPrimary,
                      fontFamily: 'Minecraft',
                    ),
                  ),
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
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
              ),
              const Spacer(),
              BamcButton(
                text: '应用筛选',
                onPressed: _loadMods,
                type: BamcButtonType.primary,
                size: BamcButtonSize.medium,
                icon: Icons.filter_list,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BamcColors.primary,
                    BamcColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: BamcColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.extension,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '加载中...',
              style: TextStyle(
                color: BamcColors.primary,
                fontSize: 16,
                fontFamily: 'Minecraft',
              ),
            ),
          ],
        ),
      );
    }

    if (_mods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BamcColors.surface,
                    BamcColors.background,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BamcColors.border,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.extension_off,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关模组' : '暂无模组数据',
              style: const TextStyle(
                color: BamcColors.textSecondary,
                fontSize: 16,
                fontFamily: 'Minecraft',
              ),
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
        childAspectRatio: 0.85,
      ),
      itemCount: _mods.length,
      itemBuilder: (context, index) {
        final mod = _mods[index];
        return _buildModCard(mod);
      },
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _buildModCard(ContentItem mod) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BamcColors.border.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModDetailPage(mod: mod),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 模组图标
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BamcColors.primary.withOpacity(0.1),
                        BamcColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: mod.iconUrl != null
                      ? Image.network(
                          mod.iconUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultIcon();
                          },
                        )
                      : _buildDefaultIcon(),
                ),
                const SizedBox(height: 12),
                // 模组名称
                Text(
                  mod.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                    fontFamily: 'Minecraft',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 模组作者
                Text(
                  '作者: ${mod.author}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                    fontFamily: 'Minecraft',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 模组版本和下载量
                Text(
                  '版本: ${mod.version} · 下载: ${mod.downloadCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: BamcColors.textTertiary,
                    fontFamily: 'Minecraft',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // 安装按钮
                BamcButton(
                  text: '安装',
                  onPressed: () => _handleInstallMod(mod),
                  type: BamcButtonType.primary,
                  size: BamcButtonSize.small,
                  fullWidth: true,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: BamcColors.primary.withValues(alpha: 0.1),
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
      final platformAdapter = PlatformAdapterFactory.getInstance();
      final destination = '${platformAdapter.gameDirectory}/mods';
      final result = await contentManager.installContent(
        mod.id,
        mod.version,
        destination,
      );

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('模组 ${mod.name} 安装成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('安装失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安装失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('切换到收藏夹模式')),
      );
    }
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
