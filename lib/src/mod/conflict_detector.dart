import '../core/logger.dart';
import 'mod_info.dart';

class ConflictDetector {
  static final Logger _logger = Logger('ConflictDetector');

  List<ModConflict> detectConflicts(List<ModInfo> mods) {
    final conflicts = <ModConflict>[];

    conflicts.addAll(_detectSameModDifferentVersions(mods));
    conflicts.addAll(_detectIncompatibleLoaders(mods));
    conflicts.addAll(_detectDuplicateMods(mods));

    return conflicts;
  }

  List<ModConflict> _detectSameModDifferentVersions(List<ModInfo> mods) {
    final conflicts = <ModConflict>[];
    final modGroups = <String, List<ModInfo>>{};

    for (final mod in mods) {
      final modId = mod.modId ?? mod.id;
      modGroups.putIfAbsent(modId, () => []).add(mod);
    }

    for (final entry in modGroups.entries) {
      final modList = entry.value;
      if (modList.length > 1) {
        final versions = modList.map((m) => m.version ?? 'unknown').toSet();
        if (versions.length > 1) {
          conflicts.add(ModConflict(
            type: ConflictType.sameModDifferentVersions,
            severity: ConflictSeverity.error,
            title: '同一Mod存在多个版本',
            description: '${entry.key} 存在 ${versions.length} 个不同版本',
            involvedMods: modList,
            suggestion: '保留最新版本，删除其他版本',
          ));
        }
      }
    }

    return conflicts;
  }

  List<ModConflict> _detectIncompatibleLoaders(List<ModInfo> mods) {
    final conflicts = <ModConflict>[];

    final fabricQuiltMods = mods.where((m) =>
        m.modLoader == 'fabric' || m.modLoader == 'quilt').toList();
    final forgeMods = mods.where((m) =>
        m.modLoader == 'forge' || m.modLoader == 'neoforge').toList();

    if (fabricQuiltMods.isNotEmpty && forgeMods.isNotEmpty) {
      conflicts.add(ModConflict(
        type: ConflictType.incompatibleLoaders,
        severity: ConflictSeverity.error,
        title: '加载器不兼容',
        description: 'Fabric/Quilt模组与Forge/NeoForge模组不能同时使用',
        involvedMods: [...fabricQuiltMods, ...forgeMods],
        suggestion: '选择使用Fabric/Quilt或Forge/NeoForge模组，确保所有模组使用相同的加载器',
      ));
    }

    return conflicts;
  }

  List<ModConflict> _detectDuplicateMods(List<ModInfo> mods) {
    final conflicts = <ModConflict>[];
    final fileNameGroups = <String, List<ModInfo>>{};

    for (final mod in mods) {
      final baseFileName = _getBaseFileName(mod.fileName);
      fileNameGroups.putIfAbsent(baseFileName, () => []).add(mod);
    }

    for (final entry in fileNameGroups.entries) {
      final modList = entry.value;
      if (modList.length > 1) {
        final enabledCount = modList.where((m) => m.isEnabled).length;
        if (enabledCount > 1) {
          conflicts.add(ModConflict(
            type: ConflictType.duplicateMods,
            severity: ConflictSeverity.warning,
            title: '存在重复模组',
            description: '${entry.key} 存在 ${modList.length} 个副本',
            involvedMods: modList,
            suggestion: '保留一个副本，删除其他重复项',
          ));
        }
      }
    }

    return conflicts;
  }

  String _getBaseFileName(String fileName) {
    var name = fileName.toLowerCase();
    name = name.replaceAll('.disabled', '');
    name = name.replaceAll(RegExp(r'[-_]?\d+\.\d+\.\d+.*'), '');
    name = name.replaceAll(RegExp(r'[-_]?(fabric|forge|quilt|neoforge)'), '');
    return name.trim();
  }

  List<ConflictSolution> generateSolutions(List<ModConflict> conflicts) {
    return conflicts.map((conflict) {
      switch (conflict.type) {
        case ConflictType.sameModDifferentVersions:
          return _solveSameModDifferentVersions(conflict);
        case ConflictType.incompatibleLoaders:
          return _solveIncompatibleLoaders(conflict);
        case ConflictType.duplicateMods:
          return _solveDuplicateMods(conflict);
        case ConflictType.dependencyConflict:
          return _solveDependencyConflict(conflict);
      }
    }).toList();
  }

