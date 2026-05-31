import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'ba_main_page.dart';
import 'home_page.dart';
import 'version_page.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'ba_settings_page.dart';
import 'resource_center_page.dart';
import 'ba_resource_center_page.dart';
import 'login_page.dart';
import 'account_selector.dart';
import 'ba_game_library_page.dart';

/// 应用路由常量定义
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String versions = '/versions';
  static const String accounts = '/accounts';
  static const String settings = '/settings';
  static const String resourceCenter = '/resource-center';
  static const String login = '/login';
  static const String accountSelector = '/account-selector';
}

/// 应用路由管理类
/// 负责管理应用的路由导航和路由生成
class AppRouter {
  /// 生成路由的方法
  /// 根据设置的路由名称返回对应的页面组件
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const BAMCSplashPage(),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const BAMCMainPage(),
          settings: settings,
        );
      case AppRoutes.versions:
        return MaterialPageRoute(
          builder: (_) => const BAGameLibraryPage(),
          settings: settings,
        );
      case AppRoutes.accounts:
        return MaterialPageRoute(
          builder: (_) => const BAMCHomePage(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const BASettingsPage(),
          settings: settings,
        );
      case AppRoutes.resourceCenter:
        return MaterialPageRoute(
          builder: (_) => const BAResourceCenterPage(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case AppRoutes.accountSelector:
        return MaterialPageRoute(
          builder: (_) => const AccountSelectorPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const BAMCSplashPage(),
          settings: settings,
        );
    }
  }

  /// 导航到首页
  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  /// 导航到启动页
  static void navigateToSplash(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.splash);
  }

  /// 导航到版本管理页
  static void navigateToVersions(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.versions);
  }

  /// 导航到账户管理页
  static void navigateToAccounts(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.accounts);
  }

  /// 导航到设置页
  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  /// 导航到资源中心页
  static void navigateToResourceCenter(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.resourceCenter);
  }

  /// 导航到登录页
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  /// 导航到账户选择页
  static void navigateToAccountSelector(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.accountSelector);
  }
}
