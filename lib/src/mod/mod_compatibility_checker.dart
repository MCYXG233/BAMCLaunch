import '../core/logger.dart';
import 'mod_info.dart';

class ModCompatibilityChecker {
  static final Logger _logger = Logger('ModCompatibilityChecker');

  static CompatibilityResult checkCompatibility(
    ModInfo mod,
    String gameVersion,
    String loaderType,
    String loaderVersion,
  ) {
    final issues = <CompatibilityIssue>[];

    _checkLoaderCompatibility(mod, loaderType, issues);
    _checkGameVersionCompatibility(mod, gameVersion, issues);
    _checkLoaderVersionCompatibility(mod, loaderType, loaderVersion, issues);

    final status = _determineStatus(issues);

    return CompatibilityResult(
      modId: mod.modId ?? mod.id,
      modName: mod.name,
      status: status,
      issues: issues,
    );
  }

  static List<CompatibilityResult> checkAllCompatibility(
    List<ModInfo> mods,
    String gameVersion,
    String loaderType,
    String loaderVersion,
  ) {
    return mods.map((mod) => checkCompatibility(mod, gameVersion, loaderType, loaderVersion)).toList();
  }

  static void _checkLoaderCompatibility(ModInfo mod, String loaderType, List<CompatibilityIssue> issues) {
    if (mod.modLoader != null && mod.modLoader!.isNotEmpty) {
      final modLoader = mod.modLoader!.toLowerCase();
      final targetLoader = loaderType.toLowerCase();

      if (modLoader != targetLoader) {
        if (_isCompatibleLoader(modLoader, targetLoader)) {
          issues.add(CompatibilityIssue(
            type: CompatibilityIssueType.loaderWarning,
            message: '模组设计用于 ${_getLoaderDisplayName(modLoader)}，当前使用 ${_getLoaderDisplayName(targetLoader)}',
          ));
        } else {
          issues.add(CompatibilityIssue(
            type: CompatibilityIssueType.loaderIncompatible,
            message: '模组设计用于 ${_getLoaderDisplayName(modLoader)}，无法在 ${_getLoaderDisplayName(targetLoader)} 上运行',
          ));
        }
      }
    }
  }

  static void _checkGameVersionCompatibility(ModInfo mod, String gameVersion, List<CompatibilityIssue> issues) {
    final mcVersions = _extractMcVersions(mod);
    if (mcVersions.isEmpty) {
      issues.add(CompatibilityIssue(
        type: CompatibilityIssueType.versionUnknown,
        message: '无法确定模组支持的游戏版本',
      ));
      return;
    }

    bool isCompatible = false;
    String? supportedVersions;

    for (final versionRange in mcVersions) {
      supportedVersions = versionRange;
      if (_versionMatches(gameVersion, versionRange)) {
        isCompatible = true;
        break;
      }
    }

    if (!isCompatible) {
      issues.add(CompatibilityIssue(
        type: CompatibilityIssueType.versionIncompatible,
        message: '模组支持版本: $supportedVersions，当前游戏版本: $gameVersion',
      ));
    }
  }

  static void _checkLoaderVersionCompatibility(
    ModInfo mod,
    String loaderType,
    String loaderVersion,
    List<CompatibilityIssue> issues,
  ) {
    final loaderVersions = _extractLoaderVersions(mod, loaderType);
    if (loaderVersions.isEmpty) return;

    int? targetVersion;
    try {
      targetVersion = _parseVersion(loaderVersion);
      if (targetVersion == null) {
        _logger.debug('Failed to parse loader version: $loaderVersion');
        return;
      }
    } catch (e) {
      _logger.debug('Failed to parse loader version: $loaderVersion');
      return;
    }

    bool isCompatible = false;
    String? supportedVersions;

    for (final versionRange in loaderVersions) {
      supportedVersions = versionRange;
      if (_matchesConstraint(versionRange, targetVersion)) {
        isCompatible = true;
        break;
      }
    }

    if (!isCompatible) {
      issues.add(CompatibilityIssue(
        type: CompatibilityIssueType.loaderVersionIncompatible,
        message: '模组需要 ${_getLoaderDisplayName(loaderType)} 版本: $supportedVersions，当前版本: $loaderVersion',
      ));
    }
  }

