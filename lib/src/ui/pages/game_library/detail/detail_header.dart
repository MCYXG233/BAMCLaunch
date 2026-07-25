import 'package:flutter/material.dart';

import '../../../../instance/models.dart';
import '../../../theme/colors.dart';

/// 详情页顶部栏
///
/// 展示返回按钮、实例图标、实例名称/版本、启动按钮
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.instance,
    required this.launchingIds,
    required this.onBack,
    required this.onLaunch,
  });

  final GameInstance instance;

  /// 正在启动的实例 ID 集合
  final Set<String> launchingIds;

  final VoidCallback onBack;
  final void Function(GameInstance instance) onLaunch;

  @override
  Widget build(BuildContext context) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = launchingIds.contains(instance.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
      child: Row(
        children: [
          // 返回按钮
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: BAColors.primaryLightOf(context),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 实例图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFFFFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // 实例名称和版本
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instance.name,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                ),
              ],
            ),
          ),

          // 启动按钮
          if (isLaunching)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      BAColors.warningOf(context),
                    ),
                  ),
                ),
              ),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isRunning ? null : () => onLaunch(instance),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isRunning
                          ? [BAColors.successOf(context), BAColors.successDark]
                          : [
                              BAColors.primaryLightOf(context),
                              BAColors.primaryOf(context),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isRunning
                                    ? BAColors.successOf(context)
                                    : BAColors.primaryOf(context))
                                .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFFFFFFFF),
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
