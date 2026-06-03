import 'package:flutter/material.dart';
import 'dart:convert';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../core/logger.dart';

/// 元素在布局中的位置
enum LayoutAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// 可配置的界面元素
enum LayoutElement {
  mainPanel,
  bottomNavBar,
  titleBar,
  sidebar,
  quickLaunch,
  newsPanel,
  friendPanel,
  accountPanel,
  settingButton,
  minimizeButton,
  closeButton,
}

/// 布局配置条目
class LayoutConfigItem {
  final LayoutElement element;
  final bool visible;
  final Offset position;
  final Size size;
  final double opacity;
  final LayoutAnchor anchor;

  LayoutConfigItem({
    required this.element,
    this.visible = true,
    this.position = Offset.zero,
    this.size = Size.zero,
    this.opacity = 1.0,
    this.anchor = LayoutAnchor.topLeft,
  });

  LayoutConfigItem copyWith({
    LayoutElement? element,
    bool? visible,
    Offset? position,
    Size? size,
    double? opacity,
    LayoutAnchor? anchor,
  }) {
    return LayoutConfigItem(
      element: element ?? this.element,
      visible: visible ?? this.visible,
      position: position ?? this.position,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      anchor: anchor ?? this.anchor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'element': element.name,
      'visible': visible,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'size': {
        'width': size.width,
        'height': size.height,
      },
      'opacity': opacity,
      'anchor': anchor.name,
    };
  }

  factory LayoutConfigItem.fromJson(Map<String, dynamic> json) {
    return LayoutConfigItem(
      element: LayoutElement.values.firstWhere(
        (e) => e.name == json['element'],
        orElse: () => LayoutElement.mainPanel,
      ),
      visible: json['visible'] as bool? ?? true,
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0,
      ),
      size: Size(
        (json['size']?['width'] as num?)?.toDouble() ?? 0,
        (json['size']?['height'] as num?)?.toDouble() ?? 0,
      ),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      anchor: LayoutAnchor.values.firstWhere(
        (e) => e.name == json['anchor'],
        orElse: () => LayoutAnchor.topLeft,
      ),
    );
  }
}

/// 布局管理器
class LayoutManager extends ChangeNotifier {
  static LayoutManager? _instance;

  factory LayoutManager() {
    _instance ??= LayoutManager._internal();
    return _instance!;
  }

  LayoutManager._internal();

  final Logger _logger = Logger('LayoutManager');
  final ConfigManager _configManager = ConfigManager();

  final Map<LayoutElement, LayoutConfigItem> _items = {};
  bool _layoutEditMode = false;

  Map<LayoutElement, LayoutConfigItem> get items => Map.unmodifiable(_items);
  bool get editMode => _layoutEditMode;

  /// 初始化默认布局
  void initializeDefaults(Size screenSize) {
    _items.clear();

    _items[LayoutElement.mainPanel] = LayoutConfigItem(
      element: LayoutElement.mainPanel,
      visible: true,
      position: Offset(screenSize.width * 0.02, screenSize.height * 0.1),
      size: Size(screenSize.width * 0.96, screenSize.height * 0.75),
      anchor: LayoutAnchor.topLeft,
    );

    _items[LayoutElement.bottomNavBar] = LayoutConfigItem(
      element: LayoutElement.bottomNavBar,
      visible: true,
      position: Offset(screenSize.width * 0.02, screenSize.height * 0.88),
      size: Size(screenSize.width * 0.96, 80),
      anchor: LayoutAnchor.bottomLeft,
    );

    _items[LayoutElement.titleBar] = LayoutConfigItem(
      element: LayoutElement.titleBar,
      visible: true,
      position: Offset.zero,
      size: Size(screenSize.width, 50),
      anchor: LayoutAnchor.topLeft,
    );

    _items[LayoutElement.settingButton] = LayoutConfigItem(
      element: LayoutElement.settingButton,
      visible: true,
      position: Offset(screenSize.width - 150, 10),
      size: const Size(40, 40),
      anchor: LayoutAnchor.topRight,
    );

    _items[LayoutElement.minimizeButton] = LayoutConfigItem(
      element: LayoutElement.minimizeButton,
      visible: true,
      position: Offset(screenSize.width - 100, 10),
      size: const Size(40, 40),
      anchor: LayoutAnchor.topRight,
    );

    _items[LayoutElement.closeButton] = LayoutConfigItem(
      element: LayoutElement.closeButton,
      visible: true,
      position: Offset(screenSize.width - 50, 10),
      size: const Size(40, 40),
      anchor: LayoutAnchor.topRight,
    );

    notifyListeners();
  }

