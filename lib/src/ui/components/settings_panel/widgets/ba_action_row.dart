import 'package:flutter/material.dart';
import 'settings_theme.dart';

/// 点击跳出型设置行
///
/// 用于"账号管理 / 主题编辑器 / 镜像测速 / 备份历史"等点击后弹出对话框/页面的设置项。
///
/// 设计要点：
/// - 整行可点击，hover 时背景提亮
/// - 右侧 chevron 箭头 + 副值预览，明确表达"可点开"
/// - 左侧彩色徽章图标 + 渐变背景
class BAActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// 右侧显示的当前值（如账号用户名、当前主题名等）
  final String? valueLabel;

  /// 主色调（默认主题紫）
  final Color? accentColor;

  /// 点击回调
  final VoidCallback onTap;

  const BAActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueLabel,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SettingsPalette.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: SettingsPalette.glassWhiteHover(context),
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              // 左侧渐变徽章
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 12),
              // 中间标题 + 描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SettingsPalette.textPrimary(context),
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧值预览
              if (valueLabel != null && valueLabel!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    valueLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: SettingsPalette.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              // chevron 箭头
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: SettingsPalette.textHint(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 信息预览行（只读，不响应点击）
class BAInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String valueLabel;
  final Color? accentColor;

  const BAInfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.valueLabel,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SettingsPalette.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SettingsPalette.textPrimary(context),
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valueLabel,
              style: TextStyle(
                fontSize: 12,
                color: SettingsPalette.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}