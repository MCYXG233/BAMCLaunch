import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/core.dart';
import '../../../core/performance/performance_monitor.dart'
    as performance_monitor;
import '../../../core/ipc/implementations/ipc_manager.dart';
import '../../../core/ipc/implementations/terracotta_integration.dart';
import 'custom_title_bar.dart';
import 'sidebar.dart';
import 'breadcrumb_navigation.dart';
import '../../components/dialogs/update_dialog.dart';
import '../../pages/home/home_page.dart';
import '../../pages/version/version_page.dart';
import '../../pages/account/account_page.dart';
import '../../pages/content/content_page.dart';
import '../../pages/modpack/modpack_page.dart';
import '../../pages/server/server_page.dart';
import '../../pages/settings/settings_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  NavigationItem _selectedItem = NavigationItem.home;
  late IServerManager _serverManager;
  late IConfigManager _configManager;
  late IGameLauncher _gameLauncher;
  late IUpdateManager _updateManager;
  late performance_monitor.PerformanceMonitor _performanceMonitor;
  bool _showPerformanceOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializePerformanceMonitor();
    _initializeManagers();
  }

  void _initializePerformanceMonitor() {
    _performanceMonitor = performance_monitor.PerformanceMonitor();
    _performanceMonitor.startMonitoring(
      fpsInterval: 500,
      metricsInterval: 2000,
    );

    // 监听性能告警
    _performanceMonitor.onAlert = (alert) {
      logger.warn('Performance Alert: ${alert.type} - ${alert.message}');
    };
  }

  Future<void> _initializeManagers() async {
    _configManager = configManager;
    _gameLauncher = gameLauncher;
    _serverManager = serverManager;
    _updateManager = updateManager;

    await _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      UpdateInfo? updateInfo = await _updateManager.checkForUpdates();
      if (updateInfo != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            updateManager: _updateManager,
          ),
        );
      }
    } catch (e) {
      logger.error('检查更新失败: $e');
    }
  }

  void _handleNavigationItemSelected(NavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    // 记录页面切换性能
    _performanceMonitor.onFrameRendered();
  }

  void _togglePerformanceOverlay() {
    setState(() {
      _showPerformanceOverlay = !_showPerformanceOverlay;
    });
  }

  Widget _buildContent() {
    // 使用懒加载优化页面性能
    final pages = [
      HomePage(versionManager: versionManager),
      VersionPage(
          versionManager: versionManager, contentManager: contentManager),
      ContentPage(versionManager: versionManager),
      const ModpackPage(),
      ServerPage(serverManager: _serverManager),
      AccountPage(accountManager: accountManager),
      SettingsPage(configManager: _configManager),
    ];

    return PageStorage(
      bucket: PageStorageBucket(),
      child: IndexedStack(
        index: _selectedItem.index,
        children: pages.asMap().entries.map((entry) {
          final index = entry.key;
          final page = entry.value;
          return _buildLazyLoadedPage(index, page);
        }).toList(),
      ),
    );
  }

  Widget _buildLazyLoadedPage(int index, Widget page) {
    return Visibility(
      visible: _selectedItem.index == index,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: false,
      child: page,
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '功能开发中',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<BreadcrumbItem> _buildBreadcrumbs() {
    switch (_selectedItem) {
      case NavigationItem.home:
        return [
          BreadcrumbItem(title: '主页', isActive: true),
        ];
      case NavigationItem.versions:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '版本管理', isActive: true),
        ];
      case NavigationItem.mods:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '模组管理', isActive: true),
        ];
      case NavigationItem.modpacks:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '整合包', isActive: true),
        ];
      case NavigationItem.servers:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '服务器', isActive: true),
        ];
      case NavigationItem.accounts:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '账户', isActive: true),
        ];
      case NavigationItem.settings:
        return [
          BreadcrumbItem(
              title: '主页',
              onTap: () => _handleNavigationItemSelected(NavigationItem.home)),
          BreadcrumbItem(title: '设置', isActive: true),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Scaffold(
            body: Column(
              children: [
                // 自定义标题栏
                CustomTitleBar(
                  title: 'BAMCLauncher',
                  isMacOS: defaultTargetPlatform == TargetPlatform.macOS,
                  onPerformanceToggle: _togglePerformanceOverlay,
                ),
                Expanded(
                  child: Row(
                    children: [
                      // 侧边栏
                      Sidebar(
                        selectedItem: _selectedItem,
                        onItemSelected: _handleNavigationItemSelected,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            // 面包屑导航
                            BreadcrumbNavigation(items: _buildBreadcrumbs()),
                            // 主内容区
                            Expanded(
                              child: Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: _buildContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 性能叠加层
          if (_showPerformanceOverlay)
            performance_monitor.PerformanceOverlay(
              monitor: _performanceMonitor,
              showFps: true,
              showMemory: true,
              showCpu: true,
              showNetwork: false,
              showAlerts: true,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _performanceMonitor.stopMonitoring();
    super.dispose();
  }
}
