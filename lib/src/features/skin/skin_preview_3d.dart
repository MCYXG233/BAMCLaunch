import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../account/skin_manager.dart';

/// 3D皮肤预览组件
/// 使用Flutter CustomPaint实现基础的3D皮肤渲染效果
class SkinPreview3D extends StatefulWidget {
  /// 皮肤图像数据
  final Uint8List? skinImage;

  /// 披风图像数据
  final Uint8List? capeImage;

  /// 皮肤类型（Steve或Alex）
  final SkinType skinType;

  /// 初始旋转角度（水平）
  final double initialRotationX;

  /// 初始旋转角度（垂直）
  final double initialRotationY;

  /// 初始缩放
  final double initialScale;

  /// 宽度
  final double width;

  /// 高度
  final double height;

  /// 背景颜色
  final Color? backgroundColor;

  const SkinPreview3D({
    super.key,
    this.skinImage,
    this.capeImage,
    this.skinType = SkinType.steve,
    this.initialRotationX = 0.0,
    this.initialRotationY = -0.3,
    this.initialScale = 1.5,
    this.width = 300,
    this.height = 400,
    this.backgroundColor,
  });

  @override
  State<SkinPreview3D> createState() => _SkinPreview3DState();
}

class _SkinPreview3DState extends State<SkinPreview3D> {
  late double _rotationX;
  late double _rotationY;
  late double _scale;
  Offset? _lastPanPosition;
  double _capeAnimationPhase = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationX = widget.initialRotationX;
    _rotationY = widget.initialRotationY;
    _scale = widget.initialScale;
  }

  @override
  void didUpdateWidget(SkinPreview3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skinImage != widget.skinImage ||
        oldWidget.capeImage != widget.capeImage ||
        oldWidget.skinType != widget.skinType) {
      setState(() {});
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    final delta = details.localPosition - _lastPanPosition!;
    setState(() {
      _rotationY += delta.dx * 0.01;
      _rotationX += delta.dy * 0.01;
      _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
    });
    _lastPanPosition = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.5, 4.0);
    });
  }

  void _handleDoubleTap() {
    setState(() {
      _rotationX = widget.initialRotationX;
      _rotationY = widget.initialRotationY;
      _scale = widget.initialScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onScaleUpdate: _handleScaleUpdate,
      onDoubleTap: _handleDoubleTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _SkinPainter(
              skinImage: widget.skinImage,
              capeImage: widget.capeImage,
              skinType: widget.skinType,
              rotationX: _rotationX,
              rotationY: _rotationY,
              scale: _scale,
            ),
            size: Size(widget.width, widget.height),
          ),
        ),
      ),
    );
  }
}

/// Minecraft皮肤像素数据
class SkinPixels {
  // Steve模型尺寸：64x64像素
  // Alex模型尺寸：64x64像素（但手臂更窄）

  // Steve手臂：x: 40-48, y: 16-20（右侧手臂外层）
  // Alex手臂：x: 40-46, y: 16-20（右侧手臂外层，更窄）

  /// Steve模型 - 手臂宽度
  static const int steveArmWidth = 8;
  static const int steveArmHeight = 12;

  /// Alex模型 - 手臂宽度（更窄）
  static const int alexArmWidth = 6;
  static const int alexArmHeight = 12;

  /// 获取皮肤类型的实际手臂宽度
  static int getArmWidth(SkinType type) {
    return type == SkinType.alex ? alexArmWidth : steveArmWidth;
  }
}

/// 3D皮肤渲染绘制器
class _SkinPainter extends CustomPainter {
  final Uint8List? skinImage;
  final Uint8List? capeImage;
  final SkinType skinType;
  final double rotationX;
  final double rotationY;
  final double scale;

