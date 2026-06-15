import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class BALaunchAnimation extends StatefulWidget {
  final String gameVersion;
  final String playerName;
  final VoidCallback onComplete;
  
  const BALaunchAnimation({
    super.key,
    required this.gameVersion,
    required this.playerName,
    required this.onComplete,
  });

  @override
  State<BALaunchAnimation> createState() => _BALaunchAnimationState();
}

class _BALaunchAnimationState extends State<BALaunchAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = true;
  List<StarParticle> _stars = [];
  List<SparkleParticle> _sparkles = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _initializeParticles();
    _startAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    setState(() {
      _stars = List.generate(50, (index) {
        return StarParticle(
          id: index,
          x: Random().nextDouble() * 100,
          y: Random().nextDouble() * 100,
          size: Random().nextDouble() * 3 + 1,
          delay: Random().nextDouble() * 2,
          duration: Random().nextDouble() * 2 + 1,
        );
      });
    });
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    await _animationController.forward();
    
    _generateSparkles();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() => _isAnimating = false);
    
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onComplete();
  }

  void _generateSparkles() {
    setState(() {
      _sparkles = List.generate(30, (index) {
        final angle = (index / 30) * 2 * pi;
        final speed = Random().nextDouble() * 4 + 2;
        return SparkleParticle(
          id: index,
          angle: angle,
          speed: speed,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildStarField(),
          _buildMainContent(),
          ..._buildSparkles(),
          _buildFadeOverlay(),
        ],
      ),
    );
  }

  Widget _buildStarField() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A1A3A),
              Color(0xFF0A0A1A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: _stars.map((star) {
            return Positioned(
              left: star.x,
              top: star.y,
              child: StarWidget(star: star),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'MINECRAFT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              shadows: [
                Shadow(
                  color: Color(0xFF7EB5F6),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Version ${widget.gameVersion}',
            style: TextStyle(
              color: const Color(0xFF7EB5F6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF7EB5F6).withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  color: Color(0xFF7EB5F6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/launch.json',
              controller: _animationController,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildLoadingAnimation();
              },
            ),
          ),
          const SizedBox(height: 30),
          
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = _animationController.value;
              String status = '';
              
              if (progress < 0.3) {
                status = '正在准备游戏...';
              } else if (progress < 0.6) {
                status = '正在加载资源...';
              } else if (progress < 0.9) {
                status = '即将启动...';
              } else {
                status = '启动成功！';
              }
              
              return Text(
                status,
                style: TextStyle(
                  color: const Color(0xFF7BCB9E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7EB5F6)),
        strokeWidth: 3,
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return _sparkles.map((sparkle) {
      return Positioned(
        top: MediaQuery.of(context).size.height / 2,
        left: MediaQuery.of(context).size.width / 2,
        child: SparkleWidget(sparkle: sparkle),
      );
    }).toList();
  }

  Widget _buildFadeOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _isAnimating ? 0 : 1,
        duration: const Duration(milliseconds: 500),
        child: Container(
          color: Colors.black,
        ),
      ),
    );
  }
}

class StarParticle {
  final int id;
  final double x;
  final double y;
  final double size;
  final double delay;
  final double duration;
  
  StarParticle({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.duration,
  });
}

class StarWidget extends StatefulWidget {
  final StarParticle star;
  
  const StarWidget({super.key, required this.star});
  
  @override
  State<StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<StarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.star.duration * 1000).round()),
    );
    
    Future.delayed(Duration(milliseconds: (widget.star.delay * 1000).round()), () {
      _controller.forward();
    });
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.star.size,
            height: widget.star.size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.star.size / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: widget.star.size * 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SparkleParticle {
  final int id;
  final double angle;
  final double speed;
  
  SparkleParticle({
    required this.id,
    required this.angle,
    required this.speed,
  });
}

class SparkleWidget extends StatefulWidget {
  final SparkleParticle sparkle;
  
  const SparkleWidget({super.key, required this.sparkle});
  
  @override
  State<SparkleWidget> createState() => _SparkleWidgetState();
}

class _SparkleWidgetState extends State<SparkleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1500 / widget.sparkle.speed).round()),
    )..forward();
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxDistance = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);
        final distance = value * maxDistance * 0.5 * widget.sparkle.speed;
        final x = cos(widget.sparkle.angle) * distance;
        final y = sin(widget.sparkle.angle) * distance;
        final opacity = 1.0 - value;
        final size = (20 * (1 - value * 0.8)).toDouble();
        
        return Transform.translate(
          offset: Offset(x.toDouble(), y.toDouble()),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7EB5F6), Color(0xFFFFB4C2), Color(0xFFB8A4FF)],
                ),
                borderRadius: BorderRadius.circular(size / 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7EB5F6),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}