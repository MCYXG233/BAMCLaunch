import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../pages/ba_settings_page.dart';

/// 设置页面右侧滑出面板
/// 使用 Overlay 方式实现
class BASettingsOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  /// 显示设置面板
  static void show(BuildContext context) {
    if (_isVisible) return;

    _isVisible = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _SettingsPanel(
        onClose: () => hide(),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏设置面板
  static void hide() {
    if (!_isVisible || _overlayEntry == null) return;

    _isVisible = false;
    _overlayEntry!.remove();
    _overlayEntry = null;
  }

  /// 切换显示状态
  static void toggle(BuildContext context) {
    if (_isVisible) {
      hide();
    } else {
      show(context);
    }
  }

  /// 是否正在显示
  static bool get isVisible => _isVisible;
}

/// 设置面板组件
class _SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const _SettingsPanel({required this.onClose});

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.4; // 40% 屏幕宽度

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 背景遮罩
            GestureDetector(
              onTap: _close,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
            // 设置面板
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: panelWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : const Color(0xFF1A1A2E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 顶部栏
                      _buildHeader(),
                      // 设置内容
                      Expanded(
                        child: BASettingsPage(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? Colors.grey.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: BAColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isLight ? BAColors.textPrimary : BAColors.darkTextPrimary,
            ),
          ),
          const Spacer(),
          // 关闭按钮
          IconButton(
            icon: Icon(
              Icons.close,
              color: isLight ? BAColors.textSecondary : BAColors.darkTextSecondary,
            ),
            onPressed: _close,
          ),
        ],
      ),
    );
  }
}
