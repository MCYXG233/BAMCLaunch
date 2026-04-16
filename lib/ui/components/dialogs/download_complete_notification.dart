import 'package:flutter/material.dart';
import '../../utils/effects.dart';
import '../../theme/colors.dart';

class DownloadCompleteNotification extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final VoidCallback? onTap;
  final Duration duration;

  const DownloadCompleteNotification({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<DownloadCompleteNotification> createState() =>
      _DownloadCompleteNotificationState();
}

class _DownloadCompleteNotificationState
    extends State<DownloadCompleteNotification>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = BamcEffects.blockPopAnimation(_controller);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {
                    widget.onTap?.call();
                    _dismiss();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: BamcColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BamcColors.success.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BamcEffects.hoverShadow(),
                        BamcEffects.glowEffect(
                          color: BamcColors.success.withOpacity(0.3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBlockIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BamcColors.textPrimary,
                                ),
                              ),
                              if (widget.subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    widget.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: BamcColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: BamcColors.textSecondary,
                          onPressed: _dismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockIcon() {
    if (widget.icon != null) {
      return widget.icon!;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: BamcEffects.successGradient(),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: BamcColors.success.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

void showDownloadCompleteNotification(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? icon,
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 4),
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topRight,
        child: DownloadCompleteNotification(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: onTap,
          duration: duration,
        ),
      );
    },
  );
}
