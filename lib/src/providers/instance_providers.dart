import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';
import 'service_locator_provider.dart';

/// InstanceManager Provider
/// 
/// 提供实例管理服务
final instanceManagerProvider = Provider<InstanceManager>((ref) {
  final locator = ref.watch(serviceLocatorProvider);
  return locator.get<InstanceManager>();
});

/// 实例列表 Provider
/// 
/// 获取所有游戏实例列表
final instancesProvider = Provider<List<GameInstance>>((ref) {
  final manager = ref.watch(instanceManagerProvider);
  return manager.instances;
});

/// 当前选中实例 Provider
/// 
/// 管理当前选中的游戏实例
final selectedInstanceProvider = StateProvider<GameInstance?>((ref) => null);

/// 实例过滤器 Provider
/// 
/// 管理实例列表的过滤条件
final instanceFilterProvider = StateProvider<InstanceFilter>((ref) {
  return const InstanceFilter();
});

/// 过滤后的实例列表 Provider
/// 
/// 根据过滤器条件过滤实例列表
final filteredInstancesProvider = Provider<List<GameInstance>>((ref) {
  final instances = ref.watch(instancesProvider);
  final filter = ref.watch(instanceFilterProvider);
  
  var result = List<GameInstance>.from(instances);
  
  // 搜索过滤
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    result = result.where((inst) =>
      inst.name.toLowerCase().contains(query) ||
      inst.description?.toLowerCase().contains(query) == true
    ).toList();
  }
  
  // 排序
  result.sort((a, b) {
    final direction = filter.sortDirection == SortDirection.ascending ? 1 : -1;
    switch (filter.sortOption) {
      case InstanceSortOption.name:
        return a.name.compareTo(b.name) * direction;
      case InstanceSortOption.lastPlayed:
        final aTime = a.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime) * direction;
      case InstanceSortOption.createdAt:
        return a.createdAt.compareTo(b.createdAt) * direction;
      case InstanceSortOption.size:
        return direction; // 大小排序需要额外计算，这里简化处理
    }
  });
  
  return result;
});
