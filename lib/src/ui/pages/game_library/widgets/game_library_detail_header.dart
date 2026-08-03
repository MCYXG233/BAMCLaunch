import 'package:flutter/material.dart';
import '../../../../instance/models.dart';
import '../../../theme/colors.dart';

class GameLibraryDetailHeader extends StatelessWidget {
  final GameInstance instance;
  final bool isRunning;
  final bool isLaunching;
  final VoidCallback onBack;
  final VoidCallback onLaunchGame;

  const GameLibraryDetailHeader({
    super.key,
    required this.instance,
    required this.isRunning,
    required this.isLaunching,
    required this.onBack,
    required this.onLaunchGame,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = isRunning ? '运行中' : (isLaunching ? '启动中' : '未启动');
    final statusColor = isRunning
        ? BAColors.successOf(context)
        : (isLaunching
              ? BAColors.warningOf(context)
              : BAColors.textDisabledOf(context));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 24, 8),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: BAColors.primaryLightOf(context),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFFFFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: isRunning || isLaunching
                            ? [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        instance.name,
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${instance.version}${instance.loader != null ? ' · ${instance.loader}' : ''}',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isLaunching)
            _buildActionButton(
              context,
              icon: null,
              label: '启动中',
              showSpinner: true,
              onTap: null,
              gradient: [BAColors.warningOf(context), BAColors.warningDark],
            )
          else
            _buildActionButton(
              context,
              icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: isRunning ? '停止' : '启动',
              showSpinner: false,
              onTap: isRunning ? null : onLaunchGame,
              gradient: isRunning
                  ? [BAColors.successOf(context), BAColors.successDark]
                  : [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData? icon,
    required String label,
    required bool showSpinner,
    required VoidCallback? onTap,
    required List<Color> gradient,
  }) {
    final disabled = onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? gradient.map((c) => c.withValues(alpha: 0.5)).toList()
                  : gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: gradient.last.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white, size: 16),
              if (showSpinner || icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
