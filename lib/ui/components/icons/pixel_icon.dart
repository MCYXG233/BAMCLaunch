import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum PixelIconType {
  search,
  user,
  lock,
  email,
  settings,
  gamepad,
  chest,
  craftTable,
  close,
}

class PixelIcon extends StatelessWidget {
  final PixelIconType iconType;
  final double size;
  final Color? color;

  const PixelIcon({
    super.key,
    required this.iconType,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? BamcColors.textSecondary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(
          iconType: iconType,
          color: iconColor,
        ),
      ),
    );
  }
}

class _PixelIconPainter extends CustomPainter {
  final PixelIconType iconType;
  final Color color;

  _PixelIconPainter({
    required this.iconType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final pixelSize = size.width / 8;

    switch (iconType) {
      case PixelIconType.search:
        _drawSearchIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.user:
        _drawUserIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.lock:
        _drawLockIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.email:
        _drawEmailIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.settings:
        _drawSettingsIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.gamepad:
        _drawGamepadIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.chest:
        _drawChestIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.craftTable:
        _drawCraftTableIcon(canvas, size, paint, pixelSize);
        break;
      case PixelIconType.close:
        _drawCloseIcon(canvas, size, paint, pixelSize);
        break;
    }
  }

  void _drawPixel(Canvas canvas, double x, double y, double pixelSize, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
      paint,
    );
  }

  void _drawSearchIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [2, 1], [3, 1], [4, 1],
      [1, 2], [2, 2], [4, 2], [5, 2],
      [1, 3], [2, 3], [4, 3],
      [2, 4], [3, 4], [4, 4], [5, 4],
      [5, 5], [6, 5],
      [6, 6], [7, 6],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  void _drawUserIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [3, 0], [4, 0],
      [2, 1], [3, 1], [4, 1], [5, 1],
      [2, 2], [3, 2], [4, 2], [5, 2],
      [3, 3], [4, 3],
      [2, 4], [3, 4], [4, 4], [5, 4],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
      [1, 6], [2, 6], [5, 6], [6, 6],
      [1, 7], [2, 7], [5, 7], [6, 7],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  void _drawLockIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [2, 0], [3, 0], [4, 0], [5, 0],
      [1, 1], [6, 1],
      [1, 2], [6, 2],
      [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
      [2, 5], [3, 5], [4, 5], [5, 5],
      [2, 6], [3, 6], [4, 6], [5, 6],
      [3, 7], [4, 7],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  void _drawEmailIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
      [0, 2], [1, 2], [6, 2], [7, 2],
      [0, 3], [1, 3], [3, 3], [4, 3], [6, 3], [7, 3],
      [0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5],
      [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  void _drawSettingsIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [3, 0], [4, 0],
      [2, 1], [3, 1], [4, 1], [5, 1],
      [1, 2], [2, 2], [5, 2], [6, 2],
      [0, 3], [1, 3], [6, 3], [7, 3],
      [1, 4], [2, 4], [5, 4], [6, 4],
      [2, 5], [3, 5], [4, 5], [5, 5],
      [3, 6], [4, 6],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
    final centerPaint = Paint()
      ..color = BamcColors.background
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    final centerPixels = [
      [3, 3], [4, 3],
      [3, 4], [4, 4],
    ];
    for (final pixel in centerPixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, centerPaint);
    }
  }

  void _drawGamepadIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3],
      [0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  void _drawChestIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3],
      [0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5],
      [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
    final lockPaint = Paint()
      ..color = BamcColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    final lockPixels = [
      [3, 3], [4, 3],
      [3, 4], [4, 4],
    ];
    for (final pixel in lockPixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, lockPaint);
    }
  }

  void _drawCraftTableIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
      [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
      [2, 6], [3, 6], [4, 6], [5, 6],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
    final gridPaint = Paint()
      ..color = BamcColors.secondary
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    final gridPixels = [
      [2, 2], [4, 2],
      [3, 3],
      [2, 4], [4, 4],
    ];
    for (final pixel in gridPixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, gridPaint);
    }
  }

  void _drawCloseIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final pixels = [
      [1, 1], [2, 1],
      [2, 2], [3, 2], [4, 2], [5, 2],
      [3, 3], [4, 3],
      [2, 4], [3, 4], [4, 4], [5, 4],
      [1, 5], [2, 5], [5, 5], [6, 5],
    ];
    for (final pixel in pixels) {
      _drawPixel(canvas, pixel[0].toDouble(), pixel[1].toDouble(), pixelSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
