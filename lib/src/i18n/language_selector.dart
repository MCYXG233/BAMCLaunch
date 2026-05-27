import 'package:flutter/material.dart';
import '../ui/theme/ba_theme_colors.dart';
import 'ba_localization.dart';

class BALanguageSelector extends StatefulWidget {
  final ValueChanged<Locale>? onLanguageChanged;

  const BALanguageSelector({super.key, this.onLanguageChanged});

  @override
  State<BALanguageSelector> createState() => _BALanguageSelectorState();
}

class _BALanguageSelectorState extends State<BALanguageSelector> {
  bool _isHovered = false;

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      locale: Locale('zh', 'CN'),
      label: '简体中文',
      flag: '🇨🇳',
    ),
    _LanguageOption(
      locale: Locale('en', 'US'),
      label: 'English',
      flag: '🇺🇸',
    ),
  ];

  _LanguageOption get _current {
    final currentLocale = BALocalizations.instance.locale;
    return _languages.firstWhere(
      (l) => l.locale.languageCode == currentLocale.languageCode,
      orElse: () => _languages.first,
    );
  }

  void _onSelect(_LanguageOption option) {
    if (option.locale.languageCode != _current.locale.languageCode) {
      BALocalizations.instance.setLocale(option.locale);
      widget.onLanguageChanged?.call(option.locale);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: PopupMenuButton<_LanguageOption>(
        onSelected: _onSelect,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: BAThemeColors.border),
        ),
        color: BAThemeColors.surface,
        itemBuilder: (_) => _languages
            .map(
              (option) => PopupMenuItem<_LanguageOption>(
                value: option,
                child: Row(
                  children: [
                    Text(option.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(
                      option.label,
                      style: TextStyle(
                        color: option.locale.languageCode ==
                                current.locale.languageCode
                            ? BAThemeColors.primary
                            : BAThemeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: option.locale.languageCode ==
                                current.locale.languageCode
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (option.locale.languageCode ==
                        current.locale.languageCode) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check,
                        color: BAThemeColors.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? BAThemeColors.surfaceHover
                : BAThemeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? BAThemeColors.primary.withValues(alpha: 0.5)
                  : BAThemeColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                current.label,
                style: const TextStyle(
                  color: BAThemeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: BAThemeColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final Locale locale;
  final String label;
  final String flag;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.flag,
  });
}
