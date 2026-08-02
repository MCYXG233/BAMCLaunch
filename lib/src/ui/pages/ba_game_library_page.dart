import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/utils.dart';
import '../../core/logger.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../../event/event_bus.dart';
import '../../event/event.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../account/account_manager.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../components/ba_dialog.dart';
import '../components/ba_notification.dart';
import '../components/ba_buttons.dart';
import '../components/ba_create_instance_dialog.dart';
import '../components/ba_backup_dialog.dart';
import '../components/ba_mod_manager_dialog.dart';
import '../components/ba_directory_selector.dart';
import '../theme/colors.dart';
import '../../game/game_statistics.dart';

// 拆分后的组件
import 'game_library/widgets/index.dart';
import 'game_library/models/index.dart';

/// 蔚蓝档案风格游戏库页面 - 模仿蔚蓝档案的"学生"列表风格
class BAGameLibraryPage extends StatefulWidget {
  const BAGameLibraryPage({super.key});

  @override
  State<BAGameLibraryPage> createState() => _BAGameLibraryPageState();
}

class _BAGameLibraryPageState extends State<BAGameLibraryPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;

  // 实例详情页状态
  GameInstance? _selectedInstance;
  TabController? _detailTabController;
  static const List<String> _detailTabs = [
    '概览',
    '存档',
    '模组',
    '资源包',
    '光影',
    '截图'
  ];
  static const List<IconData> _detailTabIcons = [
    Icons.dashboard_rounded,
    Icons.folder_rounded,
    Icons.extension_rounded,
    Icons.palette_rounded,
    Icons.brightness_7_rounded,
    Icons.photo_camera_rounded,
  ];
  List<FileSystemEntity> _detailFiles = [];
  bool _isLoadingFiles = false;

  final List<String> _filters = ['全部', '游戏中', '已安装', '可更新'];

  List<GameInstance> _instances = [];
  final List<EventSubscription> _subscriptions = [];
  final Set<String> _launchingIds = {};

  // 详情页世界列表（从 saves/ 目录真实解析）
  List<WorldInfo> _worlds = [];
  bool _isLoadingWorlds = false;

  // 游戏统计
  final GameStatisticsManager _statsManager = GameStatisticsManager.instance;
  Duration _totalPlayTime = Duration.zero;
  int _totalLaunchCount = 0;
  Duration _todayPlayTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadInstances();
    _subscribeToEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NotificationManager().init(context);
  }

  Future<void> _initializeAndLoadInstances() async {
    try {
      final manager = InstanceManager();
      if (!manager.isInitialized) {
        await manager.initialize();
      }

      await _statsManager.initialize();

      _loadInstances();
      _loadStatistics();
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('初始化失败', message: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailTabController?.dispose();
    for (final sub in _subscriptions) {
      sub.unsubscribe();
    }
    super.dispose();
  }

  void _loadInstances() {
    final manager = InstanceManager();
    if (!manager.isInitialized) return;
    if (!mounted) return;

    final selectedDirId = manager.selectedDirectoryId;
    final all = List<GameInstance>.from(manager.instances);
    final newInstances = selectedDirId == null
        ? all
        : all.where((i) => i.directoryId == selectedDirId).toList();

    if (_selectedInstance != null) {
      final match = newInstances.where((i) => i.id == _selectedInstance!.id);
      if (match.isEmpty) {
        _selectedInstance = null;
        _detailTabController?.dispose();
        _detailTabController = null;
        _detailFiles = [];
      } else {
        _selectedInstance = match.first;
      }
    }

    setState(() {
      _instances = newInstances;
    });
  }

  void _loadStatistics() {
    if (!mounted) return;

    final instanceIds = _instances.map((i) => i.id).toSet();
    final sessions = _statsManager
        .getAllSessions(limit: 99999)
        .where((s) => instanceIds.contains(s.instanceId))
        .toList();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int totalSeconds = 0;
    int todaySeconds = 0;
    for (final s in sessions) {
      totalSeconds += s.playTimeSeconds;
      if (s.startTime.isAfter(todayStart)) {
        todaySeconds += s.playTimeSeconds;
      }
    }

    setState(() {
      _totalPlayTime = Duration(seconds: totalSeconds);
      _totalLaunchCount = sessions.length;
      _todayPlayTime = Duration(seconds: todaySeconds);
    });
  }

  void _subscribeToEvents() {
    final bus = EventBus.instance;
    _subscriptions.add(bus.on<InstanceCreatedEvent>((_) => _loadInstances()));
    _subscriptions.add(bus.on<InstanceDeletedEvent>((_) => _loadInstances()));
    _subscriptions.add(bus.on<InstanceUpdatedEvent>((_) => _loadInstances()));
  }

  // ===== 实例详情页导航 =====

  void _selectInstance(GameInstance instance) {
    setState(() {
      _selectedInstance = instance;
      _detailTabController?.dispose();
      _detailTabController = TabController(
        length: _detailTabs.length,
        vsync: this,
      );
      _detailTabController!.addListener(_onDetailTabChanged);
      _detailFiles = [];
      _worlds = [];
    });
    _loadDetailFiles(0);
    _loadWorlds(instance);
  }

  void _backToList() {
    setState(() {
      _selectedInstance = null;
      _detailTabController?.dispose();
      _detailTabController = null;
      _detailFiles = [];
      _worlds = [];
    });
  }

  void _onDetailTabChanged() {
    if (_detailTabController != null &&
        !_detailTabController!.indexIsChanging) {
      _loadDetailFiles(_detailTabController!.index);
    }
  }

  void _loadDetailFiles(int tabIndex) {
    if (_selectedInstance == null) return;

    if (tabIndex == 0) {
      if (mounted) setState(() => _detailFiles = []);
      return;
    }

    final manager = InstanceManager();
    String? dirPath;
    switch (tabIndex) {
      case 1:
        dirPath = manager.getInstanceSavesPath(_selectedInstance!.id);
        break;
      case 2:
        dirPath = manager.getInstanceModsPath(_selectedInstance!.id);
        break;
      case 3:
        dirPath = manager.getInstanceResourcePacksPath(_selectedInstance!.id);
        break;
      case 4:
        dirPath = manager.getInstanceShaderPacksPath(_selectedInstance!.id);
        break;
      case 5:
        dirPath = manager.getInstanceScreenshotsPath(_selectedInstance!.id);
        break;
    }

    if (dirPath == null) {
      if (mounted) {
        setState(() {
          _detailFiles = [];
          _isLoadingFiles = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoadingFiles = true);

    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        final files = dir.listSync()
          ..sort((a, b) {
            try {
              return b.statSync().modified.compareTo(a.statSync().modified);
            } catch (_) {
              return 0;
            }
          });
        if (mounted) {
          setState(() {
            _detailFiles = files;
            _isLoadingFiles = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _detailFiles = [];
            _isLoadingFiles = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailFiles = [];
          _isLoadingFiles = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '从未';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  List<GameInstance> _getFilteredInstances() {
    var list = _instances;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((i) => i.name.toLowerCase().contains(query)).toList();
    }
    switch (_selectedFilter) {
      case 1:
        list = list.where((i) => i.status == InstanceStatus.running).toList();
        break;
      case 2:
        list = list.where((i) => i.loader != null).toList();
        break;
      case 3:
        list = list
            .where(
              (i) =>
                  i.loader != null &&
                  (i.loader == 'forge' ||
                      i.loader == 'fabric' ||
                      i.loader == 'neoforge' ||
                      i.loader == 'quilt'),
            )
            .toList();
        break;
    }
    return list;
  }

  Future<void> _launchGame(GameInstance instance) async {
    if (instance.status == InstanceStatus.running) {
      NotificationManager().showWarning(
        '游戏已在运行',
        message: '实例 ${instance.name} 已经在运行中',
      );
      return;
    }

    if (_launchingIds.contains(instance.id)) return;

    setState(() => _launchingIds.add(instance.id));

    try {
      final account = await AccountManager().getSelectedAccount();
      if (account == null) {
        if (!mounted) return;
        NotificationManager().showError('启动失败', message: '请先选择一个账户');
        return;
      }

      final manager = InstanceManager();
      final directory = manager.directories.firstWhere(
        (d) => d.id == instance.directoryId,
        orElse: () => throw StateError('游戏目录不存在'),
      );

      final config = ConfigManager.instance;
      final javaPath =
          instance.config.javaPath ??
          config.get<String>(ConfigKeys.javaPath) ??
          'java';
      final memory =
          instance.config.maxMemory ??
          config.get<int>(ConfigKeys.memory) ??
          2048;
      final jvmArgs = instance.config.jvmArgs ?? [];
      final gameArgs = instance.config.gameArgs ?? [];

      final args = LaunchArguments(
        javaPath: javaPath,
        gameVersion: instance.version,
        account: account,
        gameDirectory: directory.path,
        memory: memory,
        jvmArguments: jvmArgs,
        gameArguments: gameArgs,
      );

      _statsManager.startSession(
        instanceName: instance.name,
        instanceId: instance.id,
        gameVersion: instance.version,
        accountId: account.uuid,
        username: account.username,
      );

      await GameLauncher().launch(args);

      if (!mounted) return;
      NotificationManager().showSuccess(
        '启动成功',
        message: '正在启动 ${instance.name}...',
      );
    } catch (e) {
      await _statsManager.endSession();
      if (!mounted) return;
      NotificationManager().showError('启动失败', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => _launchingIds.remove(instance.id));
        _loadStatistics();
      }
    }
  }

  Future<void> _deleteInstance(GameInstance instance) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除实例',
      content: '确定要删除实例 ${instance.name} 吗？此操作不可撤销。',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
    );

    if (!confirmed) return;

    try {
      await InstanceManager().deleteInstance(instance.id);
      if (!mounted) return;
      NotificationManager().showSuccess(
        '删除成功',
        message: '实例 ${instance.name} 已删除',
      );
      _loadInstances();
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('删除失败', message: e.toString());
    }
  }

  Future<void> _duplicateInstance(GameInstance instance) async {
    final nameController = TextEditingController(text: '${instance.name} - 副本');

    try {
      final newName = await BAFrostedDialog.show<String>(
        context: context,
        title: '复制实例',
        child: Builder(
          builder: (context) => TextField(
            controller: nameController,
            style: TextStyle(color: BAColors.textPrimaryOf(context)),
            decoration: InputDecoration(
              hintText: '请输入新实例名称',
              hintStyle: TextStyle(
                color:
                    BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              ),
              filled: true,
              fillColor: BAColors.surfaceOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: BAColors.primaryLightOf(context)),
              ),
            ),
          ),
        ),
        actions: [
          BASecondaryButton(
            text: '取消',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          BAPrimaryButton(
            text: '复制',
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
          ),
        ],
      );

      if (newName == null || newName.isEmpty) return;

      await InstanceManager().duplicateInstance(instance.id, newName);
      if (!mounted) return;
      NotificationManager().showSuccess('复制成功', message: '实例 $newName 已创建');
      _loadInstances();
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('复制失败', message: e.toString());
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _exportInstance(GameInstance instance) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出实例',
        fileName: '${instance.name}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null) return;

      NotificationManager().showInfo(
        '导出中',
        message: '正在导出实例 ${instance.name}...',
      );

      await InstanceManager().exportInstance(instance.id, result);

      if (!mounted) return;
      NotificationManager().showSuccess(
        '导出成功',
        message: '实例 ${instance.name} 已导出',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('导出失败', message: e.toString());
    }
  }

  void _openModManager(GameInstance instance) {
    BAModManagerDialog.show(
      context: context,
      instanceId: instance.id,
      instanceName: instance.name,
    );
  }

  Future<void> _importInstance() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final manager = InstanceManager();
      if (!manager.isInitialized || manager.directories.isEmpty) {
        if (!mounted) return;
        NotificationManager().showError('导入失败', message: '请先创建一个游戏目录');
        return;
      }

      final directoryId =
          manager.selectedDirectoryId ?? manager.directories.first.id;

      NotificationManager().showInfo('导入中', message: '正在导入实例...');

      await manager.importInstance(filePath, directoryId);

      if (!mounted) return;
      NotificationManager().showSuccess('导入成功', message: '实例已导入');
      _loadInstances();
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('导入失败', message: e.toString());
    }
  }

  void _openBackupManager(GameInstance instance) {
    BABackupDialog.show(context: context, instance: instance);
  }

  void _openInstanceFolder(GameInstance instance) {
    final manager = InstanceManager();
    final path = manager.getInstancePath(instance.id);
    _openFile(path);
  }

  void _openFile(String filePath) {
    try {
      Process.run('explorer', [filePath]);
    } on Exception catch (_) {
      if (mounted) {
        NotificationManager().showError('打开文件失败');
      }
    }
  }

  // ===== 世界列表加载 =====

  Future<void> _loadWorlds(GameInstance instance) async {
    if (mounted) setState(() => _isLoadingWorlds = true);
    try {
      final manager = InstanceManager();
      final savesPath = manager.getInstanceSavesPath(instance.id);
      final savesDir = Directory(savesPath);
      final worlds = <WorldInfo>[];

      if (savesDir.existsSync()) {
        final entries = savesDir.listSync().whereType<Directory>().toList()
          ..sort((a, b) {
            try {
              return b.statSync().modified.compareTo(a.statSync().modified);
            } catch (_) {
              return 0;
            }
          });

        for (final dir in entries) {
          final levelDat = File(
            '${dir.path}${Platform.pathSeparator}level.dat',
          );
          if (!levelDat.existsSync()) continue;

          final stat = dir.statSync();
          worlds.add(
            WorldInfo(
              name: dir.path.split(Platform.pathSeparator).last,
              subtitle: '',
              lastPlayed: _formatDateTime(stat.modified),
              iconFile: File('${dir.path}${Platform.pathSeparator}icon.png'),
              isRecent: false,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _worlds = worlds;
          _isLoadingWorlds = false;
        });
      }
    } catch (e) {
      Logger.instance.error('加载世界列表失败', e);
      if (mounted) {
        setState(() {
          _worlds = [];
          _isLoadingWorlds = false;
        });
      }
    }
  }

  // ===== 视觉/UI 方法 =====

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: _selectedInstance != null
          ? RepaintBoundary(
              key: const ValueKey('detail'),
              child: _buildDetailPage(context, _selectedInstance!),
            )
          : RepaintBoundary(
              key: const ValueKey('list'),
              child: _buildListContent(context),
            ),
    );
  }

  Widget _buildListContent(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 顶部自定义标题栏
            _buildHeader(context),
            const SizedBox(height: 16),

            // 统计卡片区
            GameLibraryStatsBar(
              totalPlayTime: _totalPlayTime,
              totalLaunchCount: _totalLaunchCount,
              todayPlayTime: _todayPlayTime,
            ),
            const SizedBox(height: 20),

            // 搜索和筛选区域
            GameLibrarySearchFilter(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedFilter: _selectedFilter,
              filters: _filters,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onFilterChanged: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // 实例列表
            Expanded(
              child: GameLibraryInstanceGrid(
                instances: _getFilteredInstances(),
                selectedInstanceId: _selectedInstance?.id,
                launchingIds: _launchingIds,
                searchQuery: _searchQuery,
                selectedFilter: _selectedFilter,
                statsManager: _statsManager,
                onSelectInstance: _selectInstance,
                onLaunchGame: _launchGame,
                onDuplicateInstance: _duplicateInstance,
                onExportInstance: _exportInstance,
                onOpenBackupManager: _openBackupManager,
                onOpenModManager: _openModManager,
                onDeleteInstance: _deleteInstance,
              ),
            ),

            // 底部操作区
            _buildBottomActions(context),
          ],
        ),

        // 浮动按钮
        Positioned(
          right: 32,
          bottom: 32,
          child: GameLibraryFloatingButton(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const BACreateInstanceDialog(),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 顶部自定义标题栏 - BakaXL 风格
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧标题：图标 + 标题
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(context)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gamepad_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '游戏库',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),

          // 目录选择器
          BADirectorySelector(
            width: 200,
            onChanged: () {
              _loadInstances();
              _loadStatistics();
            },
          ),
          const SizedBox(width: 10),

          // 右侧：刷新按钮
          _buildHeaderRefreshButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderRefreshButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _loadInstances();
          _loadStatistics();
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: BAColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.refresh_rounded,
            color: BAColors.primaryLightOf(context),
            size: 18,
          ),
        ),
      ),
    );
  }

  /// 底部操作区
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: _importInstance,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_rounded,
                    color: BAColors.primaryLightOf(context)
                        .withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '导入实例',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context)
                          .withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 实例详情页 UI =====

  Widget _buildDetailPage(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);

    return Column(
      children: [
        // 顶部最小化的返回 + 标题栏
        GameLibraryDetailHeader(
          instance: instance,
          isRunning: isRunning,
          isLaunching: isLaunching,
          onBack: _backToList,
          onLaunchGame: () => _launchGame(instance),
        ),
        // 两栏布局
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧固定信息面板
              SizedBox(
                width: 280,
                child: GameLibraryDetailSidebar(
                  instance: instance,
                  isRunning: isRunning,
                  isLaunching: isLaunching,
                  statsManager: _statsManager,
                  onLaunchGame: () => _launchGame(instance),
                  onOpenInstanceFolder: () =>
                      _openInstanceFolder(instance),
                  onOpenBackupManager: () =>
                      _openBackupManager(instance),
                  onOpenModManager: () => _openModManager(instance),
                  onDuplicateInstance: () =>
                      _duplicateInstance(instance),
                  onExportInstance: () => _exportInstance(instance),
                  onDeleteInstance: () => _deleteInstance(instance),
                ),
              ),
              // 中间分隔线
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 16),
                color: BAColors.borderOf(context).withValues(alpha: 0.4),
              ),
              // 右侧 Tab 区域
              Expanded(
                child: Column(
                  children: [
                    // Tab 栏
                    GameLibraryDetailTabBar(
                      controller: _detailTabController!,
                      tabs: _detailTabs,
                      icons: _detailTabIcons,
                    ),
                    // Tab 内容独立滚动
                    Expanded(
                      child: TabBarView(
                        controller: _detailTabController,
                        children: [
                          _buildOverviewTab(context, instance),
                          _buildFileListTab(
                            context,
                            '还没有存档',
                            Icons.folder_rounded,
                          ),
                          _buildFileListTab(
                            context,
                            '还没有模组',
                            Icons.extension_rounded,
                          ),
                          _buildFileListTab(
                            context,
                            '还没有资源包',
                            Icons.palette_rounded,
                          ),
                          _buildFileListTab(
                            context,
                            '还没有光影包',
                            Icons.brightness_7_rounded,
                          ),
                          _buildScreenshotTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 概览Tab
  Widget _buildOverviewTab(BuildContext context, GameInstance instance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingWorlds) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final recentWorlds =
        _worlds.isNotEmpty ? [_worlds.first] : <WorldInfo>[];
    final allWorlds = _worlds;

    if (_worlds.isEmpty) {
      return const GameLibraryEmptyState(
        icon: Icons.public_rounded,
        message: '还没有世界',
        subMessage: '在游戏中创建世界后将在此显示',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorldSection(
            context,
            title: '最近游玩的世界',
            worlds: recentWorlds,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildWorldSection(
            context,
            title: '全部世界',
            worlds: allWorlds,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWorldSection(
    BuildContext context, {
    required String title,
    required List<WorldInfo> worlds,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
        ),
        if (worlds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 12,
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          )
        else
          ...worlds.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildWorldListItem(context, w, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildWorldListItem(
      BuildContext context, WorldInfo w, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildWorldIcon(context, w),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      w.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (w.subtitle.isNotEmpty)
                      Flexible(
                        child: Text(
                          w.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: BAColors.textSecondaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                if (w.isRecent && w.lastPlayed.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 11,
                        color: BAColors.primaryLightOf(context),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '启动此世界',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BAColors.primaryLightOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        w.lastPlayed,
                        style: TextStyle(
                          fontSize: 11,
                          color: BAColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: BAColors.textSecondaryOf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldIcon(BuildContext context, WorldInfo w) {
    const size = 40.0;
    final hasIcon = w.iconFile != null && w.iconFile!.existsSync();

    if (hasIcon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          w.iconFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildWorldFallbackIcon(context),
        ),
      );
    }
    return _buildWorldFallbackIcon(context);
  }

  Widget _buildWorldFallbackIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BAColors.primaryLightOf(context).withValues(alpha: 0.3),
            BAColors.primaryOf(context).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BAColors.primaryOf(context).withValues(alpha: 0.25),
        ),
      ),
      child: Icon(
        Icons.public_rounded,
        size: 18,
        color: BAColors.primaryLightOf(context),
      ),
    );
  }

  /// 文件列表Tab（存档/模组/资源包/光影）
  Widget _buildFileListTab(
    BuildContext context,
    String emptyMessage,
    IconData emptyIcon,
  ) {
    if (_isLoadingFiles) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            BAColors.primaryLightOf(context),
          ),
        ),
      );
    }

    if (_detailFiles.isEmpty) {
      return GameLibraryEmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subMessage: '将文件放入对应文件夹即可在此显示',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _detailFiles.length,
      itemBuilder: (context, index) {
        final entity = _detailFiles[index];
        return _buildFileItem(context, entity);
      },
    );
  }

  Widget _buildFileItem(BuildContext context, FileSystemEntity entity) {
    final isDir = entity is Directory;
    final name = entity.path.split(Platform.pathSeparator).last;

    int size = 0;
    DateTime? modified;
    try {
      final stat = entity.statSync();
      size = stat.size;
      modified = stat.modified;
    } catch (e, st) {
      Logger.instance.error('获取文件信息失败', e, st);
    }

    IconData fileIcon;
    if (isDir) {
      fileIcon = Icons.folder_rounded;
    } else if (name.endsWith('.jar')) {
      fileIcon = Icons.extension_rounded;
    } else if (name.endsWith('.zip')) {
      fileIcon = Icons.archive_rounded;
    } else if (name.endsWith('.png') || name.endsWith('.jpg')) {
      fileIcon = Icons.image_rounded;
    } else {
      fileIcon = Icons.insert_drive_file_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BAColors.primaryOf(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              fileIcon,
              color: isDir
                  ? BAColors.warningOf(context)
                  : BAColors.primaryLightOf(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${isDir ? '文件夹' : formatBytes(size)}${modified != null ? ' · ${_formatDateTime(modified)}' : ''}',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context)
                        .withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 截图Tab
  Widget _buildScreenshotTab(BuildContext context) {
    if (_isLoadingFiles) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            BAColors.primaryLightOf(context),
          ),
        ),
      );
    }

    final imageFiles = _detailFiles.where((f) {
      final name = f.path.toLowerCase();
      return name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg');
    }).toList();

    if (imageFiles.isEmpty) {
      return const GameLibraryEmptyState(
        icon: Icons.photo_camera_rounded,
        message: '还没有截图',
        subMessage: '在游戏中按下 F2 截图后将在此显示',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        final entity = imageFiles[index];
        if (entity is! File) return const SizedBox.shrink();
        final file = entity;
        final name = file.path.split(Platform.pathSeparator).last;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openFile(file.path),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.shadowOf(context).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: BAColors.surfaceOf(context),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: BAColors.textSecondaryOf(context),
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
