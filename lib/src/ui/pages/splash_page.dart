import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../../core/logger.dart';
import '../../config/config_manager_impl.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../game/java/java_manager.dart';
import '../../game/launcher/game_launcher.dart';
import '../../event/event_bus.dart';
import 'app_router.dart';

/// 启动加载页面
/// 显示夏莱Logo和像素风格加载动画，同时初始化应用资源
class BAMCSplashPage extends StatefulWidget {
  const BAMCSplashPage({super.key});

  @override
  State<BAMCSplashPage> createState() => _BAMCSplashPageState();
}

class _BAMCSplashPageState extends State<BAMCSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  int _currentPixelIndex = 0;
  final List<String> _loadingTexts = [
    '正在初始化...',
    '加载配置文件...',
    '准备游戏环境...',
    '夏莱，启动！',
  ];
  String _currentLoadingText = '正在初始化...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画控制器
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.repeat(reverse: true);

    // 定期更新加载文字
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && !_isInitialized) {
        setState(() {
          _currentPixelIndex = (_currentPixelIndex + 1) % 4;
          _currentLoadingText = _loadingTexts[_currentPixelIndex];
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 初始化应用资源
  Future<void> _initializeApp() async {
    final logger = Logger();
    try {
      logger.info('开始初始化应用...');

      // 初始化配置管理器
      final configManager = ConfigManagerImpl();
      await configManager.initialize();
      logger.info('配置管理器初始化完成');

      // 初始化账户管理器
      final accountManager = AccountManager();
      await accountManager.initialize(
        configManager: configManager,
        eventBus: EventBus(),
      );
      logger.info('账户管理器初始化完成');

      // 初始化Java管理器
      final javaManager = JavaManager();
      // 可以在这里预加载Java检测
      logger.info('Java管理器初始化完成');

      // 初始化游戏启动器
      final gameLauncher = GameLauncher();
      await gameLauncher.initialize();
      logger.info('游戏启动器初始化完成');

      // 模拟一些加载时间，让用户看到动画
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        logger.info('应用初始化完成，跳转到主页');
        // 导航到主页
        AppRouter.navigateToHome(context);
      }
    } catch (e, stackTrace) {
      logger.error('应用初始化失败', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('初始化失败: $e'),
            backgroundColor: BAColors.danger,
          ),
        );
        // 即使失败也尝试跳转到主页
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          AppRouter.navigateToHome(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BAColors.background,
              BAColors.surface,
              BAColors.surfaceVariant,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo动画
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bounceAnimation.value),
                    child: _buildSchaleLogo(),
                  );
                },
              ),
              const SizedBox(height: 40),
              // 像素风格加载动画
              _buildPixelLoadingAnimation(),
              const SizedBox(height: 24),
              // 加载文字
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  _currentLoadingText,
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建BAMCLaunch Logo
  Widget _buildSchaleLogo() {
    return Container(
      width: 140,
      height: 60,
      decoration: BoxDecoration(
        color: BAColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: BAColors.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: BAColors.primary, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/BAMCLaunch_Logo.png',
          fit: BoxFit.contain,
          width: 120,
          height: 50,
        ),
      ),
    );
  }

  /// 构建像素风格加载动画
  Widget _buildPixelLoadingAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == _currentPixelIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 16 : 10,
            height: isActive ? 16 : 10,
            decoration: BoxDecoration(
              color: isActive
                  ? BAColors.primary
                  : BAColors.primary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: BAColors.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
