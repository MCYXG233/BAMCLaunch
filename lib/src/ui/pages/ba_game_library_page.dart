import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../account/account_manager.dart';
import '../../config/config_keys.dart';
import '../../config/config_manager.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../game/game_statistics.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../components/ba_backup_dialog.dart';
import '../components/ba_dialog.dart';
import '../components/ba_buttons.dart';
import '../components/ba_mod_manager_dialog.dart';
import '../components/ba_notification.dart';
import '../theme/colors.dart';
import 'game_library/detail/instance_detail_page.dart';
import 'game_library/widgets/library_bottom_actions.dart';
import 'game_library/widgets/library_floating_button.dart';
import 'game_library/widgets/library_header.dart';
import 'game_library/widgets/instance_grid.dart';
import 'game_library/widgets/search_filter_bar.dart';

/// 蔚蓝档案风格游戏库页面 - 模仿蔚蓝档案的"学生"列表风格
///
/// 主入口,负责:
/// - 持有列表/详情页共享状态(实例列表、统计、启动中ID、hover ID)
/// - 编排业务方法(启动/删除/复制/导出/导入)
/// - 在列表视图与详情视图之间切换
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
  static const List<String> _detailTabs = ['概览', '存档', '模组', '资源包', '光影', '截图'];
  List<FileSystemEntity> _detailFiles = [];
  bool _isLoadingFiles = false;

  final List<String> _filters = ['全部', '游戏中', '已安装', '可更新'];

  List<GameInstance> _instances = [];
  final List<EventSubscription> _subscriptions = [];
  final Set<String> _launchingIds = {};
  final Set<String> _hoveredInstanceIds = {};

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
    // 将 NotificationManager 初始化移到依赖变化时,避免 build 中重复调用
    NotificationManager().init(context);
  }

  Future<void> _initializeAndLoadInstances() async {
    try {
      final manager = InstanceManager();
      if (!manager.isInitialized) {
        await manager.initialize();
      }

      // 初始化游戏统计
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

    final newInstances = List<GameInstance>.from(manager.instances);

    // 如果正在查看实例详情，检查实例是否还存在
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
    setState(() {
      _totalPlayTime = _statsManager.getTotalPlayTime();
      _totalLaunchCount = _statsManager.getTotalLaunchCount();
      _todayPlayTime = _statsManager.getTodayPlayTime();
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
    });
    _loadDetailFiles(0);
  }

  void _backToList() {
    setState(() {
      _selectedInstance = null;
      _detailTabController?.dispose();
      _detailTabController = null;
      _detailFiles = [];
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

    // 概览tab不需要文件列表
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
        list = list.where((i) => i.version != null).toList();
        break;
      case 3:
        // 集合包: 包含 mod loader 的实例视为 modpack 实例
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

  // ===== 实例业务操作 =====

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

      // 开始游戏会话记录
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
      // 失败时也结束会话
      await _statsManager.endSession();
      if (!mounted) return;
      NotificationManager().showError('启动失败', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => _launchingIds.remove(instance.id));
        _loadStatistics(); // 更新统计信息
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
                color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              ),
              filled: true,
              fillColor: BAColors.surfaceOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BAColors.primaryLightOf(context)),
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

  void _openBackupManager(GameInstance instance) {
    BABackupDialog.show(context: context, instance: instance);
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

  void _openFile(String filePath) {
    try {
      Process.run('explorer', [filePath]);
    } on Exception catch (_) {
      if (mounted) {
        NotificationManager().showError('打开文件失败');
      }
    }
  }

  void _onHoverChange(GameInstance instance, bool isEntering) {
    if (!mounted) return;
    setState(() {
      if (isEntering) {
        _hoveredInstanceIds.add(instance.id);
      } else {
        _hoveredInstanceIds.remove(instance.id);
      }
    });
  }

  // ===== 视图组合 =====

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
            position:
                Tween<Offset>(
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
            LibraryHeader(
              instanceCount: _instances.length,
              onRefresh: () {
                _loadInstances();
                _loadStatistics();
              },
            ),
            const SizedBox(height: 16),

            // 统计卡片区
            LibraryStatsRow(
              totalPlayTime: _totalPlayTime,
              totalLaunchCount: _totalLaunchCount,
              todayPlayTime: _todayPlayTime,
            ),
            const SizedBox(height: 20),

            // 搜索和筛选区域
            SearchFilterBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              filters: _filters,
              selectedFilter: _selectedFilter,
              onSearchChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSearchCleared: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onFilterSelected: (index) {
                setState(() => _selectedFilter = index);
              },
            ),
            const SizedBox(height: 20),

            // 实例列表
            Expanded(
              child: InstanceGrid(
                instances: _getFilteredInstances(),
                searchQuery: _searchQuery,
                selectedFilter: _selectedFilter,
                launchingIds: _launchingIds,
                hoveredInstanceIds: _hoveredInstanceIds,
                onHoverChange: _onHoverChange,
                onSelect: _selectInstance,
                onLaunch: _launchGame,
                onDuplicate: _duplicateInstance,
                onExport: _exportInstance,
                onOpenBackupManager: _openBackupManager,
                onOpenModManager: _openModManager,
                onDelete: _deleteInstance,
              ),
            ),

            // 底部操作区
            LibraryBottomActions(onImport: _importInstance),
          ],
        ),

        // 浮动按钮
        const Positioned(right: 32, bottom: 32, child: LibraryFloatingButton()),
      ],
    );
  }

  Widget _buildDetailPage(BuildContext context, GameInstance instance) {
    return InstanceDetailPage(
      instance: instance,
      detailTabController: _detailTabController!,
      detailTabs: _detailTabs,
      launchingIds: _launchingIds,
      isLoadingFiles: _isLoadingFiles,
      detailFiles: _detailFiles,
      onBack: _backToList,
      onLaunch: _launchGame,
      onDuplicate: _duplicateInstance,
      onExport: _exportInstance,
      onOpenBackupManager: _openBackupManager,
      onOpenModManager: _openModManager,
      onDelete: _deleteInstance,
      onOpenFile: _openFile,
    );
  }
}