  _SkinPainter({
    this.skinImage,
    this.capeImage,
    required this.skinType,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final pixelSize = scale * 2.5;

    // 绘制背景网格
    _drawBackground(canvas, size);

    // 应用旋转变换
    canvas.save();
    canvas.translate(centerX, centerY);

    // 绘制角色（按深度排序）
    _drawCape(canvas, pixelSize);
    _drawBody(canvas, pixelSize);
    _drawHead(canvas, pixelSize);
    _drawArms(canvas, pixelSize);
    _drawLegs(canvas, pixelSize);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a1a2e).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 绘制网格线
    final gridPaint = Paint()
      ..color = const Color(0xFF3d3d5c).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawHead(Canvas canvas, double pixelSize) {
    final headPaint = Paint()..style = PaintingStyle.fill;

    // 简化的头部渲染 - 白色方块表示
    headPaint.color = const Color(0xFF8B8B8B);
    final headWidth = pixelSize * 8;
    final headHeight = pixelSize * 8;
    final headY = -pixelSize * 18;

    // 头部前后面
    _drawSkinRect(
      canvas,
      -headWidth / 2,
      headY,
      headWidth,
      headHeight,
      headPaint,
      isFront: true,
    );

    // 头部顶面
    headPaint.color = const Color(0xFF6B6B6B);
    canvas.drawRect(
      Rect.fromLTWH(-headWidth / 2, headY - pixelSize, headWidth, pixelSize),
      headPaint,
    );

    // 头发/帽子（使用蓝色）
    headPaint.color = const Color(0xFF3D3D3D);
    _drawSkinRect(
      canvas,
      -headWidth / 2,
      headY - pixelSize,
      headWidth,
      pixelSize * 2,
      headPaint,
      isFront: true,
    );
  }

  void _drawBody(Canvas canvas, double pixelSize) {
    final bodyPaint = Paint()..style = PaintingStyle.fill;

    final bodyWidth = pixelSize * 8;
    final bodyHeight = pixelSize * 12;
    final bodyY = -pixelSize * 10;

    // 身体前后面
    bodyPaint.color = const Color(0xFF00AAAA);
    _drawSkinRect(
      canvas,
      -bodyWidth / 2,
      bodyY,
      bodyWidth,
      bodyHeight,
      bodyPaint,
      isFront: true,
    );

    // 身体侧面（更深颜色）
    bodyPaint.color = const Color(0xFF008888);
    canvas.drawRect(
      Rect.fromLTWH(-bodyWidth / 2, bodyY, pixelSize, bodyHeight),
      bodyPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bodyWidth / 2 - pixelSize, bodyY, pixelSize, bodyHeight),
      bodyPaint,
    );
  }

  void _drawArms(Canvas canvas, double pixelSize) {
    final armPaint = Paint()..style = PaintingStyle.fill;
    final armWidth = SkinPixels.getArmWidth(skinType) * pixelSize;
    final armHeight = pixelSize * 12;
    final armY = -pixelSize * 10;

    // 手臂颜色
    armPaint.color = skinType == SkinType.alex
        ? const Color(0xFF9B59B6) // Alex手臂颜色（紫色袖子）
        : const Color(0xFF00AAAA); // Steve手臂颜色

    // 左臂
    _drawSkinRect(
      canvas,
      -pixelSize * 8 - armWidth,
      armY,
      armWidth,
      armHeight,
      armPaint,
      isFront: true,
    );

    // 右臂
    _drawSkinRect(
      canvas,
      pixelSize * 8,
      armY,
      armWidth,
      armHeight,
      armPaint,
      isFront: true,
    );

    // 手臂外侧（袖子颜色）
    armPaint.color = skinType == SkinType.alex
        ? const Color(0xFF8E44AD)
        : const Color(0xFF008888);
    canvas.drawRect(
      Rect.fromLTWH(-pixelSize * 8 - armWidth, armY, pixelSize, armHeight),
      armPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pixelSize * 8 + armWidth - pixelSize, armY, pixelSize, armHeight),
      armPaint,
    );
  }

  void _drawLegs(Canvas canvas, double pixelSize) {
    final legPaint = Paint()..style = PaintingStyle.fill;

    final legWidth = pixelSize * 4;
    final legHeight = pixelSize * 12;
    final legY = pixelSize * 2;

    // 腿部颜色
    legPaint.color = const Color(0xFF1E90FF); // 蓝色裤子

    // 左腿
    _drawSkinRect(
      canvas,
      -pixelSize * 4 - legWidth,
      legY,
      legWidth,
      legHeight,
      legPaint,
      isFront: true,
    );

    // 右腿
    _drawSkinRect(
      canvas,
      pixelSize * 4,
      legY,
      legWidth,
      legHeight,
      legPaint,
      isFront: true,
    );

    // 腿部外侧
    legPaint.color = const Color(0xFF1873CC);
    canvas.drawRect(
      Rect.fromLTWH(-pixelSize * 4 - legWidth, legY, pixelSize, legHeight),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pixelSize * 4 + legWidth - pixelSize, legY, pixelSize, legHeight),
      legPaint,
    );
  }

  void _drawCape(Canvas canvas, double pixelSize) {
    if (capeImage == null) return;

    final capePaint = Paint()..style = PaintingStyle.fill;

    // 披风颜色（红色）
    capePaint.color = const Color(0xFFAA0000);

    final capeWidth = pixelSize * 10;
    final capeHeight = pixelSize * 16;
    final capeY = -pixelSize * 8;

    // 披风主体（带有飘动效果）
    final waveOffset = math.sin(rotationY * 2 + 1.0) * pixelSize * 0.5;

    _drawSkinRect(
      canvas,
      -capeWidth / 2 + waveOffset,
      capeY,
      capeWidth,
      capeHeight,
      capePaint,
      isFront: false, // 披风在后面
    );

    // 披风边缘
    capePaint.color = const Color(0xFF880000);
    canvas.drawRect(
      Rect.fromLTWH(-capeWidth / 2 + waveOffset, capeY, pixelSize, capeHeight),
      capePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(capeWidth / 2 - pixelSize + waveOffset, capeY, pixelSize, capeHeight),
      capePaint,
    );
  }

  void _drawSkinRect(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Paint paint, {
    required bool isFront,
  }) {
    // 根据旋转角度计算深度遮挡
    final normalizedRotation = rotationY % (2 * math.pi);
    final facingFront = normalizedRotation > -math.pi / 2 && normalizedRotation < math.pi / 2;

    if (isFront == facingFront || isFront) {
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.scale != scale ||
        oldDelegate.skinImage != skinImage ||
        oldDelegate.capeImage != capeImage ||
        oldDelegate.skinType != skinType;
  }
}

