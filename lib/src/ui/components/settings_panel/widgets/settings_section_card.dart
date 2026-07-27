import 'package:flutter/material.dart';
import 'settings_theme.dart';

/// 设置分组卡片 - 圆角 + 右上角折叠按钮 + 主体内容
class SettingsSectionCard extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyCollapsed;
  final IconData? titleIcon;
  final Widget? trailing;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.initiallyCollapsed = false,
    this.titleIcon,
    this.trailing,
  });

  @override
  State<SettingsSectionCard> createState() => _SettingsSectionCardState();
}

class _SettingsSectionCardState extends State<SettingsSectionCard> {
  late bool _collapsed = widget.initiallyCollapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsPalette.glassWhite(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SettingsPalette.cardBorder(context),
          width: 0.5,
        ),
        boxShadow: SettingsPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 分组标题栏
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _collapsed ? const Radius.circular(12) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  if (widget.titleIcon != null) ...[
                    Icon(
                      widget.titleIcon,
                      size: 16,
                      color: SettingsPalette.textPrimary(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SettingsPalette.textPrimary(context),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  const SizedBox(width: 4),
                  Icon(
                    _collapsed ? Icons.expand_more : Icons.expand_less,
                    size: 18,
                    color: SettingsPalette.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
            Divider(
              height: 0.5,
              thickness: 0.5,
              color: SettingsPalette.cardBorder(context),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _wrapChildren(widget.children),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _wrapChildren(List<Widget> children) {
    return children
        .map<Widget>(
          (child) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        )
        .toList();
  }
}

/// 设置面板内容卡片 - 用于上方通知/说明类（与 SettingsSectionCard 视觉相同但不可折叠）
class InfoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const InfoCard({super.key, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? SettingsPalette.cardSolid(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SettingsPalette.cardBorder(context),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

/// 设置面板空状态提示（如"当前版本尚不支持此功能"）
class UnsupportedNote extends StatelessWidget {
  final String text;

  const UnsupportedNote({super.key, this.text = '当前版本的 BAMCLaunch 尚不支持此功能。'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: SettingsPalette.textHint(context),
        ),
      ),
    );
  }
}

/// 设置项行 - 左侧图标 + 标题 + 描述 + 右侧 trailing
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SettingsPalette.textSecondary(context)),
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
                    fontWeight: FontWeight.w500,
                    color: SettingsPalette.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.black.withValues(alpha: 0.03),
      child: body,
    );
  }
}

/// 开关行
class SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SettingsPalette.textSecondary(context)),
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
                    fontWeight: FontWeight.w500,
                    color: SettingsPalette.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: SettingsPalette.accent,
            inactiveTrackColor: const Color(0xFFE0E0E5),
            inactiveThumbColor: Colors.white,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// 紧凑下拉选择行 - 左侧标签 + 右侧 Dropdown
class DropdownRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const DropdownRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SettingsPalette.textSecondary(context)),
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
                    fontWeight: FontWeight.w500,
                    color: SettingsPalette.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: SettingsPalette.textSecondary(context),
            ),
            style: TextStyle(
              fontSize: 12,
              color: SettingsPalette.textPrimary(context),
            ),
            items: items,
          ),
        ],
      ),
    );
  }
}

/// 按钮行 - 左侧标签 + 右侧 OutlinedButton
class ButtonRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const ButtonRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SettingsPalette.textSecondary(context)),
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
                    fontWeight: FontWeight.w500,
                    color: SettingsPalette.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: const Size(0, 28),
              side: BorderSide(color: SettingsPalette.cardBorder(context)),
              foregroundColor: SettingsPalette.textPrimary(context),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

/// 滑块行 - 带最小值/最大值标签
class SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? minLabel;
  final String? maxLabel;

  const SliderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.minLabel,
    this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: SettingsPalette.textPrimary(context),
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SettingsPalette.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: SettingsPalette.accent,
              inactiveTrackColor: SettingsPalette.accent.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: SettingsPalette.accent.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 7,
                elevation: 1,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          if (minLabel != null || maxLabel != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: SettingsPalette.textHint(context),
                  ),
                ),
                Text(
                  maxLabel ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: SettingsPalette.textHint(context),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 文本输入行 - 标题 + 副标题 + TextField
class TextFieldRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const TextFieldRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: SettingsPalette.textSecondary(context),
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
                        fontWeight: FontWeight.w500,
                        color: SettingsPalette.textPrimary(context),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 12,
              color: SettingsPalette.textPrimary(context),
            ),
            decoration: InputDecoration(
              isCollapsed: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 11,
                color: SettingsPalette.textHint(context),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: SettingsPalette.cardBorder(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: SettingsPalette.cardBorder(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: SettingsPalette.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
