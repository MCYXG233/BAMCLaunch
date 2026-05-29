import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// 自定义标题栏组件
/// 适配Windows（关闭/最小化/最大化在右侧）和MacOS（红绿灯在左侧）
class CustomTitleBar extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 左侧自定义动作按钮
  final List<Widget>? leadingActions;

  /// 右侧自定义动作按钮
  final List<Widget>? trailingActions;

  /// 标题栏高度
  final double height;

  /// 是否显示窗口控制按钮
  final bool showWindowControls;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.leadingActions,
    this.trailingActions,
    this.height = 48,
    this.showWindowControls = true,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  /// 窗口是否最大化
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 初始化窗口状态
  Future<void> _initWindow() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onWindowRestore() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: BAColors.surface,
        boxShadow: BATheme.shadowsSmall,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (Platform.isMacOS) {
                  if (_isMaximized) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                }
              },
            ),
          ),
          Row(
            children: [
              if (Platform.isMacOS && widget.showWindowControls)
                _buildMacOSWindowControls(),
              if (widget.leadingActions != null) ...widget.leadingActions!,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.title,
                    style: BATypography.titleBar.copyWith(
                      color: BAColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.trailingActions != null) ...widget.trailingActions!,
              if (Platform.isWindows && widget.showWindowControls)
                _buildWindowsWindowControls(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建Windows风格的窗口控制按钮
  Widget _buildWindowsWindowControls() {
    return Row(
      children: [
        _WindowControlButton(
          icon: Icons.remove,
          tooltip: '最小化',
          onPressed: () => windowManager.minimize(),
          buttonType: _WindowButtonType.minimize,
        ),
        _WindowControlButton(
          icon: _isMaximized ? Icons.crop_square : Icons.crop_square_outlined,
          tooltip: _isMaximized ? '还原' : '最大化',
          onPressed: () {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          buttonType: _WindowButtonType.maximize,
        ),
        _WindowControlButton(
          icon: Icons.close,
          tooltip: '关闭',
          onPressed: () => windowManager.close(),
          buttonType: _WindowButtonType.close,
        ),
      ],
    );
  }

  /// 构建MacOS风格的窗口控制按钮
  Widget _buildMacOSWindowControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MacOSWindowControlButton(
            color: BAColors.danger,
            onPressed: () => windowManager.close(),
          ),
          const SizedBox(width: 8),
          _MacOSWindowControlButton(
            color: BAColors.warning,
            onPressed: () => windowManager.minimize(),
          ),
          const SizedBox(width: 8),
          _MacOSWindowControlButton(
            color: BAColors.success,
            onPressed: () {
              if (_isMaximized) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 窗口按钮类型
enum _WindowButtonType { minimize, maximize, close }

/// Windows风格窗口控制按钮
class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final _WindowButtonType buttonType;

  const _WindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.buttonType,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Container(
            width: 46,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: widget.buttonType == _WindowButtonType.close
                  ? const BorderRadius.only(topRight: Radius.circular(12))
                  : null,
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? Colors.white : BAColors.textSecondary,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final hoverColor = isLight ? BAColors.lightSurfaceTertiary : BAColors.darkSurfaceTertiary;
    
    if (_isPressed) {
      switch (widget.buttonType) {
        case _WindowButtonType.close:
          return BAColors.danger;
        case _WindowButtonType.maximize:
          return hoverColor;
        case _WindowButtonType.minimize:
          return hoverColor;
      }
    }
    if (_isHovered) {
      switch (widget.buttonType) {
        case _WindowButtonType.close:
          return BAColors.danger;
        case _WindowButtonType.maximize:
          return BAColors.surfaceVariantOf(context);
        case _WindowButtonType.minimize:
          return BAColors.surfaceVariantOf(context);
      }
    }
    return Colors.transparent;
  }
}

/// MacOS风格窗口控制按钮
class _MacOSWindowControlButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;

  const _MacOSWindowControlButton({
    required this.color,
    required this.onPressed,
  });

  @override
  State<_MacOSWindowControlButton> createState() =>
      _MacOSWindowControlButtonState();
}

class _MacOSWindowControlButtonState extends State<_MacOSWindowControlButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _isHovered ? widget.color : widget.color.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
