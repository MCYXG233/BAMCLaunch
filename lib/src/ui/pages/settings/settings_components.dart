import 'package:flutter/material.dart';

import '../../animations/ba_animations.dart';
import '../../theme/colors.dart';

/// 设置页通用的卡片容器,带标题与分隔线
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);
    final shadowOpacity = isLight ? 0.08 : 0.2;
    final titleText = BAColors.textPrimaryOf(context);
    final accentBlue = BAColors.primaryLightOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: shadowOpacity),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [BAColors.primaryOf(context), accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: titleText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(children.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(height: 1, color: borderColor),
              );
            }
            return children[index ~/ 2];
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 设置页通用的设置项行:图标 + 标题/副标题 + 控件
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.control,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget control;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final primaryText = BAColors.textPrimaryOf(context);
    final secondaryText = BAColors.textSecondaryOf(context);
    final accentBlue = BAColors.primaryLightOf(context);
    final effectiveIconColor = iconColor ?? accentBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          BAAnimations.breathe(
            isActive: true,
            duration: const Duration(milliseconds: 3000),
            minOpacity: 0.85,
            maxOpacity: 1.0,
            glowRadius: 6.0,
            glowColor: effectiveIconColor,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectiveIconColor.withValues(alpha: 0.3),
                    effectiveIconColor.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(color: secondaryText, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }
}

/// 设置页自定义开关
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accentBlueDyn = BAColors.primaryLightOf(context);
    final offBgDyn = BAColors.surfaceTertiaryOf(context);
    final offBorderDyn = BAColors.borderOf(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  colors: [BAColors.primaryOf(context), accentBlueDyn],
                )
              : null,
          color: value ? null : offBgDyn,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? Colors.transparent : offBorderDyn),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 设置页下拉选择控件
class SettingsDropdown<T> extends StatelessWidget {
  const SettingsDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValues = items.map((item) => item.value).toList();
    final effectiveValue = validValues.contains(value)
        ? value
        : items.first.value;
    final fillBg = BAColors.surfaceVariantOf(context);
    final borderColor = BAColors.borderOf(context);
    final primaryText = BAColors.textPrimaryOf(context);
    final secondaryText = BAColors.textSecondaryOf(context);
    final dropdownBg = BAColors.surfaceOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: fillBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue,
          icon: Icon(Icons.keyboard_arrow_down, color: secondaryText, size: 20),
          style: TextStyle(color: primaryText, fontSize: 13),
          dropdownColor: dropdownBg,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 设置页文本输入控件
class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    this.width = 200,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final double width;

  @override
  Widget build(BuildContext context) {
    final fillBg = BAColors.surfaceVariantOf(context);
    final borderColor = BAColors.borderOf(context);
    final primaryText = BAColors.textPrimaryOf(context);
    final secondaryText = BAColors.textSecondaryOf(context);

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(color: primaryText, fontSize: 13),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: secondaryText, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: fillBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: BAColors.primaryOf(context)),
          ),
          isDense: true,
        ),
      ),
    );
  }
}

/// 设置页路径选择控件:显示路径 + 浏览按钮
class SettingsPathSelector extends StatelessWidget {
  const SettingsPathSelector({
    super.key,
    required this.path,
    required this.placeholder,
    required this.buttonText,
    required this.onBrowse,
  });

  final String path;
  final String placeholder;
  final String buttonText;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final fillBg = BAColors.surfaceVariantOf(context);
    final borderColor = BAColors.borderOf(context);
    final primaryText = BAColors.textPrimaryOf(context);
    final secondaryText = BAColors.textSecondaryOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fillBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            path.isEmpty ? placeholder : path,
            style: TextStyle(
              color: path.isEmpty ? secondaryText : primaryText,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        SettingsPrimaryButton(text: buttonText, onPressed: onBrowse),
      ],
    );
  }
}

/// 设置页主按钮(渐变高亮)
class SettingsPrimaryButton extends StatelessWidget {
  const SettingsPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accentBlue = BAColors.primaryLightOf(context);
    final effectiveColor = color ?? accentBlue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color ?? BAColors.primaryOf(context), effectiveColor],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (color ?? BAColors.primaryOf(context)).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 设置页次按钮(扁平描边)
class SettingsSecondaryButton extends StatelessWidget {
  const SettingsSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final offBg = BAColors.surfaceTertiaryOf(context);
    final borderColor = BAColors.borderOf(context);
    final accentBlue = BAColors.primaryLightOf(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: offBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
