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
import '../components/ba_context_menu.dart';
import '../components/ba_buttons.dart';
import '../components/ba_create_instance_dialog.dart';
import '../components/ba_backup_dialog.dart';
import '../components/ba_mod_manager_dialog.dart';
import '../components/ba_directory_selector.dart';
import '../components/instance_tile.dart';
import '../components/settings_panel/widgets/settings_theme.dart';
import '../theme/colors.dart';
import '../animations/ba_animations.dart';
import '../../game/game_statistics.dart';

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
  static const List<String> _detailTabs = ['概览', '存档', '模组', '资源包', '光影', '截图'];
  List<FileSystemEntity> _detailFiles = [];
  bool _isLoadingFiles = false;

  final List<String> _filters = ['全部', '游戏中', '已安装', '可更新'];

  List<GameInstance> _instances = [];
  final List<EventSubscription> _subscriptions = [];
  final Set<String> _launchingIds = {};

  // 详情页世界列表（从 saves/ 目录真实解析，覆盖原硬编码占位数据）
  List<_WorldInfo> _worlds = [];
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

    // 只展示当前选中目录下的实例（切换目录时联动）
    final selectedDirId = manager.selectedDirectoryId;
    final all = List<GameInstance>.from(manager.instances);
    final newInstances = selectedDirId == null
        ? all
        : all.where((i) => i.directoryId == selectedDirId).toList();

    // 如果正在查看实例详情，检查实例是否还存在（且仍在当前目录）
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

    // 统计仅计算当前目录下实例（切换目录时联动）
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

  // ===== 视觉/UI 方法（以下可自由修改） =====

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
            _buildHeader(context),
            const SizedBox(height: 16),

            // 统计卡片区
            _buildStatsRow(context),
            const SizedBox(height: 20),

            // 搜索和筛选区域
            _buildSearchAndFilter(context),
            const SizedBox(height: 20),

            // 实例列表
            Expanded(child: _buildInstanceGrid(context)),

            // 底部操作区
            _buildBottomActions(context),
          ],
        ),

        // 浮动按钮
        Positioned(right: 32, bottom: 32, child: _buildFloatingButton(context)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours时$minutes分';
    } else {
      return '$minutes分';
    }
  }

  /// 根据 loader 推断实例类型
  ///
  /// loader 为空/未识别 → 原版（Vanilla）。
  /// 不同加载器使用不同中文展示名，避免将「实例名」误当类型展示。
  String _inferInstanceType(String? loader) {
    if (loader == null || loader.isEmpty) return '原版 (Vanilla)';
    switch (loader.toLowerCase()) {
      case 'forge':
        return 'Forge';
      case 'fabric':
        return 'Fabric';
      case 'quilt':
        return 'Quilt';
      case 'optifine':
        return 'OptiFine';
      case 'neoforge':
        return 'NeoForge';
      case 'liteloader':
        return 'LiteLoader';
      default:
        return loader; // 未知 loader 透传展示原始字符串
    }
  }

  /// 解析实例所属游戏目录的真实路径
  ///
  /// 通过 [InstanceManager] 查表得到 [InstanceDirectory.path]；
  /// 找不到时回退到 "未知目录" 而不是硬编码字符串，避免误导。
  String _resolveInstanceDirectoryPath(GameInstance instance) {
    final directory = InstanceManager().directories
        .where((d) => d.id == instance.directoryId)
        .firstOrNull;
    if (directory == null) return '未知目录';
    return directory.path;
  }

  /// 顶部自定义标题栏 - BakaXL 风格
  ///
  /// 视觉重心：左侧标题锚定 + 右侧操作按钮组。
  /// 冗余的"实例总数"统计已移除（与下方统计卡/列表标题重复）。
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
                      color: BAColors.primaryOf(
                        context,
                      ).withValues(alpha: 0.35),
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

          // 目录选择器（顶部下拉，PCL 风格但不照搬）
          BADirectorySelector(width: 200, onChanged: _onDirectoryChanged),
          const SizedBox(width: 10),

          // 右侧：操作按钮组（仅保留必要操作）
          _buildHeaderRefreshButton(context),
        ],
      ),
    );
  }

  /// 目录切换后回调：重新加载实例列表 + 统计
  void _onDirectoryChanged() {
    _loadInstances();
    _loadStatistics();
  }

  /// 顶部"刷新"图标按钮 - BakaXL 风格的圆角玻璃按钮
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

  /// 游戏统计信息条 - BakaXL 风格紧凑横排
  ///
  /// 把原先 3 个大卡片合并为 1 个毛玻璃信息条，
  /// 数据项之间用细分隔线区分，整体高度更低、信息密度更高。
  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatCell(
              context,
              label: '总游戏时长',
              value: _formatDuration(_totalPlayTime),
            ),
            _buildStatDivider(context),
            _buildStatCell(
              context,
              label: '总启动次数',
              value: '$_totalLaunchCount 次',
            ),
            _buildStatDivider(context),
            _buildStatCell(
              context,
              label: '今日游戏',
              value: _formatDuration(_todayPlayTime),
            ),
          ],
        ),
      ),
    );
  }

  /// 统计信息条中的单个数据单元（标签 + 数值，纵向排列）
  Widget _buildStatCell(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 统计信息条中的细分隔线
  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: BAColors.borderOf(context).withValues(alpha: 0.5),
    );
  }

  /// 搜索和筛选区域 - 毛玻璃风格
  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 搜索框 - 毛玻璃
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.shadowOf(context).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '搜索实例...',
                  hintStyle: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: BAColors.textSecondaryOf(context),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: BAColors.textSecondaryOf(context),
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 筛选按钮 - 毛玻璃
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  BAColors.primaryLightOf(context),
                                  BAColors.primaryOf(context),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : BAColors.surfaceOf(
                                context,
                              ).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : BAColors.borderOf(
                                  context,
                                ).withValues(alpha: 0.5),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: BAColors.primaryOf(
                                    context,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : BAColors.textSecondaryOf(context),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 实例网格
  Widget _buildInstanceGrid(BuildContext context) {
    final instances = _getFilteredInstances();

    if (instances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圆形卡片包裹图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BAColors.primaryLightOf(context),
                    BAColors.primaryOf(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedFilter != 0
                    ? Icons.search_off_rounded
                    : Icons.rocket_launch_rounded,
                size: 48,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 0
                  ? '没有找到匹配的实例'
                  : '还没有游戏实例',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 0
                  ? '尝试修改搜索条件或切换筛选项'
                  : '点击右下角按钮创建第一个实例',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: instances.length,
        itemBuilder: (context, index) {
          final instance = instances[index];
          return _buildInstanceCard(context, instance);
        },
      ),
    );
  }

  void _openBackupManager(GameInstance instance) {
    BABackupDialog.show(context: context, instance: instance);
  }

  /// 实例卡片 - BakaXL 排版风格（紧凑横向布局）
  Widget _buildInstanceCard(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);
    final instanceStats = _statsManager.getInstanceStatistics(instance.id);

    final status = isRunning
        ? InstanceTileStatus.running
        : (isLaunching
              ? InstanceTileStatus.launching
              : InstanceTileStatus.stopped);

    // 副标题拼接：version · loader · 游玩时长
    // 若拼接结果与标题完全一致（用户以版本号命名），则隐藏副标题避免重复
    final hasLoader = instance.loader != null && instance.loader!.isNotEmpty;
    final parts = <String>[
      if (instance.version.isNotEmpty) instance.version,
      if (hasLoader) instance.loader!,
      if (instanceStats != null)
        _formatDuration(Duration(seconds: instanceStats.totalPlayTimeSeconds)),
    ];
    final subtitle = parts.join(' · ');
    final showSubtitle = subtitle.isNotEmpty && subtitle != instance.name;

    return InstanceTile(
      name: instance.name,
      subtitle: showSubtitle ? subtitle : '',
      status: status,
      selected: _selectedInstance?.id == instance.id,
      onTap: () => _selectInstance(instance),
      contextMenuItems: [
        BAContextMenuItem(
          icon: Icons.play_arrow_rounded,
          label: '启动',
          onTap: () => _launchGame(instance),
        ),
        BAContextMenuItem(
          icon: Icons.copy_rounded,
          label: '复制',
          onTap: () => _duplicateInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.file_upload_rounded,
          label: '导出',
          onTap: () => _exportInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.backup_rounded,
          label: '备份管理',
          onTap: () => _openBackupManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.extension_rounded,
          label: '模组管理',
          onTap: () => _openModManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.delete_outline_rounded,
          label: '删除',
          danger: true,
          onTap: () => _deleteInstance(instance),
        ),
      ],
    );
  }

  /// 蔚蓝档案风格浮动按钮 - 呼吸灯效果
  Widget _buildFloatingButton(BuildContext context) {
    return BAAnimations.breathe(
      isActive: true,
      duration: const Duration(milliseconds: 2500),
      minOpacity: 0.85,
      maxOpacity: 1.0,
      glowRadius: 12.0,
      glowColor: BAColors.primaryLightOf(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const BACreateInstanceDialog(),
            );
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: BAColors.primaryLightOf(
                    context,
                  ).withValues(alpha: 0.2),
                  blurRadius: 48,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFFFFFFFF),
              size: 32,
            ),
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
          // 导入实例按钮
          InkWell(
            onTap: _importInstance,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    color: BAColors.primaryLightOf(
                      context,
                    ).withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '导入实例',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(
                        context,
                      ).withValues(alpha: 0.95),
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

  /// 详情页主布局 - BakaXL 两栏布局（左固定信息 / 右 Tab 独立滚动）
  Widget _buildDetailPage(BuildContext context, GameInstance instance) {
    return Column(
      children: [
        // 顶部最小化的返回 + 标题栏
        _buildDetailHeader(context, instance),
        // 两栏布局
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧固定信息面板（BakaXL 实例信息）
              SizedBox(
                width: 280,
                child: _buildInstanceSidebar(context, instance),
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
                    _buildDetailTabBar(context),
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

  /// 左侧固定信息面板 - BakaXL 实例信息风格
  Widget _buildInstanceSidebar(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);
    final instanceStats = _statsManager.getInstanceStatistics(instance.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: SettingsPalette.cardShadow(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              '实例信息',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SettingsPalette.textPrimary(context),
              ),
            ),
            const SizedBox(height: 14),

            // 图标
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRunning
                        ? [BAColors.successOf(context), BAColors.successDark]
                        : [
                            BAColors.primaryLightOf(context),
                            BAColors.primaryOf(context),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isRunning
                                  ? BAColors.successOf(context)
                                  : BAColors.primaryOf(context))
                              .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 实例名称
            Text(
              instance.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SettingsPalette.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${instance.version}${instance.loader != null && instance.loader!.isNotEmpty ? ' · ${instance.loader}' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: SettingsPalette.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            // 启动游戏按钮
            SizedBox(
              width: double.infinity,
              height: 40,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: (isRunning || isLaunching)
                      ? null
                      : () => _launchGame(instance),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRunning
                            ? [
                                BAColors.successOf(context),
                                BAColors.successDark,
                              ]
                            : isLaunching
                            ? [
                                BAColors.warningOf(context),
                                BAColors.warningDark,
                              ]
                            : [
                                BAColors.primaryLightOf(context),
                                BAColors.primaryOf(context),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isRunning
                                      ? BAColors.successOf(context)
                                      : isLaunching
                                      ? BAColors.warningOf(context)
                                      : BAColors.primaryOf(context))
                                  .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLaunching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRunning
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRunning
                                      ? '运行中'
                                      : (isLaunching ? '启动中' : '启动游戏'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 快捷操作
            Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildSidebarAction(
              context,
              icon: Icons.folder_open_rounded,
              label: '在文件管理器中打开',
              onTap: () => _openInstanceFolder(instance),
            ),
            _buildSidebarAction(
              context,
              icon: Icons.backup_rounded,
              label: '备份管理',
              onTap: () => _openBackupManager(instance),
            ),
            _buildSidebarAction(
              context,
              icon: Icons.extension_rounded,
              label: '模组管理',
              onTap: () => _openModManager(instance),
            ),
            _buildSidebarAction(
              context,
              icon: Icons.copy_rounded,
              label: '复制实例',
              onTap: () => _duplicateInstance(instance),
            ),
            _buildSidebarAction(
              context,
              icon: Icons.file_upload_rounded,
              label: '导出实例',
              onTap: () => _exportInstance(instance),
            ),

            const SizedBox(height: 18),

            // 游戏信息列表
            Text(
              '游戏信息',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildSidebarInfo(
              context,
              '核心',
              '${instance.version}${instance.loader != null ? ' · ${instance.loader}' : ''}',
            ),
            _buildSidebarInfo(
              context,
              '实例类型',
              _inferInstanceType(instance.loader),
            ),
            _buildSidebarInfo(
              context,
              '来源目录',
              _resolveInstanceDirectoryPath(instance),
            ),
            _buildSidebarInfo(
              context,
              '游玩时长',
              instanceStats != null
                  ? _formatDuration(
                      Duration(seconds: instanceStats.totalPlayTimeSeconds),
                    )
                  : '0分',
            ),
            _buildSidebarInfo(
              context,
              '最近游玩',
              _formatDateTime(
                instance.lastPlayed ?? instanceStats?.lastLaunchTime,
              ),
            ),

            // 危险区域
            const SizedBox(height: 14),
            _buildSidebarDanger(
              context,
              icon: Icons.delete_outline_rounded,
              label: '删除此实例',
              onTap: () => _deleteInstance(instance),
            ),
          ],
        ),
      ),
    );
  }

  /// 侧栏快捷操作项
  Widget _buildSidebarAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: SettingsPalette.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 侧栏信息行
  Widget _buildSidebarInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: SettingsPalette.textSecondary(context),
            height: 1.5,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: SettingsPalette.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 侧栏危险操作
  Widget _buildSidebarDanger(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: SettingsPalette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: SettingsPalette.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 详情页顶部栏 - BakaXL 风格
  ///
  /// 视觉重心：左导航 + 中标题 + 右主操作按钮（带文字，比单纯 icon 更突出）。
  /// 状态点紧贴实例名，让运行态/启动态一眼可见。
  Widget _buildDetailHeader(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);
    final statusLabel = isRunning ? '运行中' : (isLaunching ? '启动中' : '未启动');
    final statusColor = isRunning
        ? BAColors.successOf(context)
        : (isLaunching
              ? BAColors.warningOf(context)
              : BAColors.textDisabledOf(context));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 24, 8),
      child: Row(
        children: [
          // 返回按钮
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _backToList,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: BAColors.primaryLightOf(context),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 实例图标
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFFFFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 实例名称 + 状态点 + 副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // 状态点
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: isRunning || isLaunching
                            ? [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        instance.name,
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${instance.version}${instance.loader != null ? ' · ${instance.loader}' : ''}',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 主操作按钮（带文字，比单纯 icon 更突出）
          if (isLaunching)
            _buildDetailActionButton(
              context,
              icon: null,
              label: '启动中',
              showSpinner: true,
              onTap: null,
              gradient: [BAColors.warningOf(context), BAColors.warningDark],
            )
          else
            _buildDetailActionButton(
              context,
              icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: isRunning ? '停止' : '启动',
              showSpinner: false,
              onTap: isRunning ? null : () => _launchGame(instance),
              gradient: isRunning
                  ? [BAColors.successOf(context), BAColors.successDark]
                  : [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
            ),
        ],
      ),
    );
  }

  /// 详情页主操作按钮 - BakaXL 风格（圆角 + 渐变 + 文字 + icon）
  Widget _buildDetailActionButton(
    BuildContext context, {
    required IconData? icon,
    required String label,
    required bool showSpinner,
    required VoidCallback? onTap,
    required List<Color> gradient,
  }) {
    final disabled = onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? gradient.map((c) => c.withValues(alpha: 0.5)).toList()
                  : gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: gradient.last.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white, size: 16),
              if (showSpinner || icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 详情页子Tab栏 - BakaXL 风格（带 icon + 渐变选中态）
  ///
  /// 每个 Tab 配 14px icon 提升可读性；选中态保留渐变 + 阴影。
  /// 未选中态靠左对齐，hover 态由 Material InkWell 提供微妙水波。
  Widget _buildDetailTabBar(BuildContext context) {
    final icons = <IconData>[
      Icons.dashboard_rounded, // 概览
      Icons.folder_rounded, // 存档
      Icons.extension_rounded, // 模组
      Icons.palette_rounded, // 资源包
      Icons.brightness_7_rounded, // 光影
      Icons.photo_camera_rounded, // 截图
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: _detailTabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFFFFFFFF),
        unselectedLabelColor: BAColors.textSecondaryOf(
          context,
        ).withValues(alpha: 0.85),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BAColors.primaryLightOf(context),
              BAColors.primaryOf(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: BAColors.primaryOf(context).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(10),
        tabs: List.generate(_detailTabs.length, (i) {
          return Tab(
            height: 34,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], size: 14),
                const SizedBox(width: 6),
                Text(_detailTabs[i]),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 概览Tab - BakaXL 风格的"最近游玩的世界 + 全部世界"列表
  ///
  /// 数据来源：真实扫描 `saves/` 目录，按目录 mtime 倒序排列；
  /// 最近游玩 = 第一个；其余归入全部世界。
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

    // 按"最近游玩 = mtime 最新"区分第一项
    final recentWorlds = _worlds.isNotEmpty ? [_worlds.first] : <_WorldInfo>[];
    final allWorlds = _worlds;

    if (_worlds.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.public_rounded,
        '还没有世界',
        '在游戏中创建世界后将在此显示',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 最近游玩的世界
          _buildWorldSection(
            context,
            title: '最近游玩的世界',
            worlds: recentWorlds,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // 全部世界
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

  /// 扫描实例 saves 目录，加载真实世界列表
  ///
  /// 简化版解析：
  /// - 每个子目录视为一个世界（包含 level.dat 的才算有效，否则降级为目录）
  /// - mtime 倒序作为"最近游玩"参考
  /// - 若 `world/icon.png` 存在则作为图标
  /// - level.dat 的 NBT 解析不实现（避免引入额外依赖），
  ///   "第 X 天 / 模式"信息先用空串占位，后续可补 NBT 解析
  Future<void> _loadWorlds(GameInstance instance) async {
    if (mounted) setState(() => _isLoadingWorlds = true);
    try {
      final manager = InstanceManager();
      final savesPath = manager.getInstanceSavesPath(instance.id);
      final savesDir = Directory(savesPath);
      final worlds = <_WorldInfo>[];

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
          if (!levelDat.existsSync()) continue; // 跳过非世界目录

          final stat = dir.statSync();
          worlds.add(
            _WorldInfo(
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

  /// 世界列表分组
  Widget _buildWorldSection(
    BuildContext context, {
    required String title,
    required List<_WorldInfo> worlds,
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
              color: SettingsPalette.textPrimary(context),
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
                color: SettingsPalette.textHint(context),
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

  /// 世界列表项 - BakaXL 排版
  Widget _buildWorldListItem(BuildContext context, _WorldInfo w, bool isDark) {
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
          // 世界图标：优先用 <world>/icon.png，否则回退到渐变 + 默认 icon
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
                        color: SettingsPalette.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (w.subtitle.isNotEmpty)
                      Flexible(
                        child: Text(
                          w.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: SettingsPalette.textSecondary(context),
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
                        color: SettingsPalette.accent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '启动此世界',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SettingsPalette.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        w.lastPlayed,
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
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
            color: SettingsPalette.textHint(context),
          ),
        ],
      ),
    );
  }

  /// 世界图标：优先读取 `world/icon.png`，否则用渐变 + 默认地球图标
  Widget _buildWorldIcon(BuildContext context, _WorldInfo w) {
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
      return _buildEmptyState(
        context,
        emptyIcon,
        emptyMessage,
        '将文件放入对应文件夹即可在此显示',
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

  /// 文件列表项
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
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.8),
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
      return _buildEmptyState(
        context,
        Icons.photo_camera_rounded,
        '还没有截图',
        '在游戏中按下 F2 截图后将在此显示',
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
                  // 底部渐变遮罩 + 文件名
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

  /// 空状态组件
  /// 通用空状态 - BakaXL 风格
  ///
  /// 视觉要点：渐变圆 + 副色"虚线圈"装饰 + 主副文案。
  /// 整体尺寸较克制（图标 56px），避免大块渐变抢戏。
  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String message,
    String subMessage,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 双层圆：外圈虚线，内圈实心渐变
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BAColors.primaryOf(
                        context,
                      ).withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BAColors.primaryLightOf(context).withValues(alpha: 0.9),
                        BAColors.primaryOf(context).withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BAColors.primaryOf(
                          context,
                        ).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 28, color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subMessage,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 打开文件（使用系统默认程序）
  void _openFile(String filePath) {
    try {
      Process.run('explorer', [filePath]);
    } on Exception catch (_) {
      if (mounted) {
        NotificationManager().showError('打开文件失败');
      }
    }
  }

  /// 打开实例文件夹
  void _openInstanceFolder(GameInstance instance) {
    final manager = InstanceManager();
    final path = manager.getInstancePath(instance.id);
    _openFile(path);
  }
}

/// 世界信息（用于概览Tab的世界列表）
///
/// 数据源：实例 saves/ 目录的子文件夹（必须含 level.dat 才视为有效世界）。
/// `iconFile` 指向 `<world>/icon.png`（若存在），否则渲染回退图标。
class _WorldInfo {
  final String name;
  final String subtitle;
  final String lastPlayed;
  final File? iconFile;
  final bool isRecent;

  _WorldInfo({
    required this.name,
    this.subtitle = '',
    this.lastPlayed = '',
    this.iconFile,
    this.isRecent = false,
  });
}
