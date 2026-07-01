import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

enum BANotificationType {
  success,
  error,
  warning,
  info,
}

class BANotification extends StatelessWidget {
  final BANotificationType type;
  final String title;
  final String? message;
  final VoidCallback? onClose;

  const BANotification({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.onClose,
  });

  Color _accentColor(BuildContext context) {
    switch (type) {
      case BANotificationType.success:
        return BAColors.successOf(context);
      case BANotificationType.error:
        return BAColors.dangerOf(context);
      case BANotificationType.warning:
        return BAColors.warningOf(context);
      case BANotificationType.info:
        return BAColors.primaryOf(context);
    }
  }

  IconData get _icon {
    switch (type) {
      case BANotificationType.success:
        return Icons.check_circle_outline;
      case BANotificationType.error:
        return Icons.error_outline;
      case BANotificationType.warning:
        return Icons.warning_amber_outlined;
      case BANotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(context);
    return Container(
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BATheme.borderRadius,
        boxShadow: BATheme.shadows,
      ),
      child: ClipRRect(
        borderRadius: BATheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: BATheme.blurSigma,
            sigmaY: BATheme.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BATheme.borderRadius,
              border: Border.all(color: BAColors.borderOf(context), width: 1),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: accentColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _icon,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: BATypography.bodyMedium.copyWith(
                                  color: BAColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (message != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  message!,
                                  style: BATypography.bodySmall.copyWith(
                                    color: BAColors.textSecondaryOf(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.close,
                              color: BAColors.textSecondaryOf(context),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNotification extends StatefulWidget {
  final BANotificationType type;
  final String title;
  final String? message;
  final VoidCallback onDismiss;

  const _AnimatedNotification({
    required this.type,
    required this.title,
    this.message,
    required this.onDismiss,
  });

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDismissed) {
        dismiss();
      }
    });
  }

  void dismiss() {
    if (_isDismissed || !mounted) return;
    _isDismissed = true;
    _fadeController.forward().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: BANotification(
          type: widget.type,
          title: widget.title,
          message: widget.message,
          onClose: dismiss,
        ),
      ),
    );
  }
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static const double _topPadding = 16.0;
  static const double _notificationSpacing = 80.0;

  OverlayState? _overlayState;
  final List<OverlayEntry> _activeEntries = [];

  void init(BuildContext context) {
    _overlayState = Overlay.of(context);
  }

  void showSuccess(String title, {String? message}) {
    _show(BANotificationType.success, title, message: message);
  }

  void showError(String title, {String? message}) {
    _show(BANotificationType.error, title, message: message);
  }

  void showWarning(String title, {String? message}) {
    _show(BANotificationType.warning, title, message: message);
  }

  void showInfo(String title, {String? message}) {
    _show(BANotificationType.info, title, message: message);
  }

  void _show(BANotificationType type, String title, {String? message}) {
    if (_overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        final index = _activeEntries.indexOf(entry);
        return Positioned(
          top: _topPadding + (index < 0 ? 0 : index) * _notificationSpacing,
          right: 16,
          child: _AnimatedNotification(
            type: type,
            title: title,
            message: message,
            onDismiss: () {
              entry.remove();
              _activeEntries.remove(entry);
              for (final e in _activeEntries) {
                e.markNeedsBuild();
              }
            },
          ),
        );
      },
    );

    _activeEntries.add(entry);
    _overlayState!.insert(entry);
  }
}