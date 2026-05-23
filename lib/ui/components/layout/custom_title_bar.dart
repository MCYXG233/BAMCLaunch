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
  final Map<String, bool> _hoverStates = {};

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
  }

  Widget _buildPixelIcon(String type) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _PixelIconPainter(type),
      ),
    );
  }

  Widget _buildWindowControls() {
    if (widget.isMacOS) {
      return Row(
        children: [
          _buildControlButton(
            id: 'close',
            color: BamcColors.error,
            onPressed: _handleClose,
            iconType: 'close',
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            id: 'minimize',
            color: BamcColors.warning,
            onPressed: _handleMinimize,
            iconType: 'minimize',
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            id: 'maximize',
            color: BamcColors.success,
            onPressed: _handleMaximize,
            iconType: 'maximize',
          ),
        ],
      );
    } else {
      return Row(
        children: [
          _buildControlButton(
            id: 'minimize',
            color: BamcColors.textSecondary,
            onPressed: _handleMinimize,
            iconType: 'minimize',
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            id: 'maximize',
            color: BamcColors.textSecondary,
            onPressed: _handleMaximize,
            iconType: 'maximize',
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            id: 'close',
            color: BamcColors.error,
            onPressed: _handleClose,
            iconType: 'close',
          ),
        ],
      );
    }
  }

  Widget _buildControlButton({
    required String id,
    required Color color,
    required VoidCallback onPressed,
    required String iconType,
  }) {
    bool isHovering = _hoverStates[id] ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverStates[id] = true),
      onExit: (_) => setState(() => _hoverStates[id] = false),
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isHovering
                ? color.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHovering
                ? Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isHovering ? 1.0 : 0.7,
              child: Icon(
                iconType == 'close' ? Icons.close :
                iconType == 'minimize' ? Icons.remove :
                Icons.square,
                size: 14,
                color: iconType == 'close' ? BamcColors.error :
                       iconType == 'minimize' ? BamcColors.textSecondary :
                       BamcColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceButton() {
    bool isHovering = _hoverStates['performance'] ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverStates['performance'] = true),
      onExit: (_) => setState(() => _hoverStates['performance'] = false),
      child: GestureDetector(
        onTap: widget.onPerformanceToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isHovering
                ? BamcColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHovering
                ? Border.all(
                    color: BamcColors.primary,
                    width: 1,
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.speed,
              size: 16,
              color: isHovering ? BamcColors.primaryLight : BamcColors.textSecondary,
            ),
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
        if (widget.onPerformanceToggle != null) _buildPerformanceButton(),
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
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BamcColors.surface,
                BamcColors.surfaceDark,
              ],
            ),
            border: const Border(
              bottom: BorderSide(
                color: BamcColors.border,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: BamcColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.isMacOS)
                  Expanded(child: _buildWindowControls())
                else
                  _buildLeftActions(),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: BamcColors.logoGradient,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BamcColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.gamepad_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!widget.isMacOS)
                  Row(
                    children: [
                      if (widget.onPerformanceToggle != null)
                        _buildPerformanceButton(),
                      const SizedBox(width: 16),
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

class _PixelIconPainter extends CustomPainter {
  final String type;

  _PixelIconPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final pixelSize = size.width / 16;

    switch (type) {
      case 'close':
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 5 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                7 * pixelSize, 5 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                9 * pixelSize, 5 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 7 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                9 * pixelSize, 7 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 9 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                7 * pixelSize, 9 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                9 * pixelSize, 9 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        break;
      case 'minimize':
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 7 * pixelSize, 6 * pixelSize, 2 * pixelSize),
            paint);
        break;
      case 'maximize':
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 5 * pixelSize, 6 * pixelSize, 6 * pixelSize),
            paint);
        break;
      case 'performance':
        canvas.drawRect(
            Rect.fromLTWH(
                6 * pixelSize, 5 * pixelSize, 4 * pixelSize, 6 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 6 * pixelSize, 1 * pixelSize, 4 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                10 * pixelSize, 6 * pixelSize, 1 * pixelSize, 4 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 7 * pixelSize, 1 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                11 * pixelSize, 7 * pixelSize, 1 * pixelSize, 2 * pixelSize),
            paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}