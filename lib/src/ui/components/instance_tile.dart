import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'ba_context_menu.dart';

/// 蔚蓝档案风格实例卡片（BakaXL 排版）
///
/// 设计要点：
/// - 紧凑横向布局：图标 + 标题/副标题 + 状态点
/// - 选中态：紫色边框 + 浅紫背景
/// - hover 态：轻微上浮（不放大）
/// - 状态点：绿色脉冲=运行中 / 橙色脉冲=启动中 / 灰色=停止
class InstanceTile extends StatefulWidget {
  /// 实例名称（也作为标题）
  final String name;

  /// 副标题（如 "Mojang · 1.20.1 · Forge 47.4.10"）
  final String subtitle;

  /// 实例图标文件（可选）
  final File? iconFile;

  /// 默认图标（无 iconFile 时使用）
  final IconData defaultIcon;

  /// 默认图标的渐变色
  final List<Color> defaultIconColors;

  /// 当前状态
  final InstanceTileStatus status;

  /// 是否选中
  final bool selected;

  /// 点击回调
  final VoidCallback? onTap;

  /// 右键菜单
  final List<BAContextMenuItem>? contextMenuItems;

  const InstanceTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.iconFile,
    this.defaultIcon = Icons.widgets_rounded,
    this.defaultIconColors = const [Color(0xFF7AB3F0), Color(0xFF4A90D9)],
    this.status = InstanceTileStatus.stopped,
    this.selected = false,
    this.onTap,
    this.contextMenuItems,
  });

  @override
  State<InstanceTile> createState() => _InstanceTileState();
}

class _InstanceTileState extends State<InstanceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = BAColors.primaryOf(context);
    final borderColor = widget.selected
        ? primary.withValues(alpha: 0.75)
        : (_hovered
              ? primary.withValues(alpha: 0.35)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.85)));
    final bgColor = widget.selected
        ? primary.withValues(alpha: 0.10)
        : (_hovered
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.65)));

    Widget card = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: widget.selected ? 1.5 : 1,
          ),
          boxShadow: [
            if (widget.selected || _hovered)
              BoxShadow(
                color: primary.withValues(alpha: widget.selected ? 0.25 : 0.12),
                blurRadius: widget.selected ? 18 : 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        transform: _hovered && !widget.selected
            ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BAColors.textPrimaryOf(context),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (widget.subtitle.isNotEmpty)
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: BAColors.textSecondaryOf(context),
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusDot(context),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.contextMenuItems != null &&
        widget.contextMenuItems!.isNotEmpty) {
      card = BAContextMenu(items: widget.contextMenuItems!, child: card);
    }

    return card;
  }

  Widget _buildIcon(BuildContext context) {
    const size = 44.0;
    final radius = BorderRadius.circular(10);
    final hasFile = widget.iconFile != null && widget.iconFile!.existsSync();

    Widget content;
    if (hasFile) {
      content = ClipRRect(
        borderRadius: radius,
        child: Image.file(
          widget.iconFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackIcon(context),
        ),
      );
    } else {
      content = _buildFallbackIcon(context);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: content,
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.defaultIconColors,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(widget.defaultIcon, size: 20, color: Colors.white),
    );
  }

  Widget _buildStatusDot(BuildContext context) {
    final (color, pulse) = switch (widget.status) {
      InstanceTileStatus.running => (BAColors.successOf(context), true),
      InstanceTileStatus.launching => (BAColors.warningOf(context), true),
      InstanceTileStatus.stopped => (BAColors.textDisabledOf(context), false),
    };
    final dot = Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: pulse
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (!pulse) return dot;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 1100),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: dot,
    );
  }
}

/// 实例状态
enum InstanceTileStatus {
  /// 正在运行
  running,

  /// 启动中
  launching,

  /// 已停止
  stopped,
}
