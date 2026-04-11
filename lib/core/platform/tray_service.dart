typedef TrayMenuItemCallback = void Function(String id);

class TrayMenuItem {
  final String id;
  final String label;
  final bool enabled;
  final bool checked;

  TrayMenuItem({
    required this.id,
    required this.label,
    this.enabled = true,
    this.checked = false,
  });
}

class TrayService {
  static TrayService? _instance;
  
  bool _initialized = false;
  String? _iconPath;
  String? _tooltip;
  final List<TrayMenuItem> _menuItems = [];
  TrayMenuItemCallback? _onMenuItemSelected;

  TrayService._internal();

  static TrayService getInstance() {
    _instance ??= TrayService._internal();
    return _instance!;
  }

  Future<void> initialize(String iconPath, String tooltip) async {
    _iconPath = iconPath;
    _tooltip = tooltip;
    _initialized = true;
  }

  Future<void> show() async {
    if (!_initialized) {
      throw Exception('Tray not initialized');
    }
  }

  Future<void> hide() async {
    if (!_initialized) {
      throw Exception('Tray not initialized');
    }
  }

  Future<void> setTooltip(String tooltip) async {
    _tooltip = tooltip;
  }

  Future<void> setMenu(List<TrayMenuItem> items, TrayMenuItemCallback onSelected) async {
    _menuItems.clear();
    _menuItems.addAll(items);
    _onMenuItemSelected = onSelected;
  }

  void handleMenuItemSelected(String id) {
    _onMenuItemSelected?.call(id);
  }

  Future<void> dispose() async {
    _initialized = false;
    _iconPath = null;
    _tooltip = null;
    _menuItems.clear();
    _onMenuItemSelected = null;
  }
}
