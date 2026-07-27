import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../instance/models.dart';

/// 主页面内部使用的 Provider 集合
///
/// 仅供 BAMainPage 内部使用，跨页面共享状态使用
/// [selectedInstanceIndexProvider]（在 providers.dart）。

/// 当前页面索引（0 首页 / 1 游戏 / 2 发现 / 3 账户 / 4 更多）
final currentPageProvider = StateProvider<int>((ref) => 0);

/// 当前选中的账号名称
final selectedAccountNameProvider = StateProvider<String?>((ref) => null);

/// 游戏实例列表
final instancesProvider = StateProvider<List<GameInstance>>((ref) => []);

/// 是否正在启动游戏
final isLaunchingProvider = StateProvider<bool>((ref) => false);
