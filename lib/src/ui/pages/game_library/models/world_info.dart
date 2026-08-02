import 'dart:io';

/// 世界信息（用于概览Tab的世界列表）
///
/// 数据源：实例 saves/ 目录的子文件夹（必须含 level.dat 才视为有效世界）。
/// `iconFile` 指向 `<world>/icon.png`（若存在），否则渲染回退图标。
class WorldInfo {
  final String name;
  final String subtitle;
  final String lastPlayed;
  final File? iconFile;
  final bool isRecent;

  WorldInfo({
    required this.name,
    this.subtitle = '',
    this.lastPlayed = '',
    this.iconFile,
    this.isRecent = false,
  });
}
