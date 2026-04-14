import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';

class VersionSettingsPage extends StatefulWidget {
  final Version version;
  final IVersionManager versionManager;
  final IContentManager contentManager;

  const VersionSettingsPage({
    super.key,
    required this.version,
    required this.versionManager,
    required this.contentManager,
  });

  @override
  State<VersionSettingsPage> createState() => _VersionSettingsPageState();
}

class _VersionSettingsPageState extends State<VersionSettingsPage> {
  bool _isLoading = false;
  List<ContentItem> _mods = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMods();
  }

  Future<void> _loadMods() async {
    setState(() => _isLoading = true);
    try {
      final mods =
          await widget.contentManager.getInstalledContent(ContentType.mod);
      setState(() => _mods = mods);
    } catch (e) {
      logger.error('Failed to load mods: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSearch(String query) {
    setState(() => _searchQuery = query);
  }

  List<ContentItem> _getFilteredMods() {
    if (_searchQuery.isEmpty) {
      return _mods;
    }
    return _mods
        .where((mod) =>
            mod.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            mod.author.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _handleToggleMod(ContentItem mod) async {
    setState(() => _isLoading = true);
    try {
      // 这里应该实现模组的启用/禁用逻辑
      logger.info('Toggle mod: ${mod.name}');
      await _loadMods();
    } catch (e) {
      logger.error('Failed to toggle mod: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUninstallMod(ContentItem mod) async {
    setState(() => _isLoading = true);
    try {
      await widget.contentManager.uninstallContent(mod.id);
      await _loadMods();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模组卸载成功')),
      );
    } catch (e) {
      logger.error('Failed to uninstall mod: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('卸载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddMod() async {
    // 导航到资源中心页面选择模组
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMods = _getFilteredMods();

    return Scaffold(
      appBar: AppBar(
        title: Text('版本设置 - ${widget.version.id}'),
        backgroundColor: BamcColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本信息
            _buildVersionInfo(),
            const SizedBox(height: 20),

            // 模组管理
            _buildModManagementSection(filteredMods),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
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
            '版本信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '版本号:',
                style: TextStyle(
                  fontSize: 14,
                  color: BamcColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.version.id,
                style: const TextStyle(
                  fontSize: 14,
                  color: BamcColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '类型:',
                style: TextStyle(
                  fontSize: 14,
                  color: BamcColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.version.type == 'release' ? '稳定版' : '快照版',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.version.type == 'release'
                      ? BamcColors.success
                      : BamcColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModManagementSection(List<ContentItem> filteredMods) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '模组管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BamcColors.textPrimary,
                ),
              ),
              BamcButton(
                text: '添加模组',
                onPressed: _handleAddMod,
                type: BamcButtonType.primary,
                size: BamcButtonSize.small,
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 搜索栏
          Row(
            children: [
              Expanded(
                child: BamcInput(
                  hintText: '搜索模组...',
                  initialValue: _searchQuery,
                  onChanged: _handleSearch,
                  suffixIcon: Icons.search,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 模组列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.extension_off,
                                size: 64, color: BamcColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? '没有找到匹配的模组' : '暂无模组',
                              style: const TextStyle(
                                  color: BamcColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredMods.length,
                        itemBuilder: (context, index) =>
                            _buildModItem(filteredMods[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildModItem(ContentItem mod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Row(
        children: [
          // 模组图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BamcColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: mod.iconUrl != null
                ? Image.network(
                    mod.iconUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.extension,
                        size: 24,
                        color: BamcColors.textSecondary,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.extension,
                      size: 24,
                      color: BamcColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // 模组信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mod.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mod.author} · ${mod.version}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            children: [
              Switch(
                value: true, // 暂时默认启用
                onChanged: (value) => _handleToggleMod(mod),
                activeThumbColor: BamcColors.primary,
              ),
              const SizedBox(width: 8),
              BamcButton(
                text: '卸载',
                onPressed: () => _handleUninstallMod(mod),
                type: BamcButtonType.warning,
                size: BamcButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
