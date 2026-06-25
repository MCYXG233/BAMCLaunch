import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';
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
        // 左上角：玩家信息卡片
        Positioned(
          left: 24,
          top: 16,
          child: _buildPlayerInfoCard(isLight),
        ),

        // 左侧中间：快速操作区
        Positioned(
          left: 24,
          bottom: 100,
          child: _buildQuickActions(isLight),
        ),

        // 右下角：超大启动按钮（与底部导航栏融合，向上突出）
        Positioned(
          right: 24,
          bottom: 8,
          child: _buildGiantLaunchButton(isLight, instance),
        ),

        // 底部中间偏左：实例快捷切换
        Positioned(
          left: 0,
          right: 200,
          bottom: 16,
          child: _buildInstanceQuickSwitcher(isLight),
        ),
      ],
    );
  }

  // ==================== 左上角：玩家信息卡片 ====================

  Widget _buildPlayerInfoCard(bool isLight) {
    return BAGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像
          _buildAvatar(52),
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
                  color: isLight ? const Color(0xFF1A2744) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BAThemeColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentAccount?.type == AccountType.microsoft
                      ? 'Microsoft 账户'
                      : '离线账户',
                  style: const TextStyle(
                    color: BAThemeColors.primary,
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
                    color: isLight
                        ? const Color(0xFF1A2744).withOpacity(0.6)
                        : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.instances.length} 个实例',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF1A2744).withOpacity(0.6)
                          : Colors.white.withOpacity(0.6),
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

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAThemeColors.primary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: BAThemeColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _currentSkin != null
            ? Image.memory(
                Uint8List.fromList(_currentSkin!.imageData),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: BAThemeColors.primary.withOpacity(0.15),
      child: const Icon(
        Icons.person,
        size: 28,
        color: BAThemeColors.primary,
      ),
    );
  }

  // ==================== 左侧：快速操作区 ====================

  Widget _buildQuickActions(bool isLight) {
    final instance = _selectedInstance;
    final actions = [
      {'icon': Icons.settings, 'label': '游戏设置', 'color': BAThemeColors.primary},
      {'icon': Icons.extension, 'label': 'Mod 管理', 'color': MCThemeColors.secondary},
      {'icon': Icons.folder, 'label': '.minecraft', 'color': MCThemeColors.accent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instance != null) ...[
          // 当前实例信息
          BAGlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            opacity: 0.6,
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports,
                    color: _getVersionColor(instance.version), size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.name,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF1A2744)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MC ${instance.version}'
                      '${instance.loader != null ? ' · ${instance.loader}' : ''}',
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF1A2744).withOpacity(0.6)
                            : Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // 快速操作按钮
        ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildQuickActionButton(
                action['icon'] as IconData,
                action['label'] as String,
                action['color'] as Color,
                isLight,
              ),
            )),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    bool isLight,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: BAGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 14,
        opacity: 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isLight ? const Color(0xFF1A2744) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 右下角：超大启动按钮 ====================

  Widget _buildGiantLaunchButton(bool isLight, GameInstance? instance) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 版本信息（按钮上方）
                  if (instance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        'MC ${instance.version}'
                        '${instance.loader != null ? ' · ${instance.loader}' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // 启动按钮主体
                  Container(
                    width: 160,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BAThemeColors.primaryLight,
                          BAThemeColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        // 发光效果
                        if (!isDisabled)
                          BoxShadow(
                            color: BAThemeColors.primary.withOpacity(
                              0.4 + (_pulseAnimation.value * 0.25),
                            ),
                            blurRadius: 20 + (_pulseAnimation.value * 12),
                            spreadRadius: _isHoveringLaunch ? 3 : 0,
                            offset: const Offset(0, 6),
                          ),
                        // 内部高光
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 0,
                          offset: const Offset(0, -2),
                          spreadRadius: -1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 光泽效果
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
                                    Colors.white.withOpacity(
                                        _isHoveringLaunch ? 0.3 : 0.18),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 按钮内容
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.isLaunching)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              else
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  transform: Matrix4.identity()
                                    ..scale(_isHoveringLaunch ? 1.2 : 1.0),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: Colors.white,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 底部：实例快捷切换 ====================

  Widget _buildInstanceQuickSwitcher(bool isLight) {
    if (widget.instances.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 56,
      margin: const EdgeInsets.only(left: 24, right: 24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.instances.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _buildQuickInstanceItem(index, isLight);
        },
      ),
    );
  }

  Widget _buildQuickInstanceItem(int index, bool isLight) {
    final inst = widget.instances[index];
    final isSelected = index == widget.selectedInstanceIndex;
    final color = _getVersionColor(inst.version);

    return GestureDetector(
      onTap: () => widget.onInstanceChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.35)
              : Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.7)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports,
                color: isSelected ? color : Colors.white.withOpacity(0.7),
                size: isSelected ? 22 : 18,
              ),
              if (isSelected) ...[
                const SizedBox(height: 2),
                Text(
                  inst.version,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVersionColor(String version) {
    if (version.startsWith('1.21')) return BAThemeColors.primary;
    if (version.startsWith('1.20')) return MCThemeColors.secondary;
    if (version.startsWith('1.19')) return MCThemeColors.accent;
    if (version.startsWith('1.18')) return MCThemeColors.woolPink;
    return BAThemeColors.textSecondary;
  }
}
