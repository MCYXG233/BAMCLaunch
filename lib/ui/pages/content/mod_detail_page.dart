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
      final platformAdapter = PlatformAdapterFactory.getInstance();
      final destination = '${platformAdapter.gameDirectory}/mods';
      final result = await contentManager.installContent(
        widget.mod.id,
        _selectedVersion!.id,
        destination,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模组 ${widget.mod.name} 安装成功')),
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

  void _shareMod() {
    // 分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享链接已复制到剪贴板')),
    );
  }

  Widget _buildModInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModIcon(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mod.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: BamcColors.textPrimary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '作者: ${widget.mod.author}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: BamcColors.textSecondary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本: ${widget.mod.version} · 下载: ${widget.mod.downloadCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: BamcColors.textTertiary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '描述:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              fontFamily: 'Minecraft',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.primary.withOpacity(0.05),
                  BamcColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BamcColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.mod.description,
              style: const TextStyle(
                fontSize: 14,
                color: BamcColors.textPrimary,
                lineHeight: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '版本列表',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              fontFamily: 'Minecraft',
            ),
          ),
          const SizedBox(height: 16),
          ..._versions.map((version) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _selectedVersion == version
                        ? BamcColors.primary.withOpacity(0.1)
                        : BamcColors.surface,
                    _selectedVersion == version
                        ? BamcColors.primary.withOpacity(0.05)
                        : BamcColors.background,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedVersion == version
                      ? BamcColors.primary
                      : BamcColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<ModVersion>(
                    value: version,
                    groupValue: _selectedVersion,
                    onChanged: (value) {
                      setState(() => _selectedVersion = value);
                    },
                    activeColor: BamcColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          version.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.textPrimary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${version.gameVersion} · ${version.loader} · ${version.releaseTime} · ${version.fileSize}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BamcColors.textSecondary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDependencies() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '依赖管理',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              fontFamily: 'Minecraft',
            ),
          ),
          const SizedBox(height: 16),
          ..._dependencies.map((dep) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    dep.installed
                        ? BamcColors.success.withOpacity(0.1)
                        : BamcColors.danger.withOpacity(0.1),
                    dep.installed
                        ? BamcColors.success.withOpacity(0.05)
                        : BamcColors.danger.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dep.installed
                      ? BamcColors.success.withOpacity(0.3)
                      : BamcColors.danger.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          dep.installed
                              ? BamcColors.success
                              : BamcColors.danger,
                          dep.installed
                              ? BamcColors.successDark
                              : BamcColors.dangerDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        dep.installed ? Icons.check : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.textPrimary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '版本要求: ${dep.version} · ${dep.required ? '必需' : '可选'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BamcColors.textSecondary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                      ],
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  if (dep.installed)
                    const Text(
                      '已安装',
                      style: TextStyle(
                        fontSize: 12,
                        color: BamcColors.success,
                        fontFamily: 'Minecraft',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (_dependencies.any((dep) => !dep.installed))
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: BamcButton(
                text: '一键安装所有缺失依赖',
                onPressed: () {
                  // 一键安装所有缺失依赖
                },
                type: BamcButtonType.primary,
                size: BamcButtonSize.medium,
                fullWidth: true,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibility() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '兼容性检测',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              fontFamily: 'Minecraft',
            ),
          ),
          const SizedBox(height: 16),
          ..._compatibleInstances.map((instance) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    instance.compatible
                        ? BamcColors.success.withOpacity(0.1)
                        : BamcColors.danger.withOpacity(0.1),
                    instance.compatible
                        ? BamcColors.success.withOpacity(0.05)
                        : BamcColors.danger.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: instance.compatible
                      ? BamcColors.success.withOpacity(0.3)
                      : BamcColors.danger.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<GameInstance>(
                    value: instance,
                    groupValue: _selectedInstance,
                    onChanged: instance.compatible
                        ? (value) {
                            setState(() => _selectedInstance = value);
                          }
                        : null,
                    activeColor: BamcColors.primary,
                    enabled: instance.compatible,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          instance.compatible
                              ? BamcColors.success
                              : BamcColors.danger,
                          instance.compatible
                              ? BamcColors.successDark
                              : BamcColors.dangerDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        instance.compatible ? Icons.check : Icons.cancel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.textPrimary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${instance.gameVersion} · ${instance.loader}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BamcColors.textSecondary,
                            fontFamily: 'Minecraft',
                          ),
                        ),
                        if (!instance.compatible) const SizedBox(height: 4),
                        if (!instance.compatible)
                          const Text(
                            '不兼容',
                            style: TextStyle(
                              fontSize: 12,
                              color: BamcColors.danger,
                              fontFamily: 'Minecraft',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.1),
            BamcColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BamcColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          BamcButton(
            text: '下载到本地',
            onPressed: () {
              // 下载到本地
            },
            type: BamcButtonType.outline,
            size: BamcButtonSize.large,
            icon: Icons.download,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isFavorite ? BamcColors.danger : BamcColors.surface,
                  _isFavorite ? BamcColors.dangerDark : BamcColors.background,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFavorite ? BamcColors.danger : BamcColors.border,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFavorite
                      ? BamcColors.danger.withOpacity(0.3)
                      : BamcColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.white : BamcColors.textSecondary,
                size: 24,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
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
                color: BamcColors.border,
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
            child: IconButton(
              icon: const Icon(
                Icons.share,
                color: BamcColors.textSecondary,
                size: 24,
              ),
              onPressed: _shareMod,
            ),
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BamcColors.primary.withOpacity(0.1),
                BamcColors.surface,
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(
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
              )
            : Column(
                children: [
                  _buildModInfo(),
                  const SizedBox(height: 20),
                  _buildVersionList(),
                  const SizedBox(height: 20),
                  _buildDependencies(),
                  const SizedBox(height: 20),
                  _buildCompatibility(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
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
