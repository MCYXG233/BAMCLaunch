import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../instance/models.dart';

/// 资源中心共享常量与映射
class ResourceConstants {
  ResourceConstants._();

  /// Modrinth 类型筛选选项
  static const modrinthTypeOptions = <MapEntry<String, ResourceType?>>[
    MapEntry('全部', null),
    MapEntry('模组', ResourceType.mod),
    MapEntry('资源包', ResourceType.resourcePack),
    MapEntry('整合包', ResourceType.modpack),
    MapEntry('光影包', ResourceType.shaderPack),
    MapEntry('数据包', ResourceType.dataPack),
  ];

  /// 排序选项
  static const sortOptions = <MapEntry<String, String>>[
    MapEntry('downloads', '最多下载'),
    MapEntry('newest', '最新发布'),
    MapEntry('updated', '最近更新'),
    MapEntry('name', '按名称'),
  ];

  /// 游戏版本列表
  static const gameVersions = [
    '1.21.4',
    '1.21.1',
    '1.20.6',
    '1.20.4',
    '1.20.1',
    '1.19.4',
    '1.18.2',
    '1.16.5',
    '1.12.2',
  ];

  /// 加载器列表
  static const loaders = <MapEntry<String, String>>[
    MapEntry('fabric', 'Fabric'),
    MapEntry('forge', 'Forge'),
    MapEntry('quilt', 'Quilt'),
    MapEntry('neoforge', 'NeoForge'),
  ];

  /// 类型 → 图标
  static const Map<ResourceType?, IconData> typeIcons = {
    null: Icons.apps,
    ResourceType.mod: Icons.extension,
    ResourceType.resourcePack: Icons.palette,
    ResourceType.modpack: Icons.inventory_2,
    ResourceType.shaderPack: Icons.lightbulb,
    ResourceType.dataPack: Icons.folder_copy,
  };

  /// 类型 → 颜色（依赖主题，需 context）
  static Map<ResourceType?, Color> typeColorsOf(BuildContext context) => {
    null: BAColors.primaryOf(context),
    ResourceType.mod: BAColors.accentPinkOf(context),
    ResourceType.resourcePack: BAColors.successOf(context),
    ResourceType.modpack: BAColors.warningOf(context),
    ResourceType.shaderPack: const Color(0xFFE6C46A),
    ResourceType.dataPack: const Color(0xFF7AA5D6),
  };
}
