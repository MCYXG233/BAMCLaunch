import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/mc_theme_colors.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../account/skin_manager.dart';
import '../components/ba_common_widgets.dart';

/// 沉浸式首页组件（分散式布局）
///
/// 左上角：玩家信息卡片
/// 左下角：实例快捷切换栏
/// 右下角：超大启动按钮（与底部导航栏融合）
/// 中间大面积留空展示背景图
class ImmersiveHomePage extends StatefulWidget {
  final List<GameInstance> instances;
  final int selectedInstanceIndex;
  final ValueChanged<int> onInstanceChanged;
  final bool isLaunching;
  final VoidCallback onLaunch;

  const ImmersiveHomePage({
    super.key,
    required this.instances,
    required this.selectedInstanceIndex,
    required this.onInstanceChanged,
    required this.isLaunching,
    required this.onLaunch,
  });

  @override
  State<ImmersiveHomePage> createState() => _ImmersiveHomePageState();
}

class _ImmersiveHomePageState extends State<ImmersiveHomePage>
    with SingleTickerProviderStateMixin {
  final AccountManager _accountManager = AccountManager();
  final SkinManager _skinManager = SkinManager();

  Account? _currentAccount;
  SkinData? _currentSkin;
  bool _isLoadingAccount = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isHoveringLaunch = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    try {
      await _skinManager.initialize();
      final selectedAccount = await _accountManager.getSelectedAccount();
      if (selectedAccount != null && mounted) {
        setState(() {
          _currentAccount = selectedAccount;
          _isLoadingAccount = false;
        });
        final skin = await _skinManager.getSkin(selectedAccount);
        if (mounted) {
          setState(() => _currentSkin = skin);
        }
      } else if (mounted) {
        setState(() => _isLoadingAccount = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAccount = false);
    }
  }

  GameInstance? get _selectedInstance {
    if (widget.instances.isEmpty ||
        widget.selectedInstanceIndex >= widget.instances.length) {
      return null;
    }
    return widget.instances[widget.selectedInstanceIndex];
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final instance = _selectedInstance;

    return Stack(
      children: [
        // 左上角：玩家信息卡片（头像渲染Minecraft角色）
        Positioned(
          left: 24,
          top: 16,
          child: _buildPlayerInfoCard(context, isLight),
        ),

        // 右上角：版本切换按钮
        Positioned(
          right: 24,
          top: 16,
          child: _buildVersionSwitcher(context, isLight),
        ),

        // 左下角：游戏名称和信息
        Positioned(
          left: 24,
          bottom: 20,
          child: _buildGameInfo(context, isLight, instance),
        ),

        // 右下角：超大启动按钮（与底部导航栏融合，向上突出）
        Positioned(
          right: 24,
          bottom: 8,
          child: _buildGiantLaunchButton(context, isLight, instance),
        ),
      ],
    );
  }

  // ==================== 左上角：玩家信息卡片 ====================

  Widget _buildPlayerInfoCard(BuildContext context, bool isLight) {
    return BAGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像
          _buildAvatar(context, 52),
          const SizedBox(width: 14),

          // 玩家信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoadingAccount
                    ? '加载中...'
                    : (_currentAccount?.username ?? '未登录'),
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BAColors.primaryOf(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentAccount?.type == AccountType.microsoft
                      ? 'Microsoft 账户'
                      : '离线账户',
                  style: TextStyle(
                    color: BAColors.primaryOf(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 12,
                    color: BAColors.textPrimaryOf(context).withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.instances.length} 个实例',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context).withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.primaryOf(context).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: BAColors.primaryOf(context).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _currentSkin != null
            ? _buildSkinPreview(context, _currentSkin!, size)
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildSkinPreview(BuildContext context, SkinData skin, double size) {
    return Image.memory(
      Uint8List.fromList(skin.imageData),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDefaultAvatar(context),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: BAColors.primaryOf(context).withOpacity(0.15),
      child: Icon(
        Icons.person,
        size: 28,
        color: BAColors.primaryOf(context),
      ),
    );
  }

  // ==================== 左下角：游戏信息 ====================

  Widget _buildGameInfo(BuildContext context, bool isLight, GameInstance? instance) {
    if (instance == null) return const SizedBox.shrink();

    return BAGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 游戏名称
          Text(
            instance.name,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // 版本和加载器标签
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip(
                Icons.tag,
                'MC ${instance.version}',
                _getVersionColor(context, instance.version),
              ),
              if (instance.loader != null)
                _buildInfoChip(
                  Icons.extension,
                  instance.loader!,
                  BAColors.secondaryOf(context),
                ),
              if (instance.status == InstanceStatus.running)
                _buildInfoChip(
                  Icons.play_circle_filled,
                  '运行中',
                  BAColors.accentPinkOf(context),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 快速操作按钮
          Row(
            children: [
              _buildQuickActionButton(
                context,
                Icons.settings,
                '游戏设置',
                BAColors.primaryOf(context),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                context,
                Icons.extension,
                'Mod 管理',
                BAColors.secondaryOf(context),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                context,
                Icons.folder,
                '.minecraft',
                MCThemeColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 右上角：版本切换 ====================

  Widget _buildVersionSwitcher(BuildContext context, bool isLight) {
    final instance = _selectedInstance;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showInstanceSelector(context, isLight),
        child: BAGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 14,
          opacity: 0.65,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: instance != null
                      ? _getVersionColor(context, instance.version).withOpacity(0.2)
                      : BAColors.primaryOf(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_esports,
                  size: 16,
                  color: instance != null
                      ? _getVersionColor(context, instance.version)
                      : BAColors.primaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance?.name ?? '选择版本',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instance != null
                        ? 'MC ${instance.version}'
                        : '${widget.instances.length} 个实例',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: BAColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstanceSelector(BuildContext context, bool isLight) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 400,
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '选择版本',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BAColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: BAColors.dividerOf(context),
                ),
                const SizedBox(height: 8),
                ...List.generate(widget.instances.length, (index) {
                  final inst = widget.instances[index];
                  final isSelected = index == widget.selectedInstanceIndex;
                  return ListTile(
                    onTap: () {
                      widget.onInstanceChanged(index);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getVersionColor(context, inst.version).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sports_esports,
                        color: _getVersionColor(context, inst.version),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      inst.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      'MC ${inst.version}'
                      '${inst.loader != null ? ' · ${inst.loader}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: BAColors.primaryOf(context), size: 22)
                        : null,
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== 右下角：超大启动按钮 ====================

  Widget _buildGiantLaunchButton(BuildContext context, bool isLight, GameInstance? instance) {
    final isDisabled = widget.isLaunching || instance == null;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHoveringLaunch = true),
      onExit: (_) => setState(() => _isHoveringLaunch = false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onLaunch,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Container(
                width: 160,
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDisabled)
                      BoxShadow(
                        color: BAColors.primaryOf(context).withOpacity(
                          0.4 + (_pulseAnimation.value * 0.25),
                        ),
                        blurRadius: 20 + (_pulseAnimation.value * 12),
                        spreadRadius: _isHoveringLaunch ? 3 : 0,
                        offset: const Offset(0, 6),
                      ),
                    BoxShadow(
                      color: BAColors.surfaceOf(context).withOpacity(0.25),
                      blurRadius: 0,
                      offset: const Offset(0, -2),
                      spreadRadius: -1,
                    ),
                  ],
                  border: Border.all(
                    color: BAColors.surfaceOf(context).withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                BAColors.surfaceOf(context).withOpacity(
                                    _isHoveringLaunch ? 0.3 : 0.18),
                                Colors.transparent,
                                Colors.black.withOpacity(0.12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isLaunching)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: BAColors.surfaceOf(context),
                                strokeWidth: 2.5,
                              ),
                            )
                          else
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.identity()
                                ..scale(_isHoveringLaunch ? 1.2 : 1.0),
                              child: Icon(
                                Icons.play_arrow,
                                color: BAColors.surfaceOf(context),
                                size: 32,
                              ),
                            ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: BAColors.surfaceOf(context),
                              fontSize: _isHoveringLaunch ? 17 : 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                            child: Text(
                              widget.isLaunching ? '启动中' : '启动游戏',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getVersionColor(BuildContext context, String version) {
    if (version.startsWith('1.21')) return BAColors.primaryOf(context);
    if (version.startsWith('1.20')) return BAColors.secondaryOf(context);
    if (version.startsWith('1.19')) return MCThemeColors.accent;
    if (version.startsWith('1.18')) return BAColors.accentPinkOf(context);
    return BAColors.textSecondaryOf(context);
  }
}
