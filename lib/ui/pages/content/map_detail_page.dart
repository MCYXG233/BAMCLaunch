import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class MapDetailPage extends StatefulWidget {
  final ContentItem map;

  const MapDetailPage({super.key, required this.map});

  @override
  State<MapDetailPage> createState() => _MapDetailPageState();
}

class _MapDetailPageState extends State<MapDetailPage> {
  bool _isLoading = false;
  ContentItem? _selectedVersion;
  String? _selectedGameInstance;
  List<String> _gameInstances = [];

  @override
  void initState() {
    super.initState();
    _loadGameInstances();
  }

  Future<void> _loadGameInstances() async {
    try {
      // 模拟加载游戏实例
      setState(() => _gameInstances = ['默认实例', '测试实例']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载游戏实例失败: $e')),
      );
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 预览图轮播
        _buildPreviewCarousel(),
        const SizedBox(height: 20),

        // 地图信息
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.map.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '作者: ${widget.map.author}',
                        style: const TextStyle(
                          color: BamcColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                BamcButton(
                  text: '收藏',
                  onPressed: () => _toggleFavorite(),
                  type: BamcButtonType.outline,
                  size: BamcButtonSize.medium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 标签和统计信息
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('版本: ${widget.map.version}'),
                _buildTag('下载量: ${widget.map.downloadCount}'),
                _buildTag('更新时间: 未知'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewCarousel() {
    // 模拟预览图片
    final images = [
      'https://example.com/map1.jpg',
      'https://example.com/map2.jpg'
    ];

    if (images.isEmpty) {
      return Container(
        height: 300,
        color: BamcColors.surface,
        child: const Center(
          child: Icon(Icons.map, size: 64, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: BamcColors.surface,
      ),
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: BamcColors.surface,
                child: const Icon(Icons.image_not_supported,
                    size: 64, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: BamcColors.primary.withAlpha(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: BamcColors.primary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '地图介绍',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          widget.map.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: BamcColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallationInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安装说明',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: BamcColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep('1. 选择要安装的游戏实例'),
              _buildInstructionStep('2. 点击"一键安装"按钮'),
              _buildInstructionStep('3. 安装完成后即可在游戏中加载该地图'),
              const SizedBox(height: 8),
              const Text(
                '注意：地图安装到游戏的saves目录下',
                style: TextStyle(
                  fontSize: 12,
                  color: BamcColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: BamcColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step,
              style: const TextStyle(
                  fontSize: 14, color: BamcColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionList() {
    // 获取地图版本列表
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '版本列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BamcColors.border),
          ),
          child: Column(
            children: [
              // 版本列表项
              _buildVersionItem(widget.map),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionItem(ContentItem version) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BamcColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  version.version,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Text(
                '未知',
                style: TextStyle(color: BamcColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '支持版本: ${version.gameVersions.join(', ')}',
            style:
                const TextStyle(color: BamcColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInstanceSelector() {
    if (_gameInstances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: BamcColors.surface,
        ),
        child: const Column(
          children: [
            Icon(Icons.warning, color: BamcColors.warning, size: 32),
            SizedBox(height: 8),
            Text(
              '暂无可用的游戏实例',
              style: TextStyle(color: BamcColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择游戏实例',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: BamcColors.surface,
          ),
          child: Column(
            children: _gameInstances.map((instance) {
              return RadioListTile<String>(
                title: Text(instance),
                value: instance,
                groupValue: _selectedGameInstance,
                onChanged: (value) {
                  setState(() => _selectedGameInstance = value);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: BamcButton(
            text: '一键安装',
            onPressed: _handleInstall,
            type: BamcButtonType.primary,
            size: BamcButtonSize.large,
            isLoading: _isLoading,
          ),
        ),
        const SizedBox(width: 12),
        BamcButton(
          text: '下载到本地',
          onPressed: _handleDownload,
          type: BamcButtonType.outline,
          size: BamcButtonSize.large,
        ),
      ],
    );
  }

  void _toggleFavorite() {
    // 实现收藏功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('收藏功能开发中')),
    );
  }

  void _handleInstall() {
    if (_selectedGameInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择游戏实例')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认安装'),
        content:
            Text('确定要将地图 ${widget.map.name} 安装到游戏实例 $_selectedGameInstance 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _installMap();
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installMap() async {
    setState(() => _isLoading = true);
    try {
      final result = await contentManager.installContent(
        item: widget.map,
        versionId: widget.map.version,
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地图 ${widget.map.name} 安装成功')),
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

  void _handleDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载到本地'),
        content: Text('确定要下载地图 ${widget.map.name} 到本地吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadMap();
            },
            child: const Text('下载'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMap() async {
    setState(() => _isLoading = true);
    try {
      final result = await contentManager.installContent(
        item: widget.map,
        versionId: widget.map.version,
        onProgress: (progress) {},
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地图 ${widget.map.name} 下载成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            _buildInstallationInstructions(),
            const SizedBox(height: 24),
            _buildVersionList(),
            const SizedBox(height: 24),
            _buildGameInstanceSelector(),
            const SizedBox(height: 24),
            _buildActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