  /// 加载保存的布局
  Future<void> loadLayout() async {
    try {
      await _configManager.initialize();
      final jsonString = _configManager.getString(ConfigKeys.layoutConfig);

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        _items.clear();

        for (final entry in json.entries) {
          if (entry.value is Map) {
            final element = LayoutElement.values.firstWhere(
              (e) => e.name == entry.key,
              orElse: () => LayoutElement.mainPanel,
            );

            _items[element] = LayoutConfigItem.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }

        _logger.info('Layout loaded successfully');
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Failed to load layout: $e');
    }
  }

  /// 保存布局
  Future<void> saveLayout() async {
    try {
      await _configManager.initialize();

      final Map<String, dynamic> json = {};
      for (final entry in _items.entries) {
        json[entry.key.name] = entry.value.toJson();
      }

      await _configManager.setString(
        ConfigKeys.layoutConfig,
        jsonEncode(json),
      );

      _logger.info('Layout saved successfully');
    } catch (e) {
      _logger.error('Failed to save layout', e);
    }
  }

  /// 进入编辑模式
  void enterEditMode() {
    _layoutEditMode = true;
    notifyListeners();
  }

  /// 退出编辑模式
  void exitEditMode() {
    _layoutEditMode = false;
    saveLayout();
    notifyListeners();
  }

  /// 更新元素配置
  void updateItem(LayoutElement element, LayoutConfigItem config) {
    _items[element] = config;
    notifyListeners();
  }

  /// 切换元素可见性
  void toggleVisibility(LayoutElement element) {
    if (_items.containsKey(element)) {
      _items[element] = _items[element]!.copyWith(
        visible: !_items[element]!.visible,
      );
      notifyListeners();
    }
  }

  /// 重设为默认
  Future<void> resetToDefault(Size screenSize) async {
    initializeDefaults(screenSize);
    await saveLayout();
  }

  /// 获取元素配置
  LayoutConfigItem? getItem(LayoutElement element) {
    return _items[element];
  }

  /// 获取可编辑的布局元素列表
  List<LayoutElement> getEditableElements() {
    return LayoutElement.values.toList();
  }
}

/// 可拖拽的布局元素
class DraggableLayoutElement extends StatefulWidget {
  final LayoutElement element;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const DraggableLayoutElement({
    super.key,
    required this.element,
    required this.child,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<DraggableLayoutElement> createState() =>
      _DraggableLayoutElementState();
}

class _DraggableLayoutElementState extends State<DraggableLayoutElement> {
  final LayoutManager _layoutManager = LayoutManager();
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final config = _layoutManager.getItem(widget.element);
    if (config == null || !config.visible) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _layoutManager,
      builder: (context, child) {
        return Positioned(
          left: config.position.dx,
          top: config.position.dy,
          width: config.size.width,
          height: config.size.height,
          child: _buildContent(config),
        );
      },
    );
  }

  Widget _buildContent(LayoutConfigItem config) {
    final isEditMode = _layoutManager.editMode;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onPanStart: isEditMode
          ? (details) {
              setState(() {
                _isDragging = true;
                _dragOffset = details.localPosition;
              });
            }
          : null,
      onPanUpdate: isEditMode
          ? (details) {
              if (!_isDragging) return;

              final newPosition = Offset(
                config.position.dx + details.delta.dx,
                config.position.dy + details.delta.dy,
              );

              _layoutManager.updateItem(
                widget.element,
                config.copyWith(position: newPosition),
              );
            }
          : null,
      onPanEnd: isEditMode
          ? (_) {
              setState(() => _isDragging = false);
            }
          : null,
      child: Opacity(
        opacity: config.opacity,
        child: Stack(
          children: [
            widget.child,
            if (isEditMode && _isDragging)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 布局编辑器控件
class LayoutEditorControls extends StatelessWidget {
  final LayoutManager layoutManager;

  const LayoutEditorControls({
    super.key,
    required this.layoutManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: layoutManager,
      builder: (context, child) {
        if (!layoutManager.editMode) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => layoutManager.exitEditMode(),
                icon: const Icon(Icons.check, color: Colors.green),
                label: const Text('完成', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  if (mounted) {
                    final size = MediaQuery.of(context).size;
                    layoutManager.resetToDefault(size);
                  }
                },
                icon: const Icon(Icons.restore, color: Colors.orange),
                label: const Text('重置', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 元素可见性开关面板
class ElementVisibilityPanel extends StatelessWidget {
  final LayoutManager layoutManager;

  const ElementVisibilityPanel({
    super.key,
    required this.layoutManager,
  });

  @override
  Widget build(BuildContext context) {
    final elements = layoutManager.getEditableElements();

    return ListenableBuilder(
      listenable: layoutManager,
      builder: (context, child) {
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '显示/隐藏元素',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...elements.map((element) => _buildSwitch(element)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitch(LayoutElement element) {
    final config = layoutManager.getItem(element);
    final name = _getElementName(element);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          Switch(
            value: config?.visible ?? true,
            onChanged: (value) => layoutManager.toggleVisibility(element),
          ),
        ],
      ),
    );
  }

  String _getElementName(LayoutElement element) {
    switch (element) {
      case LayoutElement.mainPanel:
        return '主面板';
      case LayoutElement.bottomNavBar:
        return '底部导航栏';
      case LayoutElement.titleBar:
        return '标题栏';
      case LayoutElement.sidebar:
        return '侧边栏';
      case LayoutElement.quickLaunch:
        return '快速启动';
      case LayoutElement.newsPanel:
        return '新闻面板';
      case LayoutElement.friendPanel:
        return '好友面板';
      case LayoutElement.accountPanel:
        return '账户面板';
      case LayoutElement.settingButton:
        return '设置按钮';
      case LayoutElement.minimizeButton:
        return '最小化按钮';
      case LayoutElement.closeButton:
        return '关闭按钮';
    }
  }
}
