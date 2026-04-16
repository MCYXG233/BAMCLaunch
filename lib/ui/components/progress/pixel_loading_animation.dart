import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/effects.dart';

class PixelLoadingAnimation extends StatefulWidget {
  final double size;
  final Duration duration;

  const PixelLoadingAnimation({
    super.key,
    this.size = 200,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PixelLoadingAnimation> createState() => _PixelLoadingAnimationState();
}

class _PixelLoadingAnimationState extends State<PixelLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PixelLoadingPainter(
              animation: _controller,
              random: _random,
            ),
          );
        },
      ),
    );
  }
}

class _PixelLoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Random random;

  _PixelLoadingPainter({
    required this.animation,
    required this.random,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pixelSize = size.width / 10;
    const gridSize = 8;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final x = (col - gridSize / 2 + 0.5) * pixelSize;
        final y = (row - gridSize / 2 + 0.5) * pixelSize;

        final distance = sqrt(x * x + y * y) / (size.width / 2);
        final phase = (distance + animation.value) % 1.0;

        final opacity = (0.3 + 0.7 * sin(phase * pi * 2)).clamp(0.0, 1.0);
        final scale = 0.5 + 0.5 * sin(phase * pi * 2);
        final colorIndex =
            (row * gridSize + col) % BamcEffects.pixelLoadingColors.length;
        final color =
            BamcEffects.pixelLoadingColors[colorIndex].withOpacity(opacity);

        final paint = Paint()..color = color;
        final pixelRect = Rect.fromLTWH(
          center.dx + x - (pixelSize * scale) / 2,
          center.dy + y - (pixelSize * scale) / 2,
          pixelSize * scale,
          pixelSize * scale,
        );

        canvas.drawRect(pixelRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelLoadingPainter oldDelegate) => true;
}

class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelLoadingAnimation(size: 180),
            const SizedBox(height: 32),
            if (message != null)
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
