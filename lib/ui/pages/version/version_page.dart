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
      final installedVersions =
          await widget.versionManager.getInstalledVersions();
      setState(() => _installedVersions = installedVersions);

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionBar(context),
          const SizedBox(height: 24),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: BamcColors.surfaceDark,
              border: const Border(bottom: BorderSide(color: BamcColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
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
    final isRelease = version.type == VersionType.release;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BamcColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isRelease ? BamcColors.primary.withOpacity(0.2) : BamcColors.accent.withOpacity(0.2),
                        isRelease ? BamcColors.primary.withOpacity(0.1) : BamcColors.accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRelease ? BamcColors.primary.withOpacity(0.3) : BamcColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isRelease ? Icons.gamepad_rounded : Icons.science_rounded,
                      size: 22,
                      color: isRelease ? BamcColors.primary : BamcColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minecraft ${version.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      version.status == VersionStatus.installed ? '已安装' : '未安装',
                      style: TextStyle(
                        fontSize: 12,
                        color: version.status == VersionStatus.installed
                            ? BamcColors.success
                            : BamcColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRelease 
                    ? BamcColors.success.withOpacity(0.15) 
                    : BamcColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isRelease 
                      ? BamcColors.success.withOpacity(0.3) 
                      : BamcColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isRelease ? '稳定版' : '快照版',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isRelease ? BamcColors.success : BamcColors.warning,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              version.id,
              style: const TextStyle(
                fontSize: 14,
                color: BamcColors.textSecondary,
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
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: BamcColors.textTertiary),
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
      final selectedAccount = widget.accountManager.selectedAccount;
      if (selectedAccount == null) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '请先选择一个账户');
        }
        return;
      }

      final javaResult = await widget.gameLauncher.detectJava();
      if (!javaResult.found) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '未找到Java环境: ${javaResult.error}');
        }
        return;
      }

      final config = await widget.gameLauncher.buildLaunchConfig(
        gameVersion: version.id,
        username: selectedAccount.username,
        uuid: selectedAccount.id,
        accessToken: selectedAccount.tokenData?.accessToken ?? '',
        memoryMb: 4096,
      );

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