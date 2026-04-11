import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/modpack/models/modpack_models.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class ModpackDetailPage extends StatefulWidget {
  final ContentItem modpack;

  const ModpackDetailPage({super.key, required this.modpack});

  @override
  State<ModpackDetailPage> createState() => _ModpackDetailPageState();
}

class _ModpackDetailPageState extends State<ModpackDetailPage> {
  bool _isLoading = false;
  bool _isFavorite = false;
  List<String> _galleryImages = [];
  List<ModInfo> _modList = [];
  List<ModpackVersion> _versions = [];
  ModpackVersion? _selectedVersion;
  String _installPath = '';
  bool _keepExistingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadModpackDetails();
  }

  Future<void> _loadModpackDetails() async {
    setState(() => _isLoading = true);
    try {
      // 模拟加载整合包详情数据
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _galleryImages = [
          'https://example.com/modpacks/gallery1.jpg',
          'https://example.com/modpacks/gallery2.jpg',
          'https://example.com/modpacks/gallery3.jpg',
        ];

        _modList = [
          ModInfo(name: 'Forge', version: '47.1.44'),
          ModInfo(name: 'JEI', version: '15.2.0.28'),
          ModInfo(name: 'OptiFine', version: 'HD_U_G9'),
          ModInfo(name: 'IronChests', version: '14.3.0'),
          ModInfo(name: 'TinkersConstruct', version: '3.5.1.31'),
        ];

        _versions = [
          ModpackVersion(
            id: '1.0.0',
            name: '1.0.0',
            gameVersion: '1.20.1',
            loader: 'Forge',
            releaseTime: '2024-01-15',
            fileSize: '256MB',
            downloadUrl: 'https://example.com/modpacks/example-1.0.0.zip',
          ),
          ModpackVersion(
            id: '0.9.0',
            name: '0.9.0',
            gameVersion: '1.19.4',
            loader: 'Fabric',
            releaseTime: '2023-12-10',
            fileSize: '240MB',
            downloadUrl: 'https://example.com/modpacks/example-0.9.0.zip',
          ),
        ];

        _selectedVersion = _versions.first;
        _installPath =
            '${Directory.current.path}/instances/${widget.modpack.name}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载整合包详情失败: $e')),
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
            Text('整合包: ${widget.modpack.name}'),
            Text('版本: ${_selectedVersion!.name}'),
            Text('安装路径: $_installPath'),
            Text('保留现有配置: ${_keepExistingConfig ? '是' : '否'}'),
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
      // 创建Modpack对象
      final modpackObj = Modpack(
        id: widget.modpack.id,
        name: widget.modpack.name,
        author: widget.modpack.author,
        version: _selectedVersion!.id,
        description: widget.modpack.description,
        minecraftVersion: widget.modpack.gameVersions.first,
        loaderType: widget.modpack.loaders.first,
        fileCount: 0,
        size: 0,
        format: ModpackFormat.curseforge,
        status: ModpackStatus.installed,
        createdAt: DateTime.now(),
      );

      await modpackManager.installModpack(
        modpack: modpackObj,
        onProgress: (progress) {},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('整合包 ${widget.modpack.name} 安装成功')),
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

  void _shareModpack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享链接已复制到剪贴板')),
    );
  }

  Widget _buildGallery() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: PageView.builder(
        itemCount: _galleryImages.length,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Image.network(
              _galleryImages[index],
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

  Widget _buildModpackInfo() {
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
                      widget.modpack.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('作者: ${widget.modpack.author}'),
                    Text('版本: ${widget.modpack.version}'),
                    Text('下载量: ${widget.modpack.downloadCount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('描述:'),
          const SizedBox(height: 8),
          Text(widget.modpack.description),
        ],
      ),
    );
  }

  Widget _buildModListPreview() {
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
            'Mod列表预览',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modList.map((mod) {
              return Chip(
                label: Text('${mod.name} ${mod.version}'),
                backgroundColor: BamcColors.surface,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text('共 ${_modList.length} 个Mod'),
        ],
      ),
    );
  }

  Widget _buildVersionSelection() {
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
            '版本选择',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._versions.map((version) {
            return RadioListTile<ModpackVersion>(
              title: Text(version.name),
              subtitle: Text(
                  '${version.gameVersion} · ${version.loader} · ${version.releaseTime}'),
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

  Widget _buildInstallSettings() {
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
            '安装设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // 安装路径
          const Text('安装路径:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _installPath),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '选择安装路径',
                  ),
                  onChanged: (value) {
                    setState(() => _installPath = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              BamcButton(
                text: '浏览',
                onPressed: () {
                  // 浏览文件夹功能
                },
                type: BamcButtonType.outline,
                size: BamcButtonSize.small,
                icon: Icons.folder_open,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 保留现有配置
          CheckboxListTile(
            title: const Text('保留现有配置文件'),
            value: _keepExistingConfig,
            onChanged: (value) {
              setState(() => _keepExistingConfig = value ?? false);
            },
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
            text: '下载压缩包',
            onPressed: () {
              // 下载压缩包
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
          IconButton(
            icon: const Icon(Icons.share, color: BamcColors.textSecondary),
            onPressed: _shareModpack,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('整合包详情: ${widget.modpack.name}'),
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
                  _buildGallery(),
                  const SizedBox(height: 16),
                  _buildModpackInfo(),
                  const SizedBox(height: 16),
                  _buildModListPreview(),
                  const SizedBox(height: 16),
                  _buildVersionSelection(),
                  const SizedBox(height: 16),
                  _buildInstallSettings(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }
}

class ModInfo {
  final String name;
  final String version;

  ModInfo({required this.name, required this.version});
}

class ModpackVersion {
  final String id;
  final String name;
  final String gameVersion;
  final String loader;
  final String releaseTime;
  final String fileSize;
  final String downloadUrl;

  ModpackVersion({
    required this.id,
    required this.name,
    required this.gameVersion,
    required this.loader,
    required this.releaseTime,
    required this.fileSize,
    required this.downloadUrl,
  });
}
