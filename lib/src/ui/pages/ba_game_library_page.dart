import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/colors.dart';
import '../theme/app_theme.dart';
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
        message: '实例 ${instance.name} 已启动',
      );
      _loadInstances();
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
              borderRadius: BATheme.borderRadiusMedium,
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusMedium,
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusMedium,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightBackground : BAColors.darkBackground;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;
    final textDisabled = isLight ? BAColors.lightTextDisabled : BAColors.darkTextDisabled;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context, textPrimary),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                      boxShadow: BATheme.shadowsSmallOf(context),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索实例...',
                        hintStyle: TextStyle(
                          color: textDisabled,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: textSecondary,
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ...List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BAColors.primaryOf(context)
                                : cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? BAColors.primaryOf(context)
                                  : cardBorder,
                            ),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : textSecondary,
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildInstanceGrid(context),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textPrimary) {
    return Row(
      children: [
        Text(
          '游戏库',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _ActionButton(
          icon: Icons.refresh,
          label: '刷新',
          onTap: _loadInstances,
          buttonContext: context,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.sort,
          label: '排序',
          onTap: () {},
          buttonContext: context,
        ),
      ],
    );
  }

  Widget _buildInstanceGrid(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;
    final instances = _getFilteredInstances();

    if (instances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: BAColors.primaryOf(context).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedFilter != 0
                    ? Icons.search_off_rounded
                    : Icons.rocket_launch_rounded,
                size: 48,
                color: BAColors.primaryOf(context).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 0
                  ? '没有找到匹配的实例'
                  : '还没有游戏实例',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 0
                  ? '尝试修改搜索条件或切换筛选项'
                  : '还没有游戏实例，点击新建实例开始吧',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: GridView.builder(
        key: ValueKey('${_searchQuery}_$_selectedFilter'),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: instances.length,
        itemBuilder: (context, index) {
          final instance = instances[index];
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
              const BAContextMenuDivider(),
              BAContextMenuItem(
                icon: Icons.delete_outline,
                label: '删除',
                danger: true,
                onTap: () => _deleteInstance(instance),
              ),
            ],
            child: _InstanceCard(
              instance: instance,
              isLaunching: _launchingIds.contains(instance.id),
              onLaunch: () => _launchGame(instance),
              cardContext: context,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              children: [
                _MainActionButton(
                  icon: Icons.add,
                  label: '创建实例',
                  gradient: BAColors.primaryGradient as LinearGradient,
                  onTap: () => BACreateInstanceDialog.show(context),
                ),
                const SizedBox(height: 12),
                _MainActionButton(
                  icon: Icons.file_download,
                  label: '导入整合包',
                  gradient: BAColors.secondaryGradient as LinearGradient,
                  onTap: _importInstance,
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: _MainActionButton(
                    icon: Icons.add,
                    label: '创建实例',
                    gradient: BAColors.primaryGradient as LinearGradient,
                    onTap: () => BACreateInstanceDialog.show(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MainActionButton(
                    icon: Icons.file_download,
                    label: '导入整合包',
                    gradient: BAColors.secondaryGradient as LinearGradient,
                    onTap: _importInstance,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BuildContext buttonContext;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.buttonContext,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(widget.buttonContext).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? BAColors.primaryOf(widget.buttonContext).withOpacity(0.1) : cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? BAColors.primaryOf(widget.buttonContext) : cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? BAColors.primaryOf(widget.buttonContext) : textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered ? BAColors.primaryOf(widget.buttonContext) : textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _MainActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_MainActionButton> createState() => _MainActionButtonState();
}

class _MainActionButtonState extends State<_MainActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BATheme.borderRadiusMedium,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstanceCard extends StatefulWidget {
  final GameInstance instance;
  final bool isLaunching;
  final VoidCallback? onLaunch;
  final BuildContext cardContext;

  const _InstanceCard({
    required this.instance,
    this.isLaunching = false,
    this.onLaunch,
    required this.cardContext,
  });

  @override
  State<_InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<_InstanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(widget.cardContext).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;

    final status = widget.instance.status;
    final statusColor = _getStatusColor(status, widget.cardContext);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? BAColors.primaryOf(widget.cardContext) : cardBorder,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: BAColors.primaryOf(widget.cardContext).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : BATheme.shadowsSmallOf(widget.cardContext),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLaunching ? null : widget.onLaunch,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.landscape,
                            size: 48,
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isLaunching)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    BAColors.primaryOf(widget.cardContext),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_isHovered && !widget.isLaunching)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    BAColors.primaryOf(widget.cardContext),
                                    BAColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: BAColors.primaryOf(widget.cardContext).withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.instance.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.games,
                            label: widget.instance.version,
                          ),
                          const SizedBox(width: 6),
                          _InfoChip(
                            icon: Icons.extension,
                            label: widget.instance.loader ?? '原版',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Color _getStatusColor(InstanceStatus status, BuildContext context) {
    switch (status) {
      case InstanceStatus.running:
        return BAColors.successOf(context);
      case InstanceStatus.launching:
        return BAColors.warningOf(context);
      case InstanceStatus.crashed:
        return BAColors.dangerOf(context);
      default:
        return BAColors.primaryOf(context);
    }
  }

  String _getStatusLabel(InstanceStatus status) {
    switch (status) {
      case InstanceStatus.running:
        return '运行中';
      case InstanceStatus.launching:
        return '启动中';
      case InstanceStatus.crashed:
        return '崩溃';
      default:
        return '就绪';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceVariant = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
