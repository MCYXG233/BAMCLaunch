import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 资源中心 - Modrinth / CurseForge 默认筛选与缓存
class ResourceCenterSection extends StatelessWidget {
  final String resourceCenterSource;
  final String resourceCenterDefaultType;
  final String resourceCenterSortBy;
  final bool resourceCenterEnableCache;
  final int resourceCenterCacheDuration;
  final bool resourceCenterShowInstalledOnly;
  final bool resourceCenterAutoUpdateResources;
  final ValueChanged<String> onResourceCenterSourceChanged;
  final ValueChanged<String> onResourceCenterDefaultTypeChanged;
  final ValueChanged<String> onResourceCenterSortByChanged;
  final ValueChanged<bool> onResourceCenterEnableCacheChanged;
  final ValueChanged<int> onResourceCenterCacheDurationChanged;
  final ValueChanged<bool> onResourceCenterShowInstalledOnlyChanged;
  final ValueChanged<bool> onResourceCenterAutoUpdateChanged;

  const ResourceCenterSection({
    super.key,
    required this.resourceCenterSource,
    required this.resourceCenterDefaultType,
    required this.resourceCenterSortBy,
    required this.resourceCenterEnableCache,
    required this.resourceCenterCacheDuration,
    required this.resourceCenterShowInstalledOnly,
    required this.resourceCenterAutoUpdateResources,
    required this.onResourceCenterSourceChanged,
    required this.onResourceCenterDefaultTypeChanged,
    required this.onResourceCenterSortByChanged,
    required this.onResourceCenterEnableCacheChanged,
    required this.onResourceCenterCacheDurationChanged,
    required this.onResourceCenterShowInstalledOnlyChanged,
    required this.onResourceCenterAutoUpdateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '资源中心',
      breadcrumbs: const ['下载', '资源中心'],
      children: [
        SettingsSectionCard(
          title: '默认源与类型',
          titleIcon: Icons.inventory_2_outlined,
          children: [
            DropdownRow(
              icon: Icons.public,
              title: '默认源',
              subtitle: '资源中心打开时的默认 API 源',
              value: resourceCenterSource,
              items: const [
                DropdownMenuItem(value: 'modrinth', child: Text('Modrinth')),
                DropdownMenuItem(
                  value: 'curseforge',
                  child: Text('CurseForge'),
                ),
                DropdownMenuItem(value: 'modpack', child: Text('整合包')),
              ],
              onChanged: (v) {
                if (v != null) onResourceCenterSourceChanged(v);
              },
            ),
            DropdownRow(
              icon: Icons.category_outlined,
              title: '默认资源类型',
              subtitle: '打开时直接进入该类型',
              value: resourceCenterDefaultType,
              items: const [
                DropdownMenuItem(value: 'mod', child: Text('Mod')),
                DropdownMenuItem(value: 'modpack', child: Text('整合包')),
                DropdownMenuItem(value: 'resourcepack', child: Text('资源包')),
                DropdownMenuItem(value: 'shader', child: Text('光影')),
                DropdownMenuItem(value: 'world', child: Text('世界')),
              ],
              onChanged: (v) {
                if (v != null) onResourceCenterDefaultTypeChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '筛选与排序',
          titleIcon: Icons.filter_alt_outlined,
          children: [
            DropdownRow(
              icon: Icons.sort_outlined,
              title: '默认排序',
              subtitle: '资源列表的默认排序字段',
              value: resourceCenterSortBy,
              items: const [
                DropdownMenuItem(value: 'relevance', child: Text('相关度')),
                DropdownMenuItem(value: 'downloads', child: Text('下载量')),
                DropdownMenuItem(value: 'follows', child: Text('关注数')),
                DropdownMenuItem(value: 'newest', child: Text('最新发布')),
                DropdownMenuItem(value: 'updated', child: Text('最近更新')),
              ],
              onChanged: (v) {
                if (v != null) onResourceCenterSortByChanged(v);
              },
            ),
            SwitchRow(
              icon: Icons.check_circle_outline,
              title: '仅显示已安装',
              subtitle: '列表自动过滤为已下载过的资源',
              value: resourceCenterShowInstalledOnly,
              onChanged: onResourceCenterShowInstalledOnlyChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '缓存与更新',
          titleIcon: Icons.cached_outlined,
          children: [
            SwitchRow(
              icon: Icons.storage_outlined,
              title: '启用资源缓存',
              subtitle: '减少重复 API 请求，加快二次浏览',
              value: resourceCenterEnableCache,
              onChanged: onResourceCenterEnableCacheChanged,
            ),
            if (resourceCenterEnableCache)
              SliderRow(
                icon: Icons.timer_outlined,
                title: '缓存有效期',
                valueLabel: '$resourceCenterCacheDuration 分钟',
                value: resourceCenterCacheDuration.toDouble(),
                min: 5,
                max: 1440,
                divisions: 47,
                onChanged: (v) =>
                    onResourceCenterCacheDurationChanged(v.toInt()),
                minLabel: '5 分钟',
                maxLabel: '24 小时',
              ),
            SwitchRow(
              icon: Icons.system_update_outlined,
              title: '自动检查资源更新',
              subtitle: '已安装资源有新版本时提醒',
              value: resourceCenterAutoUpdateResources,
              onChanged: onResourceCenterAutoUpdateChanged,
            ),
          ],
        ),
      ],
    );
  }
}
