import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';

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
import '../../game/game_statistics.dart';

/// 蔚蓝档案风格游戏库页面 - 模仿蔚蓝档案的"学生"列表风格
class BAGameLibraryPage extends StatefulWidget {
  const BAGameLibraryPage({super.key});

  @override
  State<BAGameLibraryPage> createState() => _BAGameLibraryPageState();
}

class _BAGameLibraryPageState extends State<BAGameLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;
  bool _isMaximized = false;

  final List<String> _filters = ['全部', '游戏中', '已安装', '可更新'];

  List<GameInstance> _instances = [];
  final List<EventSubscription> _subscriptions = [];
  final Set<String> _launchingIds = {};

  // 游戏统计
  final GameStatisticsManager _statsManager = GameStatisticsManager.instance;
  Duration _totalPlayTime = Duration.zero;
  int _totalLaunchCount = 0;
  Duration _todayPlayTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _initializeAndLoadInstances();
    _subscribeToEvents();
  }

  Future<void> _initWindow() async {
    if (Platform.isWindows || Platform.isMacOS) {
      final isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = isMaximized;
        });
      }
    }
  }

  Future<void> _initializeAndLoadInstances() async {
    final manager = InstanceManager();
    if (!manager.isInitialized) {
      await manager.initialize();
    }

    // 初始化游戏统计
    await _statsManager.initialize();

    _loadInstances();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final sub in _subscriptions) {
      sub.unsubscribe();
    }
    super.dispose();
  }

  void _loadInstances() {
    final manager = InstanceManager();
    if (!manager.isInitialized) return;
    if (!mounted) return;
    setState(() {
      _instances = List.from(manager.instances);
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
    _subscriptions.add(
      bus.on<InstanceCreatedEvent>((_) => _loadInstances()),
    );
    _subscriptions.add(
      bus.on<InstanceDeletedEvent>((_) => _loadInstances()),
    );
    _subscriptions.add(
      bus.on<InstanceUpdatedEvent>((_) => _loadInstances()),
    );
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
      case 3:
        list = [];
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
      final javaPath = instance.config.javaPath ??
          config.get<String>(ConfigKeys.javaPath) ??
          'java';
      final memory = instance.config.maxMemory ??
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
    final nameController = TextEditingController(
      text: '${instance.name} - 副本',
    );

    try {
      final newName = await BAFrostedDialog.show<String>(
        context: context,
        title: '复制实例',
        child: TextField(
          controller: nameController,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
          decoration: InputDecoration(
            hintText: '请输入新实例名称',
            hintStyle: const TextStyle(color: Color(0xFFA0B0C8)),
            filled: true,
            fillColor: const Color(0xFF1E2747),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3A4D7A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8EAAFF)),
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
      NotificationManager().showSuccess(
        '复制成功',
        message: '实例 $newName 已创建',
      );
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
        NotificationManager().showError(
          '导入失败',
          message: '请先创建一个游戏目录',
        );
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
    NotificationManager().init(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF141C33),
            Color(0xFF0A0F1E),
          ],
        ),
      ),
      child: Stack(
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
              Expanded(
                child: _buildInstanceGrid(context),
              ),

              // 底部操作区
              _buildBottomActions(context),
            ],
          ),

          // 浮动按钮
          Positioned(
            right: 32,
            bottom: 32,
            child: _buildFloatingButton(context),
          ),
        ],
      ),
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

  /// 顶部自定义标题栏 - 蔚蓝档案风格
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
      child: Row(
        children: [
          // 左侧返回按钮
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2747).withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3A4D7A).withOpacity(0.5),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  EventBus.instance.publish(NavigateHomeEvent());
                },
                borderRadius: BorderRadius.circular(14),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 中间：图标 + 标题 + 副标题
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B8EFF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gamepad,
                  color: Color(0xFFFFFFFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '游戏库',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '管理你的 Minecraft 实例',
                    style: TextStyle(
                      color: const Color(0xFFA0B0C8).withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // 右侧：实例总数统计
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2747).withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3A4D7A).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: Color(0xFFFFFFFF),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_instances.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '个实例',
                  style: TextStyle(
                    color: const Color(0xFFA0B0C8).withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 操作按钮：刷新
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2747).withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3A4D7A).withOpacity(0.5),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _loadInstances();
                  _loadStatistics();
                },
                borderRadius: BorderRadius.circular(14),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF8EAAFF),
                  size: 20,
                ),
              ),
            ),
          ),
          if (Platform.isWindows) ...[
            const SizedBox(width: 4),
            _WindowButton(
              icon: Icons.remove,
              onTap: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
              onTap: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: Icons.close,
              onTap: () => windowManager.close(),
              isClose: true,
            ),
          ],
        ],
      ),
    );
  }

  // 窗口控制按钮组件
  class _WindowButton extends StatefulWidget {
    final IconData icon;
    final VoidCallback onTap;
    final bool isClose;

    const _WindowButton({
      required this.icon,
      required this.onTap,
      this.isClose = false,
    });

    @override
    State<_WindowButton> createState() => _WindowButtonState();
  }

  class _WindowButtonState extends State<_WindowButton> {
    bool _isHovered = false;

    @override
    Widget build(BuildContext context) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isClose
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2A3A5C))
                  : const Color(0xFF1E2747),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF3A4D7A),
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered && widget.isClose
                  ? Colors.white
                  : const Color(0xFFB8C5E0),
              size: 16,
            ),
          ),
        ),
      );
    }
  }

  /// 游戏统计卡片行
  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.access_time,
            label: '总游戏时长',
            value: _formatDuration(_totalPlayTime),
            accent: const Color(0xFF8EAAFF),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.casino,
            label: '总启动次数',
            value: '$_totalLaunchCount 次',
            accent: const Color(0xFF6B8EFF),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.calendar_today,
            label: '今日游戏',
            value: _formatDuration(_todayPlayTime),
            accent: const Color(0xFF3A4D7A),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2747).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3A4D7A).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.3), accent.withOpacity(0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withOpacity(0.4),
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFFFFFF),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFFA0B0C8).withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                color: const Color(0xFF1E2747).withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3A4D7A).withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A0F1E).withOpacity(0.3),
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
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '搜索实例...',
                  hintStyle: TextStyle(
                    color: const Color(0xFFA0B0C8).withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFA0B0C8),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Color(0xFFA0B0C8),
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
                            ? const LinearGradient(
                                colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : const Color(0xFF1E2747).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFF3A4D7A).withOpacity(0.5),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6B8EFF).withOpacity(0.4),
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
                              : const Color(0xFFA0B0C8),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B8EFF).withOpacity(0.4),
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
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
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
                color: const Color(0xFFA0B0C8).withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: instances.length,
        itemBuilder: (context, index) {
          final instance = instances[index];
          return _buildInstanceCard(context, instance);
        },
      ),
    );
  }

  void _openBackupManager(GameInstance instance) {
    BABackupDialog.show(
      context: context,
      instance: instance,
    );
  }

  /// 实例卡片
  Widget _buildInstanceCard(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);
    final instanceStats = _statsManager.getInstanceStatistics(instance.id);

    return BAContextMenu(
      items: [
        BAContextMenuItem(
          icon: Icons.play_arrow,
          label: '启动',
          onTap: () => _launchGame(instance),
        ),
        BAContextMenuItem(
          icon: Icons.copy,
          label: '复制',
          onTap: () => _duplicateInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.file_upload,
          label: '导出',
          onTap: () => _exportInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.backup,
          label: '备份管理',
          onTap: () => _openBackupManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.extension,
          label: '模组管理',
          onTap: () => _openModManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.delete,
          label: '删除',
          danger: true,
          onTap: () => _deleteInstance(instance),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2747).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRunning
                  ? const Color(0xFF6BFFA7).withOpacity(0.6)
                  : const Color(0xFF3A4D7A).withOpacity(0.5),
              width: isRunning ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isRunning
                    ? const Color(0xFF6BFFA7).withOpacity(0.15)
                    : const Color(0xFF0A0F1E).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isRunning || isLaunching
                  ? null
                  : () => _launchGame(instance),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部状态和图标
                    Row(
                      children: [
                        // 状态指示器
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? const Color(0xFF6BFFA7)
                                : (isLaunching
                                    ? const Color(0xFFFFD36B)
                                    : const Color(0xFF8EAAFF)),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRunning
                                        ? const Color(0xFF6BFFA7)
                                        : const Color(0xFF8EAAFF))
                                    .withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRunning
                              ? '运行中'
                              : (isLaunching ? '启动中' : '就绪'),
                          style: TextStyle(
                            color: isRunning
                                ? const Color(0xFF6BFFA7)
                                : (isLaunching
                                    ? const Color(0xFFFFD36B)
                                    : const Color(0xFFA0B0C8)),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // 操作按钮
                        if (isLaunching)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFD36B),
                              ),
                            ),
                          )
                        else
                          Icon(
                            isRunning ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded,
                            color: isRunning
                                ? const Color(0xFF6BFFA7)
                                : const Color(0xFF8EAAFF),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 实例图标
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRunning
                              ? [
                                  const Color(0xFF6BFFA7),
                                  const Color(0xFF3FB379)
                                ]
                              : [
                                  const Color(0xFF8EAAFF),
                                  const Color(0xFF6B8EFF)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isRunning
                                    ? const Color(0xFF6BFFA7)
                                    : const Color(0xFF6B8EFF))
                                .withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFFFFFFFF),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 实例名称
                    Text(
                      instance.name,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 版本信息
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8EFF).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6B8EFF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        instance.version,
                        style: const TextStyle(
                          color: Color(0xFF8EAAFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 加载器信息
                    if (instance.loader != null)
                      Text(
                        instance.loader!,
                        style: TextStyle(
                          color: const Color(0xFFA0B0C8).withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    if (instanceStats != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: const Color(0xFFA0B0C8).withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatDuration(Duration(seconds: instanceStats.totalPlayTimeSeconds))} / ${instanceStats.launchCount}次',
                              style: TextStyle(
                                color: const Color(0xFFA0B0C8).withOpacity(0.8),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 蔚蓝档案风格浮动按钮
  Widget _buildFloatingButton(BuildContext context) {
    return MouseRegion(
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
            gradient: const LinearGradient(
              colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B8EFF).withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF8EAAFF).withOpacity(0.2),
                blurRadius: 48,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFFFFF).withOpacity(0.2),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2747).withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3A4D7A).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_rounded,
                    color: const Color(0xFF8EAAFF).withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '导入实例',
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF).withOpacity(0.95),
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
}
