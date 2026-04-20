import 'dart:ui';
import 'package:flutter/material.dart';
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
    return Container(
      width: width ?? 480,
      constraints: BoxConstraints(
        maxHeight: height ?? MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: BamcColors.glassBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BamcColors.border.withOpacity(0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BamcColors.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: BamcColors.shadow.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleBar(context),
                _buildContent(),
                if (actions != null && actions!.isNotEmpty) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.1),
            BamcColors.secondary.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: BamcColors.border.withOpacity(0.3),
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
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(28),
        child: content,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BamcColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!.map((action) {
          if (actions!.indexOf(action) > 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
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
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: PixelIcon(
              iconType: PixelIconType.close,
              size: 20,
              color: _getIconColor(),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_isPressed) {
      return BamcColors.error.withOpacity(0.3);
    }
    if (_isHovered) {
      return BamcColors.error.withOpacity(0.15);
    }
    return Colors.transparent;
  }

  Color _getBorderColor() {
    if (_isPressed || _isHovered) {
      return BamcColors.error;
    }
    return BamcColors.border.withOpacity(0.3);
  }

  Color _getIconColor() {
    if (_isPressed || _isHovered) {
      return BamcColors.error;
    }
    return BamcColors.textSecondary;
  }
}
