import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../account/account_manager.dart';
import '../../instance/instance_manager.dart';
import '../components/ba_buttons.dart';
import '../components/ba_character_display.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/background_manager.dart';
import 'ba_game_library_page.dart';
import 'ba_resource_center_page.dart';
import 'ba_settings_page.dart';

/// 蔚蓝档案风格主页
/// 完全模仿蔚蓝档案游戏主界面的设计
///  - 顶部: 用户信息(Lv. + 用户名) + 资源栏(体力/信用点/宝石)
///  - 左侧: 功能入口按钮(公告/邮件/任务/商店)
///  - 中部: 角色立绘展示区 + 事件横幅
///  - 右侧: 引导任务卡片
///  - 底部: 主导航栏
class BAMainPage extends StatefulWidget {
  const BAMainPage({super.key});

  @override
  State<BAMainPage> createState() => _BAMainPageState();
}

class _BAMainPageState extends State<BAMainPage> {
  int _currentPage = 0;
  bool _isMaximized = false;
  final BackgroundManager _backgroundManager = BackgroundManager();

  final AccountManager _accountManager = AccountManager();
  final InstanceManager _instanceManager = InstanceManager();
  String? _selectedAccountName;
  bool _isLoading = true;
  int _instanceCount = 0;
  int _activeDownloads = 0;

