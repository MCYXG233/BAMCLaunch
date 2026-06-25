import 'package:flutter/material.dart';
import '../../version/version_manager.dart';
import '../../version/models.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/ba_buttons.dart';
import '../components/ba_inputs.dart';
import '../components/ba_progress.dart';

/// 版本管理页面
/// 用于管理Minecraft版本的安装、卸载和查看
class BAMCVersionPage extends StatefulWidget {
  const BAMCVersionPage({super.key});

  @override
  State<BAMCVersionPage> createState() => _BAMCVersionPageState();
}

class _BAMCVersionPageState extends State<BAMCVersionPage>
    with SingleTickerProviderStateMixin {
  final VersionManager _versionManager = VersionManager();
  final EventBus _eventBus = EventBus();
  final Logger _logger = Logger('BAMCVersionPage');

  /// 标签页控制器
  late TabController _tabController;

  /// 版本列表
  List<GameVersion> _versions = [];

  /// 已安装版本列表
  List<String> _installedVersions = [];

  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  /// 搜索查询
  String _searchQuery = '';

  /// 选中的版本类型过滤器
  VersionType? _filterType;

  /// 是否正在加载
  bool _isLoading = false;

  /// 正在安装的版本ID
  String? _installingVersionId;

  /// 安装进度
  double _installProgress = 0.0;

  /// 安装阶段描述
  String _installStage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVersions();
    _setupEventListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    // 监听版本列表更新事件
    _eventBus.on<VersionListFetchedEvent>((event) {
      if (mounted) {
        setState(() {});
      }
    });

    // 监听已安装版本变化事件
    _eventBus.on<InstalledVersionsChangedEvent>((event) {
      if (mounted) {
        _loadInstalledVersions();
      }
    });

    // 监听版本卸载事件
    _eventBus.on<VersionUninstalledEvent>((event) {
      if (mounted) {
        _loadInstalledVersions();
        _showSnackBar('版本已卸载', success: true);
      }
    });
  }

  /// 加载版本列表
  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final versions = await _versionManager.fetchVersionList();
      setState(() {
        _versions = versions;
      });
      await _loadInstalledVersions();
    } catch (e, stackTrace) {
      _logger.error('加载版本列表失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('加载版本列表失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载已安装版本
  Future<void> _loadInstalledVersions() async {
    try {
      final installed = await _versionManager.getInstalledVersions();
      setState(() {
        _installedVersions = installed;
      });
    } catch (e) {
      _logger.error('加载已安装版本失败', e);
    }
  }

  /// 安装版本
  Future<void> _installVersion(GameVersion version) async {
    if (_installingVersionId != null) {
      _showSnackBar('请等待当前安装完成');
      return;
    }

    setState(() {
      _installingVersionId = version.id;
      _installProgress = 0.0;
      _installStage = '准备安装...';
    });

    try {
      // 监听安装进度
      final subscription = _versionManager.installProgressStream.listen((
        progress,
      ) {
        if (mounted) {
          setState(() {
            _installProgress = progress.progress;
            _installStage = progress.stage;
          });
        }
      });

      // 执行安装
      await _versionManager.installVersion(version.id);

      if (mounted) {
        _showSnackBar('${version.id} 安装成功!', success: true);
      }

      subscription.cancel();
    } catch (e, stackTrace) {
      _logger.error('安装版本失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('安装失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _installingVersionId = null;
          _installProgress = 0.0;
          _installStage = '';
        });
      }
    }
  }

  /// 卸载版本
  Future<void> _uninstallVersion(GameVersion version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('卸载 ${version.id}'),
        content: const Text('确定要卸载此版本吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: BAColors.dangerOf(context)),
            child: const Text('卸载'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _versionManager.uninstallVersion(version.id);
      } catch (e, stackTrace) {
        _logger.error('卸载版本失败', e, stackTrace);
        if (mounted) {
          _showSnackBar('卸载失败: $e');
        }
      }
    }
  }

  /// 取消安装
  Future<void> _cancelInstall() async {
    try {
      await _versionManager.cancelInstall();
      if (mounted) {
        _showSnackBar('安装已取消');
      }
    } catch (e) {
      _logger.error('取消安装失败', e);
    }
  }

  /// 过滤版本列表
  List<GameVersion> _filterVersions(
    List<GameVersion> versions,
    bool showInstalledOnly,
  ) {
    var filtered = versions;

    // 按安装状态过滤
    if (showInstalledOnly) {
      filtered = filtered
          .where((v) => _installedVersions.contains(v.id))
          .toList();
    } else {
      filtered = filtered
          .where((v) => !_installedVersions.contains(v.id))
          .toList();
    }

    // 按搜索查询过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((v) => v.id.toLowerCase().contains(query))
          .toList();
    }

    // 按版本类型过滤
    if (_filterType != null) {
      filtered = filtered.where((v) => v.type == _filterType).toList();
    }

    return filtered;
  }

  /// 显示提示消息
  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? BAColors.successOf(context) : BAColors.dangerOf(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.backgroundOf(context),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVersionList(true),
                      _buildVersionList(false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_installingVersionId != null) _buildInstallProgress(),
        ],
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(bottom: BorderSide(color: BAColors.borderOf(context), width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.extension, size: 32, color: BAColors.primaryOf(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '版本管理',
                  style: BATypography.headlineMedium.copyWith(
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  '管理和安装Minecraft版本',
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          BAPrimaryButton(
            text: '刷新',
            onPressed: _loadVersions,
            leadingIcon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 构建标签页
  Widget _buildTabBar() {
    return Container(
      color: BAColors.surfaceOf(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '已安装'),
              Tab(text: '可下载'),
            ],
            labelColor: BAColors.primaryOf(context),
            unselectedLabelColor: BAColors.textSecondaryOf(context),
            indicatorColor: BAColors.primaryOf(context),
            indicatorWeight: 3,
          ),
          _buildFilters(),
        ],
      ),
    );
  }

  /// 构建过滤器
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BAColors.borderOf(context), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BATextField(
              controller: _searchController,
              hintText: '搜索版本...',
              prefixIcon: Icon(Icons.search),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          _buildTypeFilter(),
        ],
      ),
    );
  }

  /// 构建版本类型过滤器
  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(color: BAColors.borderOf(context), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VersionType?>(
          value: _filterType,
          hint: Text(
            '全部类型',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          icon: Icon(Icons.filter_list, color: BAColors.textSecondaryOf(context)),
          items: [
            const DropdownMenuItem<VersionType?>(
              value: null,
              child: Text('全部类型'),
            ),
            DropdownMenuItem<VersionType>(
              value: VersionType.release,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text('正式版'),
                ],
              ),
            ),
            DropdownMenuItem<VersionType>(
              value: VersionType.snapshot,
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text('快照版'),
                ],
              ),
            ),
            DropdownMenuItem<VersionType>(
              value: VersionType.oldBeta,
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  const Text('Beta版'),
                ],
              ),
            ),
            DropdownMenuItem<VersionType>(
              value: VersionType.oldAlpha,
              child: Row(
                children: [
                  Icon(Icons.history_edu, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Text('Alpha版'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _filterType = value;
            });
          },
        ),
      ),
    );
  }

  /// 构建版本列表
  Widget _buildVersionList(bool showInstalledOnly) {
    final filteredVersions = _filterVersions(_versions, showInstalledOnly);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredVersions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showInstalledOnly ? Icons.inbox : Icons.cloud_off,
              size: 64,
              color: BAColors.textDisabledOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              showInstalledOnly ? '暂无已安装版本' : '没有可下载的版本',
              style: BATypography.bodyLarge.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            if (_searchQuery.isNotEmpty || _filterType != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '尝试调整搜索或筛选条件',
                  style: BATypography.bodySmall.copyWith(
                    color: BAColors.textDisabledOf(context),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: filteredVersions.length,
      itemBuilder: (context, index) {
        final version = filteredVersions[index];
        final isInstalled = _installedVersions.contains(version.id);
        final isInstalling = _installingVersionId == version.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildVersionItem(version, isInstalled, isInstalling),
        );
      },
    );
  }

  /// 构建单个版本项
  Widget _buildVersionItem(
    GameVersion version,
    bool isInstalled,
    bool isInstalling,
  ) {
    final versionColor = _getVersionColor(version.type);
    final versionIcon = _getVersionIcon(version.type);
    final versionTypeName = _getVersionTypeName(version.type);

    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.borderOf(context), width: 1),
        boxShadow: BATheme.shadowsSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: versionColor.withOpacity(0.15),
                    borderRadius: BATheme.borderRadiusSmall,
                  ),
                  child: Icon(versionIcon, color: versionColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        version.id,
                        style: BATypography.headlineSmall.copyWith(
                          color: BAColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: versionColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: versionColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              versionTypeName,
                              style: BATypography.label.copyWith(
                                color: versionColor,
                              ),
                            ),
                          ),
                          if (isInstalled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BAColors.successOf(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: BAColors.successOf(context).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '已安装',
                                style: BATypography.label.copyWith(
                                  color: BAColors.successOf(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isInstalling)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircularProgressIndicator(),
                  )
                else if (isInstalled)
                  BADangerButton(
                    text: '卸载',
                    onPressed: () => _uninstallVersion(version),
                    leadingIcon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  )
                else
                  BAPrimaryButton(
                    text: '安装',
                    onPressed: () => _installVersion(version),
                    leadingIcon: const Icon(
                      Icons.download,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建安装进度显示
  Widget _buildInstallProgress() {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(top: BorderSide(color: BAColors.borderOf(context), width: 1)),
        boxShadow: [
          BoxShadow(
            color: BAColors.shadowOf(context).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.downloading, color: BAColors.primaryOf(context), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在安装: $_installingVersionId',
                      style: BATypography.bodyLarge.copyWith(
                        color: BAColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _installStage,
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              BASecondaryButton(text: '取消', onPressed: _cancelInstall),
            ],
          ),
          const SizedBox(height: 16),
          BAExperienceProgressBar(value: _installProgress, height: 24),
        ],
      ),
    );
  }

  /// 获取版本类型颜色
  Color _getVersionColor(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Colors.green;
      case VersionType.snapshot:
        return Colors.orange;
      case VersionType.oldBeta:
        return Colors.purple;
      case VersionType.oldAlpha:
        return Colors.red;
    }
  }

  /// 获取版本类型图标
  IconData _getVersionIcon(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Icons.check_circle;
      case VersionType.snapshot:
        return Icons.science;
      case VersionType.oldBeta:
        return Icons.history;
      case VersionType.oldAlpha:
        return Icons.history_edu;
    }
  }

  /// 获取版本类型名称
  String _getVersionTypeName(VersionType type) {
    switch (type) {
      case VersionType.release:
        return '正式版';
      case VersionType.snapshot:
        return '快照版';
      case VersionType.oldBeta:
        return 'Beta版';
      case VersionType.oldAlpha:
        return 'Alpha版';
    }
  }
}