/// 皮肤预览管理器
/// 负责加载和管理皮肤纹理的类
class SkinPreviewManager {
  static SkinPreviewManager? _instance;
  final Logger _logger = Logger('SkinPreviewManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 缓存目录
  Directory? _cacheDir;

  /// 默认Steve皮肤图像
  Uint8List? _defaultSteveSkin;

  /// 默认Alex皮肤图像
  Uint8List? _defaultAlexSkin;

  SkinPreviewManager._internal();

  static SkinPreviewManager get instance {
    _instance ??= SkinPreviewManager._internal();
    return _instance!;
  }

  factory SkinPreviewManager() => instance;

  /// 初始化管理器
  Future<void> initialize() async {
    if (_cacheDir != null) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _cacheDir = Directory(path.join(supportDir, 'skins'));

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _logger.info('Skin preview manager initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize skin preview manager', e, stackTrace);
    }
  }

  /// 加载用户皮肤
  Future<Uint8List?> loadUserSkin(Account account) async {
    await initialize();

    // 尝试从账户配置的皮肤URL加载
    if (account.skinUrl != null) {
      try {
        return await _downloadSkin(account.skinUrl!);
      } catch (e) {
        _logger.warn('Failed to load skin from URL: $e');
      }
    }

    // 尝试从本地文件加载
    if (_cacheDir != null) {
      final skinFile = File(path.join(_cacheDir!.path, '${account.id}_skin.png'));
      if (await skinFile.exists()) {
        return await skinFile.readAsBytes();
      }
    }

    // 返回默认皮肤
    return getDefaultSkin(account.modelType);
  }

  /// 加载用户披风
  Future<Uint8List?> loadUserCape(Account account) async {
    await initialize();

    // 尝试从账户配置的披风URL加载
    if (account.capeUrl != null) {
      try {
        return await _downloadSkin(account.capeUrl!);
      } catch (e) {
        _logger.warn('Failed to load cape from URL: $e');
      }
    }

    // 尝试从本地文件加载
    if (_cacheDir != null) {
      final capeFile = File(path.join(_cacheDir!.path, '${account.id}_cape.png'));
      if (await capeFile.exists()) {
        return await capeFile.readAsBytes();
      }
    }

    return null;
  }

  /// 从网络下载皮肤/披风
  Future<Uint8List> _downloadSkin(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'BAMCLaunch/1.0');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Download failed with ${response.statusCode}');
      }

      return await response.expand((chunk) => chunk).toList().then(
        (bytes) => Uint8List.fromList(bytes),
      );
    } finally {
      client.close();
    }
  }

  /// 获取默认皮肤
  Uint8List? getDefaultSkin(SkinType type) {
    // 这里返回null，UI会使用默认的着色
    return null;
  }

  /// 获取用户本地皮肤目录
  Future<String> getLocalSkinDirectory() async {
    await initialize();
    final homeDir = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    _cacheDir?.path ??
                    '';
    return path.join(homeDir, '.minecraft', 'skins');
  }

  /// 获取用户本地披风目录
  Future<String> getLocalCapeDirectory() async {
    await initialize();
    final homeDir = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    _cacheDir?.path ??
                    '';
    return path.join(homeDir, '.minecraft', 'capes');
  }

  /// 列出本地皮肤
  Future<List<String>> listLocalSkins() async {
    final skinDir = await getLocalSkinDirectory();
    final dir = Directory(skinDir);

    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .map((f) => path.basename(f.path))
        .toList();
  }

  /// 列出本地披风
  Future<List<String>> listLocalCapes() async {
    final capeDir = await getLocalCapeDirectory();
    final dir = Directory(capeDir);

    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .map((f) => path.basename(f.path))
        .toList();
  }

  /// 计算文件哈希
  String calculateFileHash(Uint8List data) {
    return sha1.convert(data).toString();
  }
}
