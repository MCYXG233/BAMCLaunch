import 'package:semver/semver.dart';
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

    Version? targetVersion;
    try {
      targetVersion = Version.parse(gameVersion);
    } catch (e) {
      _logger.debug('Failed to parse game version: $gameVersion');
      return;
    }

    bool isCompatible = false;
    String? supportedVersions;

    for (final versionRange in mcVersions) {
      supportedVersions = versionRange;
      try {
        final constraint = Constraint.parse(versionRange);
        if (constraint.allows(targetVersion)) {
          isCompatible = true;
          break;
        }
      } catch (e) {
        if (versionRange.contains(gameVersion)) {
          isCompatible = true;
          break;
        }
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

    Version? targetVersion;
    try {
      targetVersion = Version.parse(loaderVersion);
    } catch (e) {
      _logger.debug('Failed to parse loader version: $loaderVersion');
      return;
    }

    bool isCompatible = false;
    String? supportedVersions;

    for (final versionRange in loaderVersions) {
      supportedVersions = versionRange;
      try {
        final constraint = Constraint.parse(versionRange);
        if (constraint.allows(targetVersion)) {
          isCompatible = true;
          break;
        }
      } catch (e) {
        if (versionRange.contains(loaderVersion.split('.').take(2).join('.'))) {
          isCompatible = true;
          break;
        }
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