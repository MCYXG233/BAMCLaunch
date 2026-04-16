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
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.background,
          ],
        ),
        border: Border(
          right: BorderSide(
            color: BamcColors.border.withOpacity(0.5),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '资源中心',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BamcColors.primary,
                fontFamily: 'Minecraft',
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 导航项
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
          const Spacer(),
          // 底部信息
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'BAM Launcher',
              style: TextStyle(
                fontSize: 12,
                color: BamcColors.textTertiary,
                fontFamily: 'Minecraft',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
      ResourceCenterTab tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = tab),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BamcColors.primary.withOpacity(0.2),
                        BamcColors.primary.withOpacity(0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? BamcColors.primary
                    : BamcColors.border.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: BamcColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BamcColors.primary,
                              BamcColors.primaryDark,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BamcColors.surface,
                              BamcColors.background,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.5)
                          : BamcColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : BamcColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? BamcColors.primary
                        : BamcColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontFamily: 'Minecraft',
                    fontSize: 14,
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