  // 模拟资源数据（蔚蓝档案风格：体力/信用点/青辉石）
  final int _stamina = 87;
  final int _maxStamina = 132;
  final int _credits = 35426147;
  final int _pyroxene = 666;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _loadAccountData();
    _initInstanceManager();
    _initBackgroundManager();
  }

  Future<void> _initBackgroundManager() async {
    await _backgroundManager.initialize();
    _backgroundManager.addListener(_onBackgroundChanged);
    if (mounted) setState(() {});
  }

  void _onBackgroundChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _backgroundManager.removeListener(_onBackgroundChanged);
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    try {
      final selectedAccount = await _accountManager.getSelectedAccount();
      if (mounted) {
        setState(() {
          _selectedAccountName = selectedAccount?.username ?? 'Sensei';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAccountName = 'Sensei';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initInstanceManager() async {
    try {
      await _instanceManager.initialize();
      if (mounted) {
        setState(() {
          _instanceCount = _instanceManager.instances.length;
        });
      }
    } catch (e) {
      // 静默失败
    }
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

  @override
  Widget build(BuildContext context) {
    if (_currentPage == 1) return const BAGameLibraryPage();
    if (_currentPage == 2) return const BAResourceCenterPage();
    if (_currentPage == 3) return const BASettingsPage();

    return Scaffold(
      body: _backgroundManager.buildBackground(
        child: SafeArea(
          child: Container(
            color: Colors.transparent,
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMainContent(),
                      _buildLeftSideButtons(),
                      _buildRightSideContent(),
                    ],
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 顶部栏 ====================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息卡 (Lv. + 用户名)
          _buildUserInfoCard(),
          const SizedBox(width: 16),

          // 研修/任务入口 (小按钮)
          _buildQuickActionButton(
            icon: Icons.calendar_today,
            label: '研修中',
            subLabel: 'あと27日',
            onTap: () => setState(() => _currentPage = 3),
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            icon: Icons.task_alt,
            label: '任务',
            subLabel: '2/8',
            onTap: () => setState(() => _currentPage = 1),
          ),

          const Spacer(),

          // 资源栏 (体力)
          _buildResourceChip(
            icon: Icons.bolt,
            value: _stamina,
            maxValue: _maxStamina,
            color: const Color(0xFFF5D76E),
            backgroundColor: const Color(0xFF1A2540),
          ),
          const SizedBox(width: 8),

          // 资源栏 (信用点)
          _buildResourceChip(
            icon: Icons.account_balance_wallet,
            value: _credits,
            color: const Color(0xFF7BCB9E),
            backgroundColor: const Color(0xFF1A2540),
          ),
          const SizedBox(width: 8),

          // 资源栏 (青辉石/宝石)
          _buildResourceChip(
            icon: Icons.diamond,
            value: _pyroxene,
            color: const Color(0xFF6B8EFF),
            backgroundColor: const Color(0xFF1A2540),
          ),
          const SizedBox(width: 16),

          // 邮件图标
          _buildTopIconButton(Icons.mail_outline, hasNotification: true),
          const SizedBox(width: 4),

          // 设置图标
          _buildTopIconButton(Icons.settings, onTap: () => setState(() => _currentPage = 3)),
          const SizedBox(width: 4),

          // 窗口控制
          if (Platform.isWindows) ...[
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

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3A4D7A).withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 等级徽章
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD93D).withOpacity(0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Text(
              'Lv.',
              style: TextStyle(
                color: Color(0xFF1A2540),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedAccountName ?? 'Sensei',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              // 经验条
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3A5C),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.72,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BCB9E), Color(0xFFB8F5D1)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7BCB9E).withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // 小叶子装饰
          Icon(
            Icons.eco,
            color: Colors.greenAccent.shade100,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2540).withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3A4D7A).withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFB8C5E0), size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceChip({
    required IconData icon,
    required int value,
    int? maxValue,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3A4D7A).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            maxValue != null ? '$value/$maxValue' : _formatNumber(value),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.add_circle_outline,
            color: color.withOpacity(0.6),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, {bool hasNotification = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2540).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3A4D7A).withOpacity(0.5),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: const Color(0xFFB8C5E0),
                  size: 18,
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A2540), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 主内容区 ====================

  Widget _buildMainContent() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(100, 20, 320, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventBanner(),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildCharacterDisplay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return Container(
      width: 380,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB4C2).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB4C2).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB4C2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'EVENT!',
              style: TextStyle(
                color: Color(0xFF1A2540),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '夏休みイベント・ビッグアップデート',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '限定キャラクター登場中！',
                  style: TextStyle(
                    color: Color(0xFFB8C5E0),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎语
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2540).withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                color: const Color(0xFF3A4D7A).withOpacity(0.5),
              ),
            ),
            child: Text(
              'お帰りなさい、先生！',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 看板娘动画组件
          const BACharacterDisplay(width: 320, height: 350),
          const SizedBox(height: 12),
          // 信息卡
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3A4D7A).withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7BCB9E), Color(0xFFB8F5D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.videogame_asset,
                  color: Color(0xFF1A2540),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Minecraft 启动器',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Blue Archive Theme',
                      style: TextStyle(
                        color: Color(0xFFB8C5E0),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 统计信息
          Row(
            children: [
              _buildStatItem(Icons.folder_outlined, '$_instanceCount', '实例'),
              const SizedBox(width: 12),
              _buildStatItem(Icons.download_outlined, '$_activeDownloads', '下载中'),
              const SizedBox(width: 12),
              _buildStatItem(Icons.extension_outlined, '12', 'Mod'),
            ],
          ),
          const SizedBox(height: 16),
          // 开始按钮
          SizedBox(
            width: double.infinity,
            child: BAButton(
              onPressed: () => setState(() => _currentPage = 1),
              style: BAButtonStyle.primary,
              leadingIcon: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
              ),
              height: 44,
              child: const Text(
                '演習開始！',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3A5C).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF3A4D7A).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7BCB9E), size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8A9BB8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 左侧按钮 ====================

  Widget _buildLeftSideButtons() {
    final buttons = [
      _SideButtonData(
        icon: Icons.campaign_outlined,
        label: 'お知らせ',
        onTap: () {},
      ),
      _SideButtonData(
        icon: Icons.mail_outline,
        label: 'モモトーク',
        badge: '6',
        onTap: () {},
      ),
      _SideButtonData(
        icon: Icons.assignment_outlined,
        label: 'ミッション',
        subLabel: '2/8',
        onTap: () => setState(() => _currentPage = 1),
      ),
      _SideButtonData(
        icon: Icons.shopping_bag_outlined,
        label: 'ストア',
        onTap: () => setState(() => _currentPage = 2),
      ),
    ];

    return Positioned(
      left: 20,
      top: 10,
      bottom: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            _buildSideButton(buttons[i]),
            if (i < buttons.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSideButton(_SideButtonData data) {
    return GestureDetector(
      onTap: data.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2540).withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF3A4D7A).withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.icon,
                    color: const Color(0xFFB8C5E0),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (data.subLabel != null)
                    Text(
                      data.subLabel!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
              if (data.badge != null)
                Positioned(
                  top: 4,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      data.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 右侧内容 ====================

  Widget _buildRightSideContent() {
    return Positioned(
      right: 20,
      top: 10,
      bottom: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildGuideMissionCard(),
          const SizedBox(height: 12),
          _buildQuickStartCard(),
        ],
      ),
    );
  }

  Widget _buildGuideMissionCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB4C2).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFFFFB4C2), size: 16),
              SizedBox(width: 6),
              Text(
                'ガイドミッション',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 任务列表
          _buildMissionItem('游戏实例创建', '创建你的第一个 MC 实例', true),
          _buildMissionItem('Mod 管理', '安装并启用 Mod', false),
          _buildMissionItem('资源下载', '从资源中心下载内容', false),
          _buildMissionItem('启动游戏', '成功启动一次游戏', true),
          const SizedBox(height: 10),
          // 进度
          Row(
            children: const [
              Expanded(
                child: Text(
                  '進捗: 2/4',
                  style: TextStyle(
                    color: Color(0xFFB8C5E0),
                    fontSize: 11,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Color(0xFFB8C5E0),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionItem(String title, String desc, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF2A5C3F).withOpacity(0.4)
            : const Color(0xFF2A3A5C).withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (completed
                  ? const Color(0xFF7BCB9E)
                  : const Color(0xFF3A4D7A))
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: completed ? const Color(0xFF7BCB9E) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: completed ? const Color(0xFF7BCB9E) : const Color(0xFF5A6A8A),
                width: 1.5,
              ),
            ),
            child: completed
                ? const Icon(Icons.check, color: Color(0xFF1A2540), size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: completed ? const Color(0xFF7BCB9E) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF7BCB9E).withOpacity(0.5),
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3A4D7A).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Color(0xFFFFD93D), size: 16),
              SizedBox(width: 6),
              Text(
                'クイックスタート',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildQuickItem(Icons.add, '新建实例', () => setState(() => _currentPage = 1)),
          _buildQuickItem(Icons.download, '下载 Mod', () => setState(() => _currentPage = 2)),
          _buildQuickItem(Icons.settings, '启动器设置', () => setState(() => _currentPage = 3)),
        ],
      ),
    );
  }

  Widget _buildQuickItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A3A5C).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3A4D7A).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF7BCB9E), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF5A6A8A), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 底部导航 ====================

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home, 'ホーム', 0),
      _NavItem(Icons.inventory_2_outlined, 'カフェ', 1),
      _NavItem(Icons.grid_view, '生徒', 2),
      _NavItem(Icons.menu_book, '編成', 3),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3A4D7A).withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => _buildNavItem(item.icon, item.label, item.index))
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6B8EFF).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6B8EFF).withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF6B8EFF) : const Color(0xFF8A9BB8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6B8EFF) : const Color(0xFF8A9BB8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 100000000) {
      return '${(num / 100000000).toStringAsFixed(1)}億';
    } else if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(0)},${(num % 10000).toString().padLeft(4, '0')}';
    }
    return num.toString();
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem(this.icon, this.label, this.index);
}

class _SideButtonData {
  final IconData icon;
  final String label;
  final String? subLabel;
  final String? badge;
  final VoidCallback? onTap;

  _SideButtonData({
    required this.icon,
    required this.label,
    this.subLabel,
    this.badge,
    this.onTap,
  });
}

/// 窗口按钮
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
                : const Color(0xFF1A2540).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3A4D7A).withOpacity(0.5),
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
