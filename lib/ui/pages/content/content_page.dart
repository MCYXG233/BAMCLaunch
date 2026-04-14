import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import './auto_install_page.dart';
import './manual_install_page.dart';
import './mod_download_page.dart';
import './modpack_download_page.dart';
import './resource_pack_download_page.dart';
import './shader_pack_download_page.dart';
import './map_download_page.dart';

enum ResourceCenterTab {
  autoInstall,
  manualInstall,
  modDownload,
  modpackDownload,
  resourcePackDownload,
  shaderPackDownload,
  mapDownload,
}

class ContentPage extends StatefulWidget {
  final IVersionManager versionManager;

  const ContentPage({super.key, required this.versionManager});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  ResourceCenterTab _selectedTab = ResourceCenterTab.autoInstall;

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case ResourceCenterTab.autoInstall:
        return AutoInstallPage(versionManager: widget.versionManager);
      case ResourceCenterTab.manualInstall:
        return const ManualInstallPage();
      case ResourceCenterTab.modDownload:
        return const ModDownloadPage();
      case ResourceCenterTab.modpackDownload:
        return const ModpackDownloadPage();
      case ResourceCenterTab.resourcePackDownload:
        return const ResourcePackDownloadPage();
      case ResourceCenterTab.shaderPackDownload:
        return const ShaderPackDownloadPage();
      case ResourceCenterTab.mapDownload:
        return const MapDownloadPage();
    }
  }

  Widget _buildNavigationMenu() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: BamcColors.surface,
        border: Border(
          right: BorderSide(color: BamcColors.border),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNavigationItem(
            ResourceCenterTab.autoInstall,
            '自动安装',
            Icons.download,
          ),
          _buildNavigationItem(
            ResourceCenterTab.manualInstall,
            '手动安装包',
            Icons.file_upload,
          ),
          _buildNavigationItem(
            ResourceCenterTab.modDownload,
            '模组下载',
            Icons.extension,
          ),
          _buildNavigationItem(
            ResourceCenterTab.modpackDownload,
            '整合包下载',
            Icons.widgets,
          ),
          _buildNavigationItem(
            ResourceCenterTab.resourcePackDownload,
            '资源包下载',
            Icons.image,
          ),
          _buildNavigationItem(
            ResourceCenterTab.shaderPackDownload,
            '光影包下载',
            Icons.brightness_7,
          ),
          _buildNavigationItem(
            ResourceCenterTab.mapDownload,
            '地图存档下载',
            Icons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
      ResourceCenterTab tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = tab),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? BamcColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? BamcColors.primary
                      : BamcColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? BamcColors.primary
                        : BamcColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: BamcColors.surface,
        border: Border(
          bottom: BorderSide(color: BamcColors.border),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '资源中心',
            style: TextStyle(
              color: BamcColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Text('>'),
          const SizedBox(width: 8),
          Text(
            _getTabLabel(_selectedTab),
            style: const TextStyle(
              color: BamcColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTabLabel(ResourceCenterTab tab) {
    switch (tab) {
      case ResourceCenterTab.autoInstall:
        return '自动安装';
      case ResourceCenterTab.manualInstall:
        return '手动安装包';
      case ResourceCenterTab.modDownload:
        return '模组下载';
      case ResourceCenterTab.modpackDownload:
        return '整合包下载';
      case ResourceCenterTab.resourcePackDownload:
        return '资源包下载';
      case ResourceCenterTab.shaderPackDownload:
        return '光影包下载';
      case ResourceCenterTab.mapDownload:
        return '地图存档下载';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          // 左侧导航菜单
          _buildNavigationMenu(),

          // 右侧内容区域
          Expanded(
            child: Column(
              children: [
                // 面包屑导航
                _buildBreadcrumbNavigation(),

                // 内容区域
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
