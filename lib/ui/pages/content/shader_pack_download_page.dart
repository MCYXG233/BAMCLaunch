import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import './shader_pack_detail_page.dart';

class ShaderPackDownloadPage extends StatefulWidget {
  const ShaderPackDownloadPage({super.key});

  @override
  State<ShaderPackDownloadPage> createState() => _ShaderPackDownloadPageState();
}

class _ShaderPackDownloadPageState extends State<ShaderPackDownloadPage> {
  String _searchQuery = '';
  String? _selectedGameVersion;
  String? _selectedLoader;
  String? _selectedStyle;
  String? _selectedSort;
  bool _isLoading = false;
  List<ContentItem> _shaderPacks = [];

  @override
  void initState() {
    super.initState();
    _loadShaderPacks();
  }

  Future<void> _loadShaderPacks() async {
    setState(() => _isLoading = true);
    try {
      if (_searchQuery.isNotEmpty) {
        final result = await contentManager.searchContent(
          SearchQuery(
            query: _searchQuery,
            type: ContentType.shaderPack,
            gameVersion: _selectedGameVersion,
          ),
        );
        setState(() => _shaderPacks = result.items);
      } else {
        // 加载热门光影包
        final popular =
            await contentManager.getPopularContent(ContentType.shaderPack);
        setState(() => _shaderPacks = popular);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载光影包失败: $e')),
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
            hintText: '搜索光影包...',
            initialValue: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            suffixIcon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '搜索',
          onPressed: _loadShaderPacks,
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
                  labelText: '光影加载器',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedLoader,
                hint: const Text('选择加载器'),
                items: const [
                  DropdownMenuItem(value: 'optifine', child: Text('OptiFine')),
                  DropdownMenuItem(value: 'iris', child: Text('Iris')),
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
                  labelText: '风格',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedStyle,
                hint: const Text('选择风格'),
                items: const [
                  DropdownMenuItem(value: 'realistic', child: Text('写实')),
                  DropdownMenuItem(value: 'cartoon', child: Text('卡通')),
                  DropdownMenuItem(value: 'lightweight', child: Text('轻量化')),
                  DropdownMenuItem(value: 'cinematic', child: Text('电影级')),
                  DropdownMenuItem(value: 'performance', child: Text('性能向')),
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
                  _selectedLoader = null;
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

  Widget _buildShaderPackGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_shaderPacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.brightness_7, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到相关光影包' : '暂无光影包数据',
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
      itemCount: _shaderPacks.length,
      itemBuilder: (context, index) {
        final shaderPack = _shaderPacks[index];
        return _buildShaderPackCard(shaderPack);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildShaderPackCard(ContentItem shaderPack) {
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
            child: shaderPack.iconUrl != null
                ? Image.network(
                    shaderPack.iconUrl!,
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
                  shaderPack.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '作者: ${shaderPack.author}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '光影加载器: ${_selectedLoader == 'optifine' ? 'OptiFine' : _selectedLoader == 'iris' ? 'Iris' : '通用'}',
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
                        onPressed: () => _handleInstallShaderPack(shaderPack),
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
                                ShaderPackDetailPage(shaderPack: shaderPack),
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
        Icons.brightness_7,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  void _handleInstallShaderPack(ContentItem shaderPack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装光影包'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装光影包 ${shaderPack.name} 吗？'),
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
              await _installShaderPack(shaderPack);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installShaderPack(ContentItem shaderPack) async {
    setState(() => _isLoading = true);
    try {
      final result = await contentManager.installContent(
        item: shaderPack,
        versionId: 'latest',
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('光影包 ${shaderPack.name} 安装成功')),
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

  void _showShaderPackDetails(ContentItem shaderPack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('光影包详情: ${shaderPack.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${shaderPack.author}'),
            Text('版本: ${shaderPack.version}'),
            Text('下载量: ${shaderPack.downloadCount}'),
            const SizedBox(height: 16),
            Text('描述: ${shaderPack.description}'),
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
            '光影包下载',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '提供光影着色器包的下载、安装能力，适配OptiFine与Iris',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 搜索栏
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 筛选器
          _buildFilters(),
          const SizedBox(height: 20),

          // 光影包网格
          _buildShaderPackGrid(),
        ],
      ),
    );
  }
}
