import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../instance/models.dart';
import '../../../theme/colors.dart';
import 'detail_header.dart';
import 'file_list_tab.dart';
import 'overview_tab.dart';
import 'screenshot_tab.dart';

/// 实例详情页容器
///
/// 详情页的入口,负责组合 header/tab bar/各 tab 内容,
/// 自身不持有任何业务状态,所有状态由父级 [BAGameLibraryPage] 通过参数注入
class InstanceDetailPage extends StatelessWidget {
  const InstanceDetailPage({
    super.key,
    required this.instance,
    required this.detailTabController,
    required this.detailTabs,
    required this.launchingIds,
    required this.isLoadingFiles,
    required this.detailFiles,
    required this.onBack,
    required this.onLaunch,
    required this.onDuplicate,
    required this.onExport,
    required this.onOpenBackupManager,
    required this.onOpenModManager,
    required this.onDelete,
    required this.onOpenFile,
  });

  final GameInstance instance;
  final TabController detailTabController;
  final List<String> detailTabs;

  /// 正在启动的实例 ID 集合,用于决定启动按钮是否显示 loading
  final Set<String> launchingIds;

  /// 文件 tab 是否正在加载
  final bool isLoadingFiles;

  /// 当前 tab 的文件列表(概览 tab 为空)
  final List<FileSystemEntity> detailFiles;

  final VoidCallback onBack;
  final void Function(GameInstance instance) onLaunch;
  final void Function(GameInstance instance) onDuplicate;
  final void Function(GameInstance instance) onExport;
  final void Function(GameInstance instance) onOpenBackupManager;
  final void Function(GameInstance instance) onOpenModManager;
  final void Function(GameInstance instance) onDelete;
  final void Function(String path) onOpenFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DetailHeader(
          instance: instance,
          launchingIds: launchingIds,
          onBack: onBack,
          onLaunch: onLaunch,
        ),
        _buildDetailTabBar(context),
        Expanded(
          child: TabBarView(
            controller: detailTabController,
            children: [
              OverviewTab(
                instance: instance,
                launchingIds: launchingIds,
                onLaunch: onLaunch,
                onDuplicate: onDuplicate,
                onExport: onExport,
                onOpenBackupManager: onOpenBackupManager,
                onOpenModManager: onOpenModManager,
                onDelete: onDelete,
              ),
              FileListTab(
                emptyMessage: '还没有存档',
                emptyIcon: Icons.folder_rounded,
                isLoadingFiles: isLoadingFiles,
                detailFiles: detailFiles,
                onOpenFile: onOpenFile,
              ),
              FileListTab(
                emptyMessage: '还没有模组',
                emptyIcon: Icons.extension_rounded,
                isLoadingFiles: isLoadingFiles,
                detailFiles: detailFiles,
                onOpenFile: onOpenFile,
              ),
              FileListTab(
                emptyMessage: '还没有资源包',
                emptyIcon: Icons.palette_rounded,
                isLoadingFiles: isLoadingFiles,
                detailFiles: detailFiles,
                onOpenFile: onOpenFile,
              ),
              FileListTab(
                emptyMessage: '还没有光影包',
                emptyIcon: Icons.brightness_7_rounded,
                isLoadingFiles: isLoadingFiles,
                detailFiles: detailFiles,
                onOpenFile: onOpenFile,
              ),
              ScreenshotTab(
                isLoadingFiles: isLoadingFiles,
                detailFiles: detailFiles,
                onOpenFile: onOpenFile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 详情页子Tab栏
  Widget _buildDetailTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: detailTabController,
        isScrollable: true,
        labelColor: const Color(0xFFFFFFFF),
        unselectedLabelColor: BAColors.textSecondaryOf(context),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BAColors.primaryLightOf(context),
              BAColors.primaryOf(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: BAColors.primaryOf(context).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(10),
        tabs: detailTabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
