import 'package:flutter/material.dart';

class KeyboardShortcuts {
  static void registerShortcuts() {
    // 键盘快捷键功能暂时禁用
  }
}

extension KeyboardShortcutExtension on Widget {
  Widget withKeyboardShortcuts(Map<LogicalKeySet, VoidCallback> shortcuts) {
    return this;
  }
}
