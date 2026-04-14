import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class ResourcePackDetailPage extends StatefulWidget {
  final ContentItem resourcePack;

  const ResourcePackDetailPage({super.key, required this.resourcePack});

  @override
  State<ResourcePackDetailPage> createState() => _ResourcePackDetailPageState();
}

class _ResourcePackDetailPageState extends State<ResourcePackDetailPage> {
  bool _isLoading = false;
  bool _isFavorite = false;
  List<String> _previewImages = [];
  List<ResourcePackVersion> _versions = [];
  ResourcePackVersion? _selectedVersion;
  String? _selectedInstance;

  @override
  void initState() {
    super.initState();
    _loadResourcePackDetails();
  }

  Future<void> _loadResourcePackDetails() async {
    setState(() => _isLoading = true);
    try {
      // 模拟加载资源包详情数据
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _previewImages = [
          'https://example.com/resourcepacks/preview1.jpg',
          'https://example.com/resourcepacks/preview2.jpg',
          'https://example.com/resourcepacks/preview3.jpg',
        ];

        _versions = [
          ResourcePackVersion(
            id: '1.0.0',
            name: '1.0.0',
            gameVersion: '1.20.1',
            resolution: '64x',
            releaseTime: '2024-01-15',
            fileSize: '128MB',
            downloadUrl: 'https://example.com/resourcepacks/example-1.0.0.zip',
          ),
          ResourcePackVersion(
            id: '0.9.0',
            name: '0.9.0',
            gameVersion: '1.19.4',
            resolution: '64x',
            releaseTime: '2023-12-10',
            fileSize: '120MB',
            downloadUrl: 'https://example.com/resourcepacks/example-0.9.0.zip',
          ),
        ];

        _selectedVersion = _versions.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载资源包详情失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleInstall() {
    if (_selectedVersion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择版本')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('资源包: ${widget.resourcePack.name}'),
            Text('版本: ${_selectedVersion!.name}'),
            Text('分辨率: ${_selectedVersion!.resolution}'),
            const SizedBox(height: 16),
            const Text('确定要安装吗？'),
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
              await _performInstall();
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _performInstall() async {
    setState(() => _isLoading = true);
    try {
      final platformAdapter = PlatformAdapterFactory.getInstance();
      final destination = '${platformAdapter.gameDirectory}/resourcepacks';
      final result = await contentManager.installContent(
        widget.resourcePack.id,
        _selectedVersion!.id,
        destination,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('资源包 ${widget.resourcePack.name} 安装成功')),
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

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? '已添加到收藏夹' : '已从收藏夹移除')),
    );
  }

  Widget _buildPreviewCarousel() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: PageView.builder(
        itemCount: _previewImages.length,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Image.network(
              _previewImages[index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: BamcColors.surface,
                  child: const Icon(Icons.image_not_supported,
                      size: 64, color: Colors.grey),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourcePackInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.resourcePack.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('作者: ${widget.resourcePack.author}'),
                    Text('版本: ${widget.resourcePack.version}'),
                    Text('下载量: ${widget.resourcePack.downloadCount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('描述:'),
          const SizedBox(height: 8),
          Text(widget.resourcePack.description),
        ],
      ),
    );
  }

  Widget _buildVersionList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '版本列表',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._versions.map((version) {
            return RadioListTile<ResourcePackVersion>(
              title: Text(version.name),
              subtitle: Text(
                  '${version.gameVersion} · ${version.resolution} · ${version.releaseTime}'),
              value: version,
              groupValue: _selectedVersion,
              onChanged: (value) {
                setState(() => _selectedVersion = value);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: BamcButton(
              text: '一键安装',
              onPressed: _handleInstall,
              type: BamcButtonType.primary,
              size: BamcButtonSize.large,
              icon: Icons.install_desktop,
            ),
          ),
          const SizedBox(width: 12),
          BamcButton(
            text: '下载到本地',
            onPressed: () {
              // 下载到本地
            },
            type: BamcButtonType.outline,
            size: BamcButtonSize.large,
            icon: Icons.download,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? BamcColors.danger : BamcColors.textSecondary,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('资源包详情: ${widget.resourcePack.name}'),
        backgroundColor: BamcColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildPreviewCarousel(),
                  const SizedBox(height: 16),
                  _buildResourcePackInfo(),
                  const SizedBox(height: 16),
                  _buildVersionList(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }
}

class ResourcePackVersion {
  final String id;
  final String name;
  final String gameVersion;
  final String resolution;
  final String releaseTime;
  final String fileSize;
  final String downloadUrl;

  ResourcePackVersion({
    required this.id,
    required this.name,
    required this.gameVersion,
    required this.resolution,
    required this.releaseTime,
    required this.fileSize,
    required this.downloadUrl,
  });
}
