import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../core/logger.dart';
import '../../config/config_manager_impl.dart';
import '../../account/account_manager.dart';
import '../../game/launcher/game_launcher.dart';
import '../../event/event_bus.dart';
import 'app_router.dart';

/// 启动加载页面
class BAMCSplashPage extends StatefulWidget {
  const BAMCSplashPage({super.key});

  @override
  State<BAMCSplashPage> createState() => _BAMCSplashPageState();
}

class _BAMCSplashPageState extends State<BAMCSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _currentDotIndex = 0;
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

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 1.0)),
    );

    _animationController.forward();

    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted && !_isInitialized) {
        setState(() {
          _currentDotIndex = (_currentDotIndex + 1) % 4;
          _currentLoadingText = _loadingTexts[_currentDotIndex];
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeApp() async {
    final logger = Logger();
    try {
      logger.info('开始初始化应用...');

      final configManager = ConfigManagerImpl();
      await configManager.initialize();
      logger.info('配置管理器初始化完成');

      final accountManager = AccountManager();
      await accountManager.initialize(
        configManager: configManager,
        eventBus: EventBus(),
      );
      logger.info('账户管理器初始化完成');

      final gameLauncher = GameLauncher();
      await gameLauncher.initialize();
      logger.info('游戏启动器初始化完成');

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        logger.info('应用初始化完成，跳转到主页');
        AppRouter.navigateToHome(context);
      }
    } catch (e, stackTrace) {
      logger.error('应用初始化失败', e, stackTrace);
      if (mounted) {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF161B3A),
              Color(0xFF1E2447),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildLogo(),
                  );
                },
              ),
              const SizedBox(height: 40),
              _buildLoadingDots(),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  _currentLoadingText,
                  style: BATypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 180,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: BAColors.primaryOf(context).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A3456),
              Color(0xFF1E2747),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BAColors.primaryOf(context).withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/BAMCLaunch_Logo.png',
            fit: BoxFit.contain,
            width: 150,
            height: 45,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: index == _currentDotIndex ? 16 : 10,
            height: index == _currentDotIndex ? 16 : 10,
            decoration: BoxDecoration(
              color: index == _currentDotIndex
                  ? BAColors.primaryOf(context)
                  : BAColors.primaryOf(context).withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: index == _currentDotIndex
                  ? [
                      BoxShadow(
                        color: BAColors.primaryOf(context).withOpacity(0.6),
                        blurRadius: 10,
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
