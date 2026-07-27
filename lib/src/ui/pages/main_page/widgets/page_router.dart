import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ba_game_library_page.dart';
import '../../ba_resource_center_page.dart';
import '../../ba_account_page.dart';
import '../../ba_more_page.dart';
import '../../../components/ba_immersive_home.dart';
import '../../../../di/providers.dart';
import '../main_page_providers.dart';

/// 页面路由器 - 根据 currentPageProvider 返回对应子页面
class PageRouter extends ConsumerWidget {
  final Future<void> Function() onLaunch;

  const PageRouter({super.key, required this.onLaunch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    switch (currentPage) {
      case 0:
        return _buildHomePage(ref);
      case 1:
        return const BAGameLibraryPage(key: ValueKey('library'));
      case 2:
        return const BAResourceCenterPage(key: ValueKey('resource'));
      case 3:
        return const BAAccountPage(key: ValueKey('account'));
      case 4:
        return const BAMorePage(key: ValueKey('more'));
      default:
        return _buildHomePage(ref);
    }
  }

  Widget _buildHomePage(WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
    final selectedIndex = ref.watch(selectedInstanceIndexProvider);
    final isLaunching = ref.watch(isLaunchingProvider);
    return ImmersiveHomePage(
      key: const ValueKey('home'),
      instances: instances,
      selectedInstanceIndex: selectedIndex,
      onInstanceChanged: (index) {
        ref.read(selectedInstanceIndexProvider.notifier).state = index;
      },
      isLaunching: isLaunching,
      onLaunch: onLaunch,
    );
  }
}
