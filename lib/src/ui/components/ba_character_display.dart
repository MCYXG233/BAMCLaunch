import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class BACharacterDisplay extends StatefulWidget {
  final double? width;
  final double? height;
  
  const BACharacterDisplay({
    super.key,
    this.width,
    this.height,
  });

  @override
  State<BACharacterDisplay> createState() => _BACharacterDisplayState();
}

class _BACharacterDisplayState extends State<BACharacterDisplay> with SingleTickerProviderStateMixin {
  String _currentAnimation = 'idle';
  bool _isPlayingOneShot = false;
  late AnimationController _animationController;
  List<Particle> _particles = [];
  Offset? _mousePosition;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _playTapAnimation() async {
    if (_isPlayingOneShot) return;
    
    setState(() {
      _isPlayingOneShot = true;
      _currentAnimation = 'tap';
    });
    
    _animationController
      ..stop()
      ..duration = const Duration(milliseconds: 800)
      ..forward(from: 0).then((_) {
        _generateParticles();
        setState(() {
          _isPlayingOneShot = false;
          _currentAnimation = 'idle';
        });
        _animationController
          ..duration = const Duration(seconds: 2)
          ..repeat();
      });
  }

  void _playHoverAnimation() {
    if (_isPlayingOneShot) return;
    setState(() => _currentAnimation = 'happy');
  }

  void _generateParticles() {
    setState(() {
      _particles = List.generate(20, (index) {
        final angle = (index / 20) * 2 * pi;
        final speed = Random().nextDouble() * 3 + 1;
        return Particle(
          id: index,
          angle: angle,
          speed: speed,
          color: [
            Colors.pink,
            Colors.cyan,
            Colors.yellow,
            Colors.purple,
            Colors.white,
          ][Random().nextInt(5)],
        );
      });
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _particles.clear());
    });
  }

  String _getAnimationPath() {
    return 'assets/animations/character_idle.json';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() => _mousePosition = event.localPosition);
        _playHoverAnimation();
      },
      onExit: (event) {
        setState(() => _mousePosition = null);
        setState(() => _currentAnimation = 'idle');
      },
      child: GestureDetector(
        onTap: _playTapAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCharacterAnimation(),
            ..._buildParticles(),
            _buildInteractionHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterAnimation() {
    return SizedBox(
      width: widget.width ?? 300,
      height: widget.height ?? 400,
      child: Lottie.asset(
        _getAnimationPath(),
        controller: _animationController,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackCharacter();
        },
      ),
    );
  }

  Widget _buildFallbackCharacter() {
    return Container(
      width: widget.width ?? 300,
      height: widget.height ?? 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7EB5F6).withOpacity(0.3),
            const Color(0xFFB8A4FF).withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7EB5F6), Color(0xFFB8A4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7EB5F6).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '点击互动',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    final centerX = (widget.width ?? 320) / 2;
    final centerY = (widget.height ?? 350) / 2;
    
    return _particles.map((particle) {
      return Positioned(
        top: centerY,
        left: centerX,
        child: ParticleWidget(particle: particle),
      );
    }).toList();
  }

  Widget _buildInteractionHint() {
    if (_currentAnimation != 'idle') return const SizedBox();
    
    return Positioned(
      bottom: 20,
      child: const OpacityAnimation(
        child: Text(
          '👆 点击互动',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class Particle {
  final int id;
  final double angle;
  final double speed;
  final Color color;
  
  Particle({
    required this.id,
    required this.angle,
    required this.speed,
    required this.color,
  });
}

class ParticleWidget extends StatefulWidget {
  final Particle particle;
  
  const ParticleWidget({super.key, required this.particle});
  
  @override
  State<ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<ParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.particle.speed).round()),
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
        final radius = value * 100 * widget.particle.speed;
        final x = cos(widget.particle.angle) * radius;
        final y = sin(widget.particle.angle) * radius - 50;
        final opacity = 1.0 - value;
        final size = (8 * (1 - value * 0.5)).toDouble();
        
        return Transform.translate(
          offset: Offset(x.toDouble(), y.toDouble()),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.particle.color,
                borderRadius: BorderRadius.circular(size / 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.particle.color,
                    blurRadius: 10,
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

class OpacityAnimation extends StatefulWidget {
  final Widget child;
  
  const OpacityAnimation({
    super.key,
    required this.child,
  });
  
  @override
  State<OpacityAnimation> createState() => _OpacityAnimationState();
}

class _OpacityAnimationState extends State<OpacityAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
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
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}