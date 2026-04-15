import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import '../../components/layout/bamc_card.dart';
import '../../components/dialogs/version_install_dialog.dart';
import '../../components/dialogs/error_dialog.dart';
import 'loader_install_test_page.dart';
import 'version_settings_page.dart';

class VersionPage extends StatefulWidget {
  final IVersionManager versionManager;
  final IContentManager contentManager;
  final IGameLauncher gameLauncher;
  final AccountManager accountManager;

  const VersionPage({
    super.key,
    required this.versionManager,
    required this.contentManager,
    required this.gameLauncher,
    required this.accountManager,
  });

  @override
  State<VersionPage> createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage> {
  bool _isLoading = false;
  List<Version> _installedVersions = [];
  List<VersionEntry> _availableVersions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      // 加载已安装版本
      final installedVersions =
          await widget.versionManager.getInstalledVersions();
      setState(() => _installedVersions = installedVersions);

      // 加载可用版本列表
      final manifest = await widget.versionManager.getVersionManifest();
      setState(() => _availableVersions = manifest.versions);
    } catch (e) {
      logger.error('Failed to load versions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSearch(String query) {
    setState(() => _searchQuery = query);
  }

  List<Version> _getFilteredVersions() {
    if (_searchQuery.isEmpty) {
      return _installedVersions;
    }
    return _installedVersions
        .where((version) =>
            version.id.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作栏
          _buildActionBar(context),
          const SizedBox(height: 20),

          // 版本列表 - 占满剩余空间
          Expanded(
            child: _buildVersionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BamcInput(
            hintText: '搜索版本...',
            prefixIcon: Icons.search,
            onChanged: _handleSearch,
            size: BamcInputSize.medium,
            fullWidth: true,
          ),
        ),
        const SizedBox(width: 16),
        BamcButton(
          text: '安装版本',
          onPressed: () async {
            final result = await showDialog(
              context: context,
              builder: (context) => VersionInstallDialog(
                versionManager: widget.versionManager,
              ),
            );
            if (result == true) {
              await _loadVersions();
            }
          },
          type: BamcButtonType.primary,
          size: BamcButtonSize.medium,
          icon: Icons.add,
        ),
        const SizedBox(width: 16),
        BamcButton(
          text: '安装加载器',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoaderInstallTestPage(
                  versionManager: versionManager,
                ),
              ),
            );
          },
          type: BamcButtonType.outline,
          size: BamcButtonSize.medium,
          icon: Icons.extension,
        ),
      ],
    );
  }

  Widget _buildVersionList() {
    final filteredVersions = _getFilteredVersions();

    return BamcCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // 列表头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BamcColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '版本名称',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '类型',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '版本号',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '操作',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          // 版本列表项 - 使用ListView.builder实现懒加载
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVersions.isEmpty
                    ? const Center(
                        child: Text(
                          '没有找到匹配的版本',
                          style: TextStyle(color: BamcColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredVersions.length,
                        itemBuilder: (context, index) =>
                            _buildVersionItem(filteredVersions[index]),
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem(Version version) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BamcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BamcColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gamepad,
                      size: 24,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minecraft ${version.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                    Text(
                      version.status == VersionStatus.installed ? '已安装' : '未安装',
                      style: TextStyle(
                        fontSize: 12,
                        color: version.status == VersionStatus.installed
                            ? BamcColors.success
                            : BamcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              version.type == 'release' ? '稳定版' : '快照版',
              style: TextStyle(
                fontSize: 14,
                color: version.type == 'release'
                    ? BamcColors.textPrimary
                    : BamcColors.warning,
              ),
            ),
          ),
          Expanded(
            child: Text(
              version.id,
              style: const TextStyle(
                fontSize: 14,
                color: BamcColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BamcButton(
                  text: '启动',
                  onPressed: () async {
                    if (version.status == VersionStatus.installed) {
                      await _launchGame(version);
                    } else {
                      logger.warn(
                          'Cannot start uninstalled version: ${version.id}');
                      if (mounted) {
                        ErrorDialog.show(context, '错误', '版本未安装，无法启动');
                      }
                    }
                  },
                  type: BamcButtonType.primary,
                  size: BamcButtonSize.small,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: BamcColors.textSecondary),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('设置'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('复制'),
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 'settings':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VersionSettingsPage(
                              version: version,
                              versionManager: widget.versionManager,
                              contentManager: widget.contentManager,
                            ),
                          ),
                        );
                        break;
                      case 'delete':
                        await widget.versionManager
                            .uninstallVersion(version.id);
                        await _loadVersions();
                        break;
                      case 'edit':
                        logger.info('Editing version: ${version.id}');
                        break;
                      case 'duplicate':
                        logger.info('Duplicating version: ${version.id}');
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGame(Version version) async {
    try {
      // 检查是否有选中的账户
      final selectedAccount = widget.accountManager.selectedAccount;
      if (selectedAccount == null) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '请先选择一个账户');
        }
        return;
      }

      // 检查Java环境
      final javaResult = await widget.gameLauncher.detectJava();
      if (!javaResult.found) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '未找到Java环境: ${javaResult.error}');
        }
        return;
      }

      // 构建启动配置
      final config = await widget.gameLauncher.buildLaunchConfig(
        gameVersion: version.id,
        username: selectedAccount.username,
        uuid: selectedAccount.id,
        accessToken: selectedAccount.tokenData?.accessToken ?? '',
        memoryMb: 4096, // 默认4GB内存
      );

      // 启动游戏
      await widget.gameLauncher.launchGame(config);
      
      logger.info('Game launched successfully: ${version.id}');
    } catch (e) {
      logger.error('Failed to launch game: $e');
      if (mounted) {
        ErrorDialog.show(context, '启动失败', '无法启动游戏: $e');
      }
    }
  }
}