  ConflictSolution _solveSameModDifferentVersions(ModConflict conflict) {
    final sortedMods = List<ModInfo>.from(conflict.involvedMods)
      ..sort((a, b) => _compareVersions(
          b.version ?? '0.0.0', a.version ?? '0.0.0'));

    final keep = sortedMods.first;
    final remove = sortedMods.skip(1).toList();

    return ConflictSolution(
      conflict: conflict,
      action: SolutionAction.keepLatestRemoveOthers,
      keepMods: [keep],
      removeMods: remove,
      description: '保留版本 ${keep.version}，删除其他版本',
    );
  }

  ConflictSolution _solveIncompatibleLoaders(ModConflict conflict) {
    final fabricQuiltMods = conflict.involvedMods
        .where((m) => m.modLoader == 'fabric' || m.modLoader == 'quilt')
        .toList();
    final forgeMods = conflict.involvedMods
        .where((m) => m.modLoader == 'forge' || m.modLoader == 'neoforge')
        .toList();

    return ConflictSolution(
      conflict: conflict,
      action: SolutionAction.chooseLoader,
      keepMods: [],
      removeMods: [],
      description: '需要选择一种加载器：保留Fabric/Quilt模组或Forge/NeoForge模组',
      alternativeChoices: [
        AlternativeChoice(
          name: '使用Fabric/Quilt',
          keepMods: fabricQuiltMods,
          removeMods: forgeMods,
        ),
        AlternativeChoice(
          name: '使用Forge/NeoForge',
          keepMods: forgeMods,
          removeMods: fabricQuiltMods,
        ),
      ],
    );
  }

  ConflictSolution _solveDuplicateMods(ModConflict conflict) {
    final enabledMods = conflict.involvedMods.where((m) => m.isEnabled).toList();
    final disabledMods = conflict.involvedMods.where((m) => !m.isEnabled).toList();

    return ConflictSolution(
      conflict: conflict,
      action: SolutionAction.removeDuplicates,
      keepMods: enabledMods.isNotEmpty ? [enabledMods.first] : [],
      removeMods: [...enabledMods.skip(1), ...disabledMods],
      description: '保留一个启用状态的副本',
    );
  }

  ConflictSolution _solveDependencyConflict(ModConflict conflict) {
    return ConflictSolution(
      conflict: conflict,
      action: SolutionAction.resolveDependencies,
      keepMods: [],
      removeMods: [],
      description: '请检查并安装缺失的依赖项',
    );
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = _parseVersionParts(v1);
    final parts2 = _parseVersionParts(v2);

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  List<int> _parseVersionParts(String version) {
    final cleanVersion = version.replaceAll(RegExp(r'^[vV]'), '').split('-').first;
    return cleanVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }
}

enum ConflictType {
  sameModDifferentVersions,
  incompatibleLoaders,
  duplicateMods,
  dependencyConflict,
}

enum ConflictSeverity {
  warning,
  error,
}

enum SolutionAction {
  keepLatestRemoveOthers,
  removeDuplicates,
  chooseLoader,
  resolveDependencies,
}

class ModConflict {
  final ConflictType type;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final List<ModInfo> involvedMods;
  final String suggestion;

  ModConflict({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.involvedMods,
    required this.suggestion,
  });

  bool get isError => severity == ConflictSeverity.error;
  bool get isWarning => severity == ConflictSeverity.warning;
}

class ConflictSolution {
  final ModConflict conflict;
  final SolutionAction action;
  final List<ModInfo> keepMods;
  final List<ModInfo> removeMods;
  final String description;
  final List<AlternativeChoice>? alternativeChoices;

  ConflictSolution({
    required this.conflict,
    required this.action,
    required this.keepMods,
    required this.removeMods,
    required this.description,
    this.alternativeChoices,
  });
}

class AlternativeChoice {
  final String name;
  final List<ModInfo> keepMods;
  final List<ModInfo> removeMods;

  AlternativeChoice({
    required this.name,
    required this.keepMods,
    required this.removeMods,
  });
}
