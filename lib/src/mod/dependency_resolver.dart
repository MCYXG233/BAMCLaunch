import '../core/logger.dart';
import 'mod_info.dart';

class DependencyResolver {
  static final Logger _logger = Logger('DependencyResolver');

  final Map<String, ModInfo> _modMap = {};
  final Set<String> _visited = {};
  final List<String> _path = [];

  DependencyTree? buildDependencyTree(List<ModInfo> mods) {
    _modMap.clear();
    _modMap.addAll({for (var mod in mods) mod.modId ?? mod.id: mod});

    final roots = <DependencyNode>[];

    for (final mod in mods) {
      final modId = mod.modId ?? mod.id;
      if (!_isDependencyOfAny(modId, mods)) {
        roots.add(_buildNode(modId, 0));
      }
    }

    if (roots.isEmpty && mods.isNotEmpty) {
      roots.add(_buildNode(mods.first.modId ?? mods.first.id, 0));
    }

    return roots.isNotEmpty ? DependencyTree(roots: roots) : null;
  }

  bool _isDependencyOfAny(String modId, List<ModInfo> mods) {
    for (final mod in mods) {
      if (mod.dependencies.contains(modId)) {
        return true;
      }
    }
    return false;
  }

  DependencyNode _buildNode(String modId, int depth) {
    if (depth > 100) {
      _logger.warning('Max depth exceeded for dependency resolution');
      return DependencyNode(modId: modId, mod: _modMap[modId], depth: depth);
    }

    if (_visited.contains(modId)) {
      final cycleStartIndex = _path.indexOf(modId);
      if (cycleStartIndex != -1) {
        final cycle = _path.sublist(cycleStartIndex)..add(modId);
        return DependencyNode(
          modId: modId,
          mod: _modMap[modId],
          depth: depth,
          cycle: cycle,
        );
      }
      return DependencyNode(modId: modId, mod: _modMap[modId], depth: depth);
    }

    _visited.add(modId);
    _path.add(modId);

    final mod = _modMap[modId];
    final children = <DependencyNode>[];

    if (mod != null) {
      for (final depId in mod.dependencies) {
        final childNode = _buildNode(depId, depth + 1);
        children.add(childNode);
      }
    }

    _path.removeLast();

    return DependencyNode(
      modId: modId,
      mod: mod,
      depth: depth,
      children: children,
    );
  }

  List<String> detectCircularDependencies(List<ModInfo> mods) {
    _modMap.clear();
    _modMap.addAll({for (var mod in mods) mod.modId ?? mod.id: mod});

    final cycles = <String>[];

    for (final mod in mods) {
      final modId = mod.modId ?? mod.id;
      _visited.clear();
      _path.clear();

      if (_hasCycle(modId, mods)) {
        final cycleStartIndex = _path.indexOf(modId);
        if (cycleStartIndex != -1) {
          final cycle = _path.sublist(cycleStartIndex)..add(modId);
          cycles.add(cycle.join(' -> '));
        }
      }
    }

    return cycles;
  }

  bool _hasCycle(String modId, List<ModInfo> mods) {
    if (_visited.contains(modId)) {
      return true;
    }

    _visited.add(modId);
    _path.add(modId);

    final mod = _modMap[modId];
    if (mod != null) {
      for (final depId in mod.dependencies) {
        if (_hasCycle(depId, mods)) {
          return true;
        }
      }
    }

    _path.removeLast();
    return false;
  }

  List<MissingDependency> findMissingDependencies(List<ModInfo> mods) {
    _modMap.clear();
    _modMap.addAll({for (var mod in mods) mod.modId ?? mod.id: mod});

    final missing = <MissingDependency>[];

    for (final mod in mods) {
      final modId = mod.modId ?? mod.id;

      for (final depId in mod.dependencies) {
        if (!_modMap.containsKey(depId)) {
          missing.add(MissingDependency(
            dependentModId: modId,
            dependentModName: mod.name,
            missingModId: depId,
          ));
        }
      }
    }

    return missing;
  }

  Future<List<String>> resolveDependencies(
    List<ModInfo> mods, {
    required Future<String?> Function(String modId) downloadMod,
    void Function(String modId, int current, int total)? onProgress,
  }) async {
    final missingDeps = findMissingDependencies(mods);
    if (missingDeps.isEmpty) {
      return [];
    }

    final uniqueMissingIds = missingDeps.map((d) => d.missingModId).toSet().toList();
    final downloaded = <String>[];

    for (var i = 0; i < uniqueMissingIds.length; i++) {
      final modId = uniqueMissingIds[i];
      onProgress?.call(modId, i + 1, uniqueMissingIds.length);

      final path = await downloadMod(modId);
      if (path != null) {
        downloaded.add(path);
      }
    }

    return downloaded;
  }
}

class DependencyTree {
  final List<DependencyNode> roots;

  DependencyTree({required this.roots});

  List<DependencyNode> get allNodes {
    final nodes = <DependencyNode>[];
    _collectNodes(roots, nodes);
    return nodes;
  }

  void _collectNodes(List<DependencyNode> nodes, List<DependencyNode> result) {
    result.addAll(nodes);
    for (final node in nodes) {
      if (node.children.isNotEmpty) {
        _collectNodes(node.children, result);
      }
    }
  }
}

class DependencyNode {
  final String modId;
  final ModInfo? mod;
  final int depth;
  final List<DependencyNode> children;
  final List<String>? cycle;

  DependencyNode({
    required this.modId,
    this.mod,
    this.depth = 0,
    this.children = const [],
    this.cycle,
  });

  bool get hasCycle => cycle != null && cycle!.isNotEmpty;

  String get displayName => mod?.name ?? modId;

  String get version => mod?.version ?? 'unknown';
}

class MissingDependency {
  final String dependentModId;
  final String dependentModName;
  final String missingModId;

  MissingDependency({
    required this.dependentModId,
    required this.dependentModName,
    required this.missingModId,
  });
}
