import 'package:flutter/material.dart';
import 'settings_theme.dart';

/// 设置面板内容区域 - 顶部面包屑 + 标题 + 滚动内容
class SettingsContentArea extends StatelessWidget {
  final String title;
  final List<String> breadcrumbs;
  final List<Widget> children;

  const SettingsContentArea({
    super.key,
    required this.title,
    required this.breadcrumbs,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: child,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (int i = 0; i < breadcrumbs.length; i++) ...[
                    Text(
                      breadcrumbs[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: i == breadcrumbs.length - 1
                            ? SettingsPalette.textSecondary(context)
                            : SettingsPalette.textHint(context),
                      ),
                    ),
                    if (i < breadcrumbs.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.chevron_right,
                          size: 12,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SettingsPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