  static CompatibilityStatus _determineStatus(List<CompatibilityIssue> issues) {
    if (issues.isEmpty) {
      return CompatibilityStatus.compatible;
    }

    if (issues.any((issue) => issue.type.isError)) {
      return CompatibilityStatus.incompatible;
    }

    return CompatibilityStatus.warning;
  }

  static List<String> _extractMcVersions(ModInfo mod) {
    return [];
  }

  static List<String> _extractLoaderVersions(ModInfo mod, String loaderType) {
    return [];
  }

  static bool _isCompatibleLoader(String modLoader, String targetLoader) {
    return (modLoader == 'fabric' && targetLoader == 'quilt') ||
           (modLoader == 'quilt' && targetLoader == 'fabric');
  }

  static bool _versionMatches(String version, String range) {
    if (range.contains(version)) {
      return true;
    }
    
    if (range.contains('>=') && _compareVersions(version, range.replaceAll('>=', '')) >= 0) {
      return true;
    }
    if (range.contains('<=') && _compareVersions(version, range.replaceAll('<=', '')) <= 0) {
      return true;
    }
    if (range.contains('>') && _compareVersions(version, range.replaceAll('>', '')) > 0) {
      return true;
    }
    if (range.contains('<') && _compareVersions(version, range.replaceAll('<', '')) < 0) {
      return true;
    }
    
    return false;
  }

  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  static int? _parseVersion(String version) {
    try {
      final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      return parts[0] * 1000000 + (parts.length > 1 ? parts[1] * 1000 : 0) + (parts.length > 2 ? parts[2] : 0);
    } catch (e) {
      return null;
    }
  }

  static bool _matchesConstraint(String constraint, int versionValue) {
    try {
      final parts = constraint.split(' ');
      for (final part in parts) {
        final otherValue = _parseVersion(part);
        if (otherValue == null) return false;
        
        if (part.startsWith('>=')) {
          if (versionValue < otherValue) return false;
        } else if (part.startsWith('>')) {
          if (versionValue <= otherValue) return false;
        } else if (part.startsWith('<=')) {
          if (versionValue >= otherValue) return false;
        } else if (part.startsWith('<')) {
          if (versionValue >= otherValue) return false;
        } else {
          if (versionValue != otherValue) return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _getLoaderDisplayName(String loaderType) {
    switch (loaderType.toLowerCase()) {
      case 'fabric':
        return 'Fabric';
      case 'quilt':
        return 'Quilt';
      case 'forge':
        return 'Forge';
      case 'neoforge':
        return 'NeoForge';
      default:
        return loaderType;
    }
  }
}

class CompatibilityResult {
  final String modId;
  final String modName;
  final CompatibilityStatus status;
  final List<CompatibilityIssue> issues;

  CompatibilityResult({
    required this.modId,
    required this.modName,
    required this.status,
    required this.issues,
  });
}

enum CompatibilityStatus {
  compatible,
  warning,
  incompatible,
}

enum CompatibilityIssueType {
  loaderIncompatible,
  loaderWarning,
  versionIncompatible,
  versionUnknown,
  loaderVersionIncompatible,
  missingDependency,
  dependencyVersionMismatch,
  other,
}

extension CompatibilityIssueTypeExtension on CompatibilityIssueType {
  bool get isError {
    switch (this) {
      case CompatibilityIssueType.loaderIncompatible:
      case CompatibilityIssueType.versionIncompatible:
      case CompatibilityIssueType.loaderVersionIncompatible:
      case CompatibilityIssueType.missingDependency:
        return true;
      default:
        return false;
    }
  }

  String get severity {
    return isError ? 'error' : 'warning';
  }
}

class CompatibilityIssue {
  final CompatibilityIssueType type;
  final String message;

  CompatibilityIssue({
    required this.type,
    required this.message,
  });
}

class ModDependencyInfo {
  final String modId;
  final String? versionRange;
  final bool required;

  ModDependencyInfo({
    required this.modId,
    this.versionRange,
    this.required = true,
  });
}