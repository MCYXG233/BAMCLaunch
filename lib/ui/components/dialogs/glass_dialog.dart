import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../theme/colors.dart';
import '../icons/pixel_icon.dart';

class GlassDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _GlassDialogContent(
          title: title,
          content: content,
          actions: actions,
          width: width,
          height: height,
        ),
      ),
    );
  }
}

class _GlassDialogContent extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final double? height;

  const _GlassDialogContent({
    required this.title,
    required this.content,
    this.actions,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width ?? 520,
        constraints: BoxConstraints(
          maxHeight: height ?? MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: BamcColors.shadow.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: BamcColors.shadow.withOpacity(0.15),
              blurRadius: 45,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                color: BamcColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BamcColors.border.withOpacity(0.7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BamcColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pixel line decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            BamcColors.primary.withOpacity(0),
                            BamcColors.primary,
                            BamcColors.primary.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            BamcColors.secondary.withOpacity(0),
                            BamcColors.secondary,
                            BamcColors.secondary.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleBar(context),
                      _buildContent(),
                      if (actions != null && actions!.isNotEmpty) _buildActions(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.15),
            BamcColors.secondary.withOpacity(0.15),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: BamcColors.border.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: BamcColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _PixelCloseButton(
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: content,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BamcColors.border.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!.map((action) {
          if (actions!.indexOf(action) > 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: action,
            );
          }
          return action;
        }).toList(),
      ),
    );
  }
}

class _PixelCloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PixelCloseButton({
    required this.onPressed,
  });

  @override
  State<_PixelCloseButton> createState() => _PixelCloseButtonState();
}

class _PixelCloseButtonState extends State<_PixelCloseButton> {
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
          width: 36,
          height: 36,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.9 : _isHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: BamcColors.error.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: PixelIcon(
              iconType: PixelIconType.close,
              size: 22,
              color: _getIconColor(),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_isPressed) {
      return BamcColors.error.withOpacity(0.35);
    }
    if (_isHovered) {
      return BamcColors.error.withOpacity(0.2);
    }
    return Colors.transparent;
  }

  Color _getBorderColor() {
    if (_isPressed || _isHovered) {
      return BamcColors.error;
    }
    return BamcColors.border.withOpacity(0.4);
  }

  Color _getIconColor() {
    if (_isPressed || _isHovered) {
      return BamcColors.error;
    }
    return BamcColors.textSecondary;
  }
}
