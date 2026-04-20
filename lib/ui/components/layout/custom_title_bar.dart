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
    // windowManager.stopDragging();
  }

  Widget _buildPixelIcon(String type) {
    return SizedBox(
      width: 14,
      height: 14,
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
            color: BamcColors.warning,
            onPressed: _handleClose,
            iconType: 'close',
          ),
          const SizedBox(width: 10),
          _buildControlButton(
            id: 'minimize',
            color: BamcColors.success,
            onPressed: _handleMinimize,
            iconType: 'minimize',
          ),
          const SizedBox(width: 10),
          _buildControlButton(
            id: 'maximize',
            color: BamcColors.secondary,
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
            color: BamcColors.border,
            onPressed: _handleMinimize,
            iconType: 'minimize',
          ),
          const SizedBox(width: 10),
          _buildControlButton(
            id: 'maximize',
            color: BamcColors.border,
            onPressed: _handleMaximize,
            iconType: 'maximize',
          ),
          const SizedBox(width: 10),
          _buildControlButton(
            id: 'close',
            color: BamcColors.warning,
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
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isHovering
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.7),
                      color.withOpacity(0.9),
                    ],
                  ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _buildPixelIcon(iconType),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isHovering
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BamcColors.primary.withOpacity(0.3),
                      BamcColors.secondary.withOpacity(0.3),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BamcColors.primary.withOpacity(0.15),
                      BamcColors.secondary.withOpacity(0.15),
                    ],
                  ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHovering
                  ? BamcColors.primary.withOpacity(0.6)
                  : BamcColors.primary.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: BamcColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _buildPixelIcon('performance'),
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
                BamcColors.primary.withOpacity(0.15),
                BamcColors.secondary.withOpacity(0.15),
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
                color: BamcColors.shadow,
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
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                BamcColors.primary,
                                BamcColors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BamcColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.gamepad_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.primary,
                            fontFamily: 'Minecraft',
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
    final pixelSize = size.width / 14;

    switch (type) {
      case 'close':
        // Pixel close icon (X)
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 4 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                6 * pixelSize, 4 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                8 * pixelSize, 4 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 6 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                8 * pixelSize, 6 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 8 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                6 * pixelSize, 8 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                8 * pixelSize, 8 * pixelSize, 2 * pixelSize, 2 * pixelSize),
            paint);
        break;
      case 'minimize':
        // Pixel minimize icon (horizontal line)
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 6 * pixelSize, 6 * pixelSize, 2 * pixelSize),
            paint);
        break;
      case 'maximize':
        // Pixel maximize icon (square)
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 4 * pixelSize, 6 * pixelSize, 6 * pixelSize),
            paint);
        break;
      case 'performance':
        // Pixel performance icon (speed lines)
        canvas.drawRect(
            Rect.fromLTWH(
                5 * pixelSize, 4 * pixelSize, 4 * pixelSize, 6 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                4 * pixelSize, 5 * pixelSize, 1 * pixelSize, 4 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                9 * pixelSize, 5 * pixelSize, 1 * pixelSize, 4 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                3 * pixelSize, 6 * pixelSize, 1 * pixelSize, 2 * pixelSize),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(
                10 * pixelSize, 6 * pixelSize, 1 * pixelSize, 2 * pixelSize),
            paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
