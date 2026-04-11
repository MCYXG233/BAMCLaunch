import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/colors.dart';

class CustomTitleBar extends StatefulWidget {
  final String title;
  final bool isMacOS;
  final VoidCallback? onPerformanceToggle;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.isMacOS = false,
    this.onPerformanceToggle,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  double _dragStartX = 0;
  double _dragStartY = 0;
  bool _isHovering = false;

  Future<void> _handleMinimize() async {
    await windowManager.minimize();
  }

  Future<void> _handleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _handleClose() async {
    await windowManager.close();
  }

  void _handleMouseDown(PointerDownEvent event) {
    _dragStartX = event.position.dx;
    _dragStartY = event.position.dy;
  }

  void _handleMouseMove(PointerMoveEvent event) {
    windowManager.startDragging();
  }

  void _handleMouseUp(PointerUpEvent event) {
    // windowManager.stopDragging();
  }

  Widget _buildWindowControls() {
    if (widget.isMacOS) {
      return Row(
        children: [
          _buildControlButton(
            color: BamcColors.warning,
            onPressed: _handleClose,
            icon: Icons.close,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            color: BamcColors.success,
            onPressed: _handleMinimize,
            icon: Icons.minimize,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            color: BamcColors.secondary,
            onPressed: _handleMaximize,
            icon: Icons.maximize,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          _buildControlButton(
            color: BamcColors.border,
            onPressed: _handleMinimize,
            icon: Icons.minimize,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            color: BamcColors.border,
            onPressed: _handleMaximize,
            icon: Icons.maximize,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            color: BamcColors.warning,
            onPressed: _handleClose,
            icon: Icons.close,
          ),
        ],
      );
    }
  }

  Widget _buildControlButton({
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPerformanceToggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: BamcColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BamcColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.speed,
            size: 16,
            color: BamcColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftActions() {
    return const SizedBox();
  }

  Widget _buildRightActions() {
    return Row(
      children: [
        if (widget.onPerformanceToggle != null)
          _buildPerformanceButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Listener(
        onPointerDown: (event) {
          _handleMouseDown(event);
        },
        onPointerMove: (event) {
          _handleMouseMove(event);
        },
        onPointerUp: (event) {
          _handleMouseUp(event);
        },
        child: Container(
          height: 40,
          decoration: const BoxDecoration(
            color: BamcColors.surface,
            border: Border(
              bottom: BorderSide(
                color: BamcColors.border,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (widget.isMacOS)
                  Expanded(child: _buildWindowControls())
                else
                  _buildLeftActions(),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (!widget.isMacOS)
                  Row(
                    children: [
                      if (widget.onPerformanceToggle != null)
                        _buildPerformanceButton(),
                      const SizedBox(width: 8),
                      _buildWindowControls(),
                    ],
                  )
                else
                  _buildRightActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
