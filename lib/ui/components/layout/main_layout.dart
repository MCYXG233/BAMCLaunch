import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/core.dart';
import '../../../core/performance/performance_monitor.dart'
    as performance_monitor;
import '../../theme/colors.dart';
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

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  NavigationItem _selectedItem = NavigationItem.home;
  NavigationItem? _previousItem;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;
  late IServerManager _serverManager;
  late IConfigManager _configManager;
  late IGameLauncher _gameLauncher;
  late IUpdateManager _updateManager;
  late performance_monitor.PerformanceMonitor _performanceMonitor;
  bool _showPerformanceOverlay = false;
  bool _isSidebarCollapsed = false;

  void _initializePerformanceMonitor() {
    _performanceMonitor = performance_monitor.PerformanceMonitor();
    _performanceMonitor.startMonitoring(
      fpsInterval: 500,
      metricsInterval: 2000,
    );

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
            updateManager: _updateManager as UpdateManager,
          ),
        );
      }
    } catch (e) {
      logger.error('检查更新失败: $e');
    }
  }

  void _handleNavigationItemSelected(NavigationItem item) {
    if (_selectedItem != item) {
      setState(() {
        _previousItem = _selectedItem;
        _selectedItem = item;
      });
      _pageAnimationController.reset();
      _pageAnimationController.forward();
      _performanceMonitor.onFrameRendered();
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _performanceMonitor.stopMonitoring();
    super.dispose();
  }

  void _togglePerformanceOverlay() {
    setState(() {
      _showPerformanceOverlay = !_showPerformanceOverlay;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePerformanceMonitor();
    _initializeManagers().then((_) {
      _initializePages();
    });

    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pageAnimationController.forward();
  }

  void _initializePages() {
    _pages = [
      HomePage(
        versionManager: versionManager,
        contentManager: contentManager,
        gameLauncher: gameLauncher,
        accountManager: accountManager,
        onNavigateToVersions: () =>
            _handleNavigationItemSelected(NavigationItem.versions),
        onNavigateToModpacks: () =>
            _handleNavigationItemSelected(NavigationItem.modpacks),
      ),
      VersionPage(
        versionManager: versionManager,
        contentManager: contentManager,
        gameLauncher: gameLauncher,
        accountManager: accountManager,
      ),
      ContentPage(versionManager: versionManager),
      const ModpackPage(),
      ServerPage(serverManager: _serverManager),
      AccountPage(accountManager: accountManager),
      SettingsPage(configManager: _configManager),
    ];
  }

  Widget _buildContent() {
    return PageStorage(
      bucket: PageStorageBucket(),
      child: AnimatedBuilder(
        animation: _pageAnimation,
        builder: (context, child) {
          return IndexedStack(
            index: _selectedItem.index,
            children: _pages.asMap().entries.map((entry) {
              final index = entry.key;
              final page = entry.value;
              return _buildLazyLoadedPage(index, page);
            }).toList(),
          );
        },
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

  List<BreadcrumbItem> _buildBreadcrumbs() {
    switch (_selectedItem) {
      case NavigationItem.home:
        return [BreadcrumbItem(title: '主页', isActive: true)];
      case NavigationItem.versions:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '版本管理', isActive: true),
        ];
      case NavigationItem.content:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '资源中心', isActive: true),
        ];
      case NavigationItem.modpacks:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '整合包', isActive: true),
        ];
      case NavigationItem.servers:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '服务器', isActive: true),
        ];
      case NavigationItem.accounts:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '账户', isActive: true),
        ];
      case NavigationItem.settings:
        return [
          BreadcrumbItem(
            title: '主页',
            onTap: () => _handleNavigationItemSelected(NavigationItem.home),
          ),
          BreadcrumbItem(title: '设置', isActive: true),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BamcColors.background,
      child: Stack(
        children: [
          _buildBackgroundEffects(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                CustomTitleBar(
                  title: 'BAMCLauncher',
                  isMacOS: defaultTargetPlatform == TargetPlatform.macOS,
                  onPerformanceToggle: _togglePerformanceOverlay,
                ),
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: _isSidebarCollapsed ? 80 : 260,
                        child: Sidebar(
                          selectedItem: _selectedItem,
                          onItemSelected: _handleNavigationItemSelected,
                          isCollapsed: _isSidebarCollapsed,
                          onToggle: _toggleSidebar,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: BamcColors.glassCardGradient,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: BamcColors.glassBorder,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BamcColors.shadowHeavy,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: BamcColors.primary.withOpacity(0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              children: [
                                BreadcrumbNavigation(
                                  items: _buildBreadcrumbs(),
                                ),
                                Expanded(
                                  child: _buildContent(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildBackgroundEffects() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: BamcColors.contentBackgroundGradient,
      ),
      child: Stack(
        children: [
          _buildDynamicStars(),
          _buildOrbitalEffects(),
        ],
      ),
    );
  }

  Widget _buildDynamicStars() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.4,
        child: CustomPaint(
          painter: _DynamicStarFieldPainter(),
        ),
      ),
    );
  }

  Widget _buildOrbitalEffects() {
    return Stack(
      children: [
        Positioned(
          top: 100,
          right: -150,
          child: AnimatedContainer(
            duration: const Duration(seconds: 20),
            curve: Curves.linear,
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BamcColors.primary.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: AnimatedContainer(
            duration: const Duration(seconds: 15),
            curve: Curves.linear,
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BamcColors.accent.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 300,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BamcColors.secondary.withOpacity(0.06),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicStarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final random = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final starSize = random.nextDouble() * 2.5 + 0.3;
      final opacity = random.nextDouble() * 0.7 + 0.15;
      final twinkle = (random.nextDouble() * 0.5 + 0.5);

      paint.color = Colors.white.withOpacity(opacity * twinkle);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}