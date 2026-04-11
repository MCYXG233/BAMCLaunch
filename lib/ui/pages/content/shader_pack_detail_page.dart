import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class ShaderPackDetailPage extends StatefulWidget {
  final ContentItem shaderPack;

  const ShaderPackDetailPage({super.key, required this.shaderPack});

  @override
  State<ShaderPackDetailPage> createState() => _ShaderPackDetailPageState();
}

class _ShaderPackDetailPageState extends State<ShaderPackDetailPage> {
  bool _isLoading = false;
  bool _isFavorite = false;
  List<String> _previewImages = [];
  List<ShaderPackVersion> _versions = [];
  ShaderPackVersion? _selectedVersion;
  String? _selectedLoader;

  @override
  void initState() {
    super.initState();
    _loadShaderPackDetails();
  }

  Future<void> _loadShaderPackDetails() async {
    setState(() => _isLoading = true);
    try {
      // 模拟加载光影包详情数据
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _previewImages = [
          'https://example.com/shaders/preview1.jpg',
          'https://example.com/shaders/preview2.jpg',
          'https://example.com/shaders/preview3.jpg',
        ];

        _versions = [
          ShaderPackVersion(
            id: '1.0.0',
            name: '1.0.0',
            gameVersion: '1.20.1',
            loader: 'optifine',
            performance: 'high',
            releaseTime: '2024-01-15',
            fileSize: '64MB',
            downloadUrl: 'https://example.com/shaders/example-1.0.0.zip',
          ),
          ShaderPackVersion(
            id: '0.9.0',
            name: '0.9.0',
            gameVersion: '1.19.4',
            loader: 'iris',
            performance: 'medium',
            releaseTime: '2023-12-10',
            fileSize: '60MB',
            downloadUrl: 'https://example.com/shaders/example-0.9.0.zip',
          ),
        ];

        _selectedVersion = _versions.first;
        _selectedLoader = 'optifine';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载光影包详情失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleInstall() {
    if (_selectedVersion == null || _selectedLoader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择版本和光影加载器')),
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
            Text('光影包: ${widget.shaderPack.name}'),
            Text('版本: ${_selectedVersion!.name}'),
            Text(
                '光影加载器: ${_selectedLoader == 'optifine' ? 'OptiFine' : 'Iris'}'),
            Text(
                '性能需求: ${_getPerformanceLabel(_selectedVersion!.performance)}'),
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
      await contentManager.installContent(
        item: widget.shaderPack,
        versionId: _selectedVersion!.id,
        onProgress: (progress) {},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('光影包 ${widget.shaderPack.name} 安装成功')),
      );
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

  String _getPerformanceLabel(String performance) {
    switch (performance) {
      case 'low':
        return '低';
      case 'medium':
        return '中';
      case 'high':
        return '高';
      case 'very_high':
        return '极高';
      default:
        return '未知';
    }
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

  Widget _buildShaderPackInfo() {
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
                      widget.shaderPack.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('作者: ${widget.shaderPack.author}'),
                    Text('版本: ${widget.shaderPack.version}'),
                    Text('下载量: ${widget.shaderPack.downloadCount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('描述:'),
          const SizedBox(height: 8),
          Text(widget.shaderPack.description),
        ],
      ),
    );
  }

  Widget _buildConfigurationRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '配置要求',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('推荐显卡: '),
              Text('NVIDIA GTX 1060 / AMD RX 580 或更高'),
            ],
          ),
          Row(
            children: [
              Text('推荐内存: '),
              Text('8GB 或更高'),
            ],
          ),
          Row(
            children: [
              Text('性能影响: '),
              Text('中等'),
            ],
          ),
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
            return RadioListTile<ShaderPackVersion>(
              title: Text(version.name),
              subtitle: Text(
                  '${version.gameVersion} · ${version.loader == 'optifine' ? 'OptiFine' : 'Iris'} · 性能: ${_getPerformanceLabel(version.performance)}'),
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

  Widget _buildLoaderSelection() {
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
            '光影加载器选择',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('OptiFine'),
                  value: 'optifine',
                  groupValue: _selectedLoader,
                  onChanged: (value) {
                    setState(() => _selectedLoader = value);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Iris'),
                  value: 'iris',
                  groupValue: _selectedLoader,
                  onChanged: (value) {
                    setState(() => _selectedLoader = value);
                  },
                ),
              ),
            ],
          ),
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
        title: Text('光影包详情: ${widget.shaderPack.name}'),
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
                  _buildShaderPackInfo(),
                  const SizedBox(height: 16),
                  _buildConfigurationRequirements(),
                  const SizedBox(height: 16),
                  _buildVersionList(),
                  const SizedBox(height: 16),
                  _buildLoaderSelection(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }
}

class ShaderPackVersion {
  final String id;
  final String name;
  final String gameVersion;
  final String loader;
  final String performance;
  final String releaseTime;
  final String fileSize;
  final String downloadUrl;

  ShaderPackVersion({
    required this.id,
    required this.name,
    required this.gameVersion,
    required this.loader,
    required this.performance,
    required this.releaseTime,
    required this.fileSize,
    required this.downloadUrl,
  });
}
