import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class ModDetailPage extends StatefulWidget {
  final ContentItem mod;

  const ModDetailPage({super.key, required this.mod});

  @override
  State<ModDetailPage> createState() => _ModDetailPageState();
}

class _ModDetailPageState extends State<ModDetailPage> {
  bool _isLoading = false;
  bool _isFavorite = false;
  List<ModVersion> _versions = [];
  List<ModDependency> _dependencies = [];
  List<GameInstance> _compatibleInstances = [];
  ModVersion? _selectedVersion;
  GameInstance? _selectedInstance;

  @override
  void initState() {
    super.initState();
    _loadModDetails();
  }

  Future<void> _loadModDetails() async {
    setState(() => _isLoading = true);
    try {
      // 模拟加载模组详情数据
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _versions = [
          ModVersion(
            id: '1.0.0',
            name: '1.0.0',
            gameVersion: '1.20.1',
            loader: 'Forge',
            releaseTime: '2024-01-15',
            fileSize: '2.5MB',
            downloadUrl: 'https://example.com/mods/example-1.0.0.jar',
          ),
          ModVersion(
            id: '0.9.0',
            name: '0.9.0',
            gameVersion: '1.19.4',
            loader: 'Fabric',
            releaseTime: '2023-12-10',
            fileSize: '2.3MB',
            downloadUrl: 'https://example.com/mods/example-0.9.0.jar',
          ),
        ];

        _dependencies = [
          ModDependency(
            name: 'CoreLib',
            version: '>=1.0.0',
            required: true,
            installed: true,
          ),
          ModDependency(
            name: 'API',
            version: '>=2.0.0',
            required: true,
            installed: false,
          ),
        ];

        _compatibleInstances = [
          GameInstance(
            id: 'instance-1',
            name: '生存模式',
            gameVersion: '1.20.1',
            loader: 'Forge',
            compatible: true,
          ),
          GameInstance(
            id: 'instance-2',
            name: '创造模式',
            gameVersion: '1.19.4',
            loader: 'Fabric',
            compatible: true,
          ),
          GameInstance(
            id: 'instance-3',
            name: '测试实例',
            gameVersion: '1.18.2',
            loader: 'Forge',
            compatible: false,
          ),
        ];

        _selectedVersion = _versions.first;
        _selectedInstance = _compatibleInstances.firstWhere(
          (instance) => instance.compatible,
          orElse: () => _compatibleInstances.first,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载模组详情失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleInstall() {
    if (_selectedVersion == null || _selectedInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择版本和游戏实例')),
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
            Text('模组: ${widget.mod.name}'),
            Text('版本: ${_selectedVersion!.name}'),
            Text('安装到: ${_selectedInstance!.name}'),
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
        item: widget.mod,
        versionId: _selectedVersion!.id,
        onProgress: (progress) {},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模组 ${widget.mod.name} 安装成功')),
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

  void _shareMod() {
    // 分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享链接已复制到剪贴板')),
    );
  }

  Widget _buildModInfo() {
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
              _buildModIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mod.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('作者: ${widget.mod.author}'),
                    Text('版本: ${widget.mod.version}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('描述:'),
          const SizedBox(height: 8),
          Text(widget.mod.description),
          const SizedBox(height: 16),
          Row(
            children: [
              BamcButton(
                text: '原帖链接',
                onPressed: () {
                  // 打开原帖
                },
                type: BamcButtonType.outline,
                size: BamcButtonSize.small,
                icon: Icons.open_in_new,
              ),
              const SizedBox(width: 12),
              BamcButton(
                text: '开源地址',
                onPressed: () {
                  // 打开开源地址
                },
                type: BamcButtonType.outline,
                size: BamcButtonSize.small,
                icon: Icons.code,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModIcon() {
    if (widget.mod.iconUrl != null) {
      return Image.network(
        widget.mod.iconUrl!,
        width: 64,
        height: 64,
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: BamcColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.extension, color: Colors.blue, size: 32),
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
            return RadioListTile<ModVersion>(
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

  Widget _buildDependencies() {
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
            '依赖管理',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._dependencies.map((dep) {
            return ListTile(
              title: Text(dep.name),
              subtitle: Text('版本要求: ${dep.version}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dep.installed ? '已安装' : '未安装',
                    style: TextStyle(
                      color: dep.installed
                          ? BamcColors.success
                          : BamcColors.danger,
                    ),
                  ),
                  if (!dep.installed)
                    BamcButton(
                      text: '安装',
                      onPressed: () {
                        // 安装依赖
                      },
                      type: BamcButtonType.primary,
                      size: BamcButtonSize.small,
                    ),
                ],
              ),
            );
          }),
          if (_dependencies.any((dep) => !dep.installed))
            BamcButton(
              text: '一键安装所有缺失依赖',
              onPressed: () {
                // 一键安装所有缺失依赖
              },
              type: BamcButtonType.primary,
              size: BamcButtonSize.small,
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibility() {
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
            '兼容性检测',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._compatibleInstances.map((instance) {
            return RadioListTile<GameInstance>(
              title: Text(instance.name),
              subtitle: Text('${instance.gameVersion} · ${instance.loader}'),
              value: instance,
              groupValue: _selectedInstance,
              onChanged: instance.compatible
                  ? (value) {
                      setState(() => _selectedInstance = value);
                    }
                  : null,
              enabled: instance.compatible,
              secondary: Icon(
                instance.compatible ? Icons.check_circle : Icons.cancel,
                color: instance.compatible
                    ? BamcColors.success
                    : BamcColors.danger,
              ),
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
          IconButton(
            icon: const Icon(Icons.share, color: BamcColors.textSecondary),
            onPressed: _shareMod,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('模组详情: ${widget.mod.name}'),
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
                  _buildModInfo(),
                  const SizedBox(height: 16),
                  _buildVersionList(),
                  const SizedBox(height: 16),
                  _buildDependencies(),
                  const SizedBox(height: 16),
                  _buildCompatibility(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }
}

class ModVersion {
  final String id;
  final String name;
  final String gameVersion;
  final String loader;
  final String releaseTime;
  final String fileSize;
  final String downloadUrl;

  ModVersion({
    required this.id,
    required this.name,
    required this.gameVersion,
    required this.loader,
    required this.releaseTime,
    required this.fileSize,
    required this.downloadUrl,
  });
}

class ModDependency {
  final String name;
  final String version;
  final bool required;
  final bool installed;

  ModDependency({
    required this.name,
    required this.version,
    required this.required,
    required this.installed,
  });
}

class GameInstance {
  final String id;
  final String name;
  final String gameVersion;
  final String loader;
  final bool compatible;

  GameInstance({
    required this.id,
    required this.name,
    required this.gameVersion,
    required this.loader,
    required this.compatible,
  });
}
