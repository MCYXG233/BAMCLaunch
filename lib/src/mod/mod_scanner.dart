import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import 'mod_info.dart';
import 'mod_parser.dart';

/// Mod扫描器
///
/// 用于扫描指定Minecraft实例目录中的Mod文件，解析并返回Mod信息列表。
/// 支持扫描.jar文件和.jar.disabled文件，并自动识别Mod的启用/禁用状态。
///
/// 使用示例：
/// ```dart
/// final scanner = ModScanner();
/// final mods = await scanner.scanMods('/path/to/instance');
/// ```
class ModScanner {
  /// 日志记录器实例
  ///
  /// 用于记录扫描过程中的信息，如扫描到的Mod数量等
  static final Logger _logger = Logger('ModScanner');

  /// 扫描指定实例目录中的所有Mod
  ///
  /// 扫描给定Minecraft实例目录下的mods文件夹，解析所有.jar和.jar.disabled文件，
  /// 提取Mod信息并返回排序后的Mod列表。
  ///
  /// 参数：
  /// - [instancePath] Minecraft实例的根目录路径
  ///
  /// 返回：
  /// - 返回解析后的Mod信息列表，按Mod名称字母顺序排序
  /// - 如果mods目录不存在，返回空列表
  ///
  /// 扫描规则：
  /// - 只处理.jar和.jar.disabled文件
  /// - .jar文件被视为已启用状态
  /// - .jar.disabled文件被视为已禁用状态
  /// - 其他类型的文件会被跳过
  Future<List<ModInfo>> scanMods(String instancePath) async {
    // 构建mods目录的完整路径
    final modsDir = Directory(path.join(instancePath, 'mods'));

    // 如果mods目录不存在，直接返回空列表
    if (!await modsDir.exists()) {
      return [];
    }

    // 用于存储解析后的Mod信息
    final List<ModInfo> mods = [];
    // 获取mods目录下的所有文件和子目录
    final entries = modsDir.listSync();

    // 遍历目录中的每个条目
    for (final entry in entries) {
      // 跳过非文件条目（如子目录）
      if (entry is! File) continue;

      // 获取文件名（不含路径）
      final fileName = path.basename(entry.path);
      // 转换为小写以便进行不区分大小写的扩展名检查
      final lowerName = fileName.toLowerCase();

      // 只处理.jar和.jar.disabled文件，跳过其他文件
      if (!lowerName.endsWith('.jar') && !lowerName.endsWith('.jar.disabled')) {
        continue;
      }

      // 根据文件扩展名判断Mod是否启用
      // .disabled后缀表示Mod已被禁用
      final isEnabled = !lowerName.endsWith('.disabled');
      // 解析JAR文件，提取Mod信息
      final modInfo = await ModParser.parseJarFile(entry.path, isEnabled);

      // 如果解析成功，将Mod信息添加到列表中
      if (modInfo != null) {
        mods.add(modInfo);
      }
    }

    // 按Mod名称的字母顺序排序（不区分大小写）
    mods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 记录扫描结果日志
    _logger.info('Scanned ${mods.length} mods in $instancePath');
    return mods;
  }
}