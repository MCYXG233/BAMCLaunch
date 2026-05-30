import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/colors.dart';
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
import 'ba_mod_manager_page.dart';

/// 蔚蓝档案风格游戏库页面
class BAGameLibraryPage extends StatefulWidget {
  const BAGameLibraryPage({super.key});

  @override
  State<BAGameLibraryPage> createState() => _BAGameLibraryPageState();
}

class _BAGameLibraryPageState extends State<BAGameLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;

  final List<String> _filters = ['全部', '游戏中', '已安装', '可更新'];

  List<GameInstance> _instances = [];
  final List<EventSubscription> _subscriptions = [];
  final Set<String> _launchingIds = {};

  @override
  void initState() {
    super.initState();
    _initializeAndLoadInstances();
    _subscribeToEvents();
  }

  Future<void> _initializeAndLoadInstances() async {
    final manager = InstanceManager();
    if (!manager.isInitialized) {
      await manager.initialize();
    }
    _loadInstances();
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

      await GameLauncher().launch(args);

      if (!mounted) return;
      NotificationManager().showSuccess(
        '启动成功',
        message: '正在启动 ${instance.name}...',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('启动失败', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => _launchingIds.remove(instance.id));
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
          style: TextStyle(color: BAColors.textPrimaryOf(context)),
          decoration: InputDecoration(
            hintText: '请输入新实例名称',
            hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
            filled: true,
            fillColor: BAColors.surfaceOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BAColors.primaryOf(context)),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BAModManagerPage(instanceId: instance.id),
      ),
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

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Container(
      decoration: BoxDecoration(
        gradient: BAColors.backgroundGradientOf(context),
      ),
      child: Column(
        children: [
          // 顶部状态栏
          _buildHeader(context),
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
    );
  }

  /// 顶部标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: BAColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gamepad,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '游戏库',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // 统计信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder,
                  color: BAColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_instances.length}',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' 个实例',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索和筛选区域
  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: BAColors.glassOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withOpacity(0.6),
                ),
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
                    color: BAColors.textDisabledOf(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: BAColors.textSecondaryOf(context),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
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

          // 筛选按钮
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                          gradient: isSelected ? BAColors.primaryGradient : null,
                          color: isSelected
                              ? null
                              : BAColors.surfaceOf(context).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : BAColors.borderOf(context).withOpacity(0.6),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: BAColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : BAColors.textSecondaryOf(context),
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: BAColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BAColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedFilter != 0
                    ? Icons.search_off_rounded
                    : Icons.rocket_launch_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 0
                  ? '尝试修改搜索条件或切换筛选项'
                  : '还没有游戏实例，点击下方按钮开始创建',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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

  /// 实例卡片
  Widget _buildInstanceCard(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = _launchingIds.contains(instance.id);

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
            color: BAColors.glassOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRunning
                  ? BAColors.success.withOpacity(0.6)
                  : BAColors.borderOf(context).withOpacity(0.5),
              width: isRunning ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isRunning
                    ? BAColors.success.withOpacity(0.2)
                    : BAColors.shadowOf(context),
                blurRadius: 12,
                offset: Offset(0, 4),
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
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? BAColors.success
                                : (isLaunching
                                    ? BAColors.warning
                                    : BAColors.primary),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRunning
                                        ? BAColors.success
                                        : BAColors.primary)
                                    .withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // 操作按钮
                        if (isLaunching)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                BAColors.warning,
                              ),
                            ),
                          )
                        else
                          Icon(
                            isRunning ? Icons.stop : Icons.play_arrow,
                            color: isRunning
                                ? BAColors.success
                                : BAColors.primary,
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
                        gradient: isRunning
                            ? BAColors.successGradient
                            : BAColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isRunning
                                    ? BAColors.success
                                    : BAColors.primary)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.grass,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const Spacer(),

                    // 实例名称
                    Text(
                      instance.name,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 版本信息
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BAColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        instance.version,
                        style: TextStyle(
                          color: BAColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 加载器信息
                    if (instance.loader != null)
                      Text(
                        instance.loader!,
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 底部操作区
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.glassOf(context),
        border: Border(
          top: BorderSide(
            color: BAColors.borderOf(context).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 创建实例按钮
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const BACreateInstanceDialog(),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withOpacity(0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: BAColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '新建实例',
                    style: TextStyle(
                      color: BAColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 导入实例按钮
          InkWell(
            onTap: _importInstance,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withOpacity(0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload,
                    color: BAColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '导入实例',
                    style: TextStyle(
                      color: BAColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
