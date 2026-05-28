/// Java安装信息模型
/// 包含Java版本的详细信息
class JavaInstallation {
  /// Java可执行文件路径
  final String path;

  /// 完整版本号字符串
  final String version;

  /// 主版本号（如8, 11, 17, 21等）
  final int majorVersion;

  /// 是否为64位版本
  final bool is64Bit;

  /// Java发行商（可选）
  final String? vendor;

  /// 构造函数
  JavaInstallation({
    required this.path,
    required this.version,
    required this.majorVersion,
    required this.is64Bit,
    this.vendor,
  });

  /// 创建副本并修改指定字段
  JavaInstallation copyWith({
    String? path,
    String? version,
    int? majorVersion,
    bool? is64Bit,
    String? vendor,
  }) {
    return JavaInstallation(
      path: path ?? this.path,
      version: version ?? this.version,
      majorVersion: majorVersion ?? this.majorVersion,
      is64Bit: is64Bit ?? this.is64Bit,
      vendor: vendor ?? this.vendor,
    );
  }

  /// 转换为字符串表示
  @override
  String toString() {
    return 'JavaInstallation(path: $path, version: $version, majorVersion: $majorVersion, is64Bit: $is64Bit, vendor: $vendor)';
  }

  /// 相等性比较
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JavaInstallation &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          version == other.version &&
          majorVersion == other.majorVersion &&
          is64Bit == other.is64Bit &&
          vendor == other.vendor;

  /// 哈希码
  @override
  int get hashCode =>
      path.hashCode ^
      version.hashCode ^
      majorVersion.hashCode ^
      is64Bit.hashCode ^
      vendor.hashCode;
}

/// Java版本解析工具类
/// 用于解析Java版本字符串并提取信息
class JavaVersion {
  /// 解析Java版本字符串，返回主版本号
  ///
  /// 支持的版本字符串格式：
  /// - "1.8.0_301" -> 8
  /// - "11.0.12" -> 11
  /// - "17.0.4" -> 17
  /// - "21" -> 21
  static int parseMajorVersion(String versionString) {
    try {
      // 移除可能的前缀（如 "java version " 或引号）
      String cleanVersion = versionString
          .replaceAll('"', '')
          .replaceAll("'", '')
          .trim();

      // 处理 "1.x" 格式的老版本
      if (cleanVersion.startsWith('1.')) {
        final parts = cleanVersion.split('.');
        if (parts.length >= 2) {
          final majorPart = parts[1].split(RegExp(r'[_\-+]')).first;
          return int.tryParse(majorPart) ?? 0;
        }
      }

      // 处理新格式版本（如 11, 17, 21 等）
      final parts = cleanVersion.split('.');
      if (parts.isNotEmpty) {
        final majorPart = parts.first.split(RegExp(r'[_\-+]')).first;
        return int.tryParse(majorPart) ?? 0;
      }
    } catch (e) {
      // 解析失败返回0
    }
    return 0;
  }

  /// 判断Java版本是否兼容Minecraft
  ///
  /// 推荐的兼容版本：8, 11, 17, 21
  static bool isCompatible(int majorVersion) {
    const compatibleVersions = {8, 11, 17, 21};
    return compatibleVersions.contains(majorVersion);
  }

  /// 判断Java版本是否为推荐版本
  static bool isRecommended(int majorVersion) {
    return majorVersion >= 8 && majorVersion <= 21;
  }

  /// 获取版本兼容性描述
  static String getCompatibilityDescription(int majorVersion) {
    if (majorVersion == 0) {
      return '未知版本';
    }
    if (isCompatible(majorVersion)) {
      return '完全兼容';
    }
    if (majorVersion < 8) {
      return '版本过低';
    }
    return '可能不兼容';
  }

  /// 根据游戏版本获取推荐的Java版本列表（按优先级排序）
  ///
  /// Minecraft版本与Java版本的对应关系：
  /// - 1.16及以下: Java 8 (推荐), Java 11 (兼容)
  /// - 1.17-1.18: Java 17 (推荐), Java 8 (兼容)
  /// - 1.19-1.20.4: Java 17 (推荐)
  /// - 1.20.5+: Java 21 (推荐), Java 17 (兼容)
  static List<int> getRecommendedForGameVersion(String gameVersion) {
    try {
      final versionParts = gameVersion.split('.');
      if (versionParts.length < 2) {
        return [17, 11, 8];
      }

      final major = int.tryParse(versionParts[0]) ?? 1;
      final minor = int.tryParse(versionParts[1]) ?? 0;

      int? patch;
      if (versionParts.length >= 3) {
        patch = int.tryParse(versionParts[2].replaceAll(RegExp(r'[^0-9]'), ''));
      }

      if (major == 1) {
        if (minor <= 16) {
          return [8, 11];
        } else if (minor >= 17 && minor <= 18) {
          return [17, 8];
        } else if (minor >= 19 && minor <= 20) {
          if (minor == 20 && patch != null && patch >= 5) {
            return [21, 17];
          }
          return [17];
        }
      }

      return [17, 11, 8];
    } catch (e) {
      return [17, 11, 8];
    }
  }

  /// 判断游戏版本是否需要特定的Java版本
  static bool requiresSpecificJava(String gameVersion, int javaMajorVersion) {
    final recommended = getRecommendedForGameVersion(gameVersion);
    return recommended.isNotEmpty && recommended.first == javaMajorVersion;
  }
}
