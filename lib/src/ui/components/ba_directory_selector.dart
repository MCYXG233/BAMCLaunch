import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../../modpack/modpack_import_dialog.dart';
import '../theme/colors.dart';
import 'ba_notification.dart';

/// 游戏目录选择器
///
/// 触发按钮：胶囊样式，显示当前目录名 + 路径 + 下拉箭头
/// 弹窗：自定义下拉面板
///   - 列表：所有已添加目录，当前选中高亮
///   - 分组：添加文件夹 / 导入整合包
///
/// 视觉风格遵循 BAMCLaunch 的玻璃拟态 + 渐变语言。
/// 不模仿第三方启动器（PCL/Hello Minecraft!/BakaXL）的强品牌色标题栏。
class BADirectorySelector extends StatefulWidget {
  /// 触发按钮的宽度范围（左右留白由调用方控制）
  final double? width;

  /// 添加新目录后的回调（用于刷新上层数据）
  final VoidCallback? onChanged;

  const BADirectorySelector({super.key, this.width, this.onChanged});

  @override
  State<BADirectorySelector> createState() => _BADirectorySelectorState();
}

class _BADirectorySelectorState extends State<BADirectorySelector> {
  final InstanceManager _manager = InstanceManager();
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  InstanceDirectory? get _selected {
    final id = _manager.selectedDirectoryId;
    if (id == null) return null;
    try {
      return _manager.directories.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void _toggle() {
    if (_open) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  void _showOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _DirectoryDropdown(
        anchorRect: Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
        onDismiss: _removeOverlay,
        onSelect: (id) async {
          _removeOverlay();
          await _selectDirectory(id);
        },
        onAddFolder: () async {
          _removeOverlay();
          await _addFolder();
        },
        onImportModpack: () async {
          _removeOverlay();
          await _importModpack();
        },
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _open = true);
  }

  Future<void> _selectDirectory(String id) async {
    try {
      await _manager.selectDirectory(id);
      widget.onChanged?.call();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('切换失败', message: e.toString());
      }
    }
  }

  Future<void> _addFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择游戏目录',
    );
    if (result == null || result.isEmpty) return;

    // 目录特征校验：检查是否包含 versions/ 或 mods/ 子目录
    final isValid = await _validateMinecraftDirectory(result);
    if (!isValid && mounted) {
      final proceed = await _showInvalidDirectoryDialog(result);
      if (proceed != true) return;
    }

    try {
      final name = result.split(Platform.pathSeparator).last;
      await _manager.createDirectory(name: name, path: result);
      widget.onChanged?.call();
      if (mounted) {
        NotificationManager().showSuccess('已添加', message: name);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加失败', message: e.toString());
      }
    }
  }

  /// 校验目录是否像 Minecraft 游戏目录
  ///
  /// 特征：包含 `versions/` 或 `mods/` 子目录
  /// （任意一项即可，避免空目录被误判）
  Future<bool> _validateMinecraftDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return false;

      final versionsDir = Directory('${dir.path}${Platform.pathSeparator}versions');
      final modsDir = Directory('${dir.path}${Platform.pathSeparator}mods');
      return (await versionsDir.exists()) || (await modsDir.exists());
    } catch (_) {
      return false;
    }
  }

  /// 当目录不像 Minecraft 时弹确认对话框
  ///
  /// 返回 `true` 表示用户确认仍要添加，`false`/`null` 表示取消
  Future<bool?> _showInvalidDirectoryDialog(String path) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BAColors.surfaceOf(ctx),
        title: const Text('目录可能不是游戏目录'),
        content: Text(
          '所选目录未检测到 versions/ 或 mods/ 子目录：\n\n$path\n\n是否仍要添加？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('仍要添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _importModpack() async {
    // ModpackImportDialog.show 内部自带文件选择器
    if (!mounted) return;
    final result = await ModpackImportDialog.show(context);
    if (result != null) {
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final hasMultiple = _manager.directories.length > 1;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: _anchorKey,
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _open
                ? BAColors.primaryOf(context).withValues(alpha: 0.18)
                : BAColors.surfaceOf(context).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _open
                  ? BAColors.primaryOf(context).withValues(alpha: 0.6)
                  : BAColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_rounded,
                size: 16,
                color: BAColors.primaryLightOf(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  selected?.name ?? '未选择目录',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasMultiple || true) ...[
                const SizedBox(width: 4),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _open ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: BAColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 下拉浮层
class _DirectoryDropdown extends StatelessWidget {
  final Rect anchorRect;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddFolder;
  final VoidCallback onImportModpack;

  const _DirectoryDropdown({
    required this.anchorRect,
    required this.onDismiss,
    required this.onSelect,
    required this.onAddFolder,
    required this.onImportModpack,
  });

  @override
  Widget build(BuildContext context) {
    final manager = InstanceManager();
    final selectedId = manager.selectedDirectoryId;
    final directories = manager.directories;

    return Positioned.fill(
      child: Stack(
        children: [
          // 点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
            ),
          ),
          // 浮层本体
          Positioned(
            left: anchorRect.left,
            top: anchorRect.bottom + 6,
            width: 320,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (directories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '暂无游戏目录，请先添加',
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: directories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final d = directories[index];
                            final isSelected = d.id == selectedId;
                            return _DirectoryItem(
                              directory: d,
                              selected: isSelected,
                              onTap: () => onSelect(d.id),
                            );
                          },
                        ),
                      ),
                    Container(
                      height: 1,
                      color: BAColors.borderOf(context).withValues(alpha: 0.4),
                    ),
                    _DirectoryAction(
                      icon: Icons.create_new_folder_rounded,
                      label: '添加已有文件夹',
                      onTap: onAddFolder,
                    ),
                    _DirectoryAction(
                      icon: Icons.inventory_2_rounded,
                      label: '导入整合包',
                      onTap: onImportModpack,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryItem extends StatelessWidget {
  final InstanceDirectory directory;
  final bool selected;
  final VoidCallback onTap;

  const _DirectoryItem({
    required this.directory,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: selected
              ? BAColors.primaryOf(context).withValues(alpha: 0.18)
              : null,
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.folder_outlined,
                size: 16,
                color: selected
                    ? BAColors.primaryLightOf(context)
                    : BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      directory.name,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      directory.path,
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DirectoryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: BAColors.primaryLightOf(context)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
