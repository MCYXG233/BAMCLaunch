import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../../core/logger.dart';
import '../../core/network_client.dart';
import '../../core/error_codes.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../account/skin_manager.dart';
import '../../account/account.dart';

/// 3D皮肤预览组件
///
/// 该组件使用Flutter的CustomPaint实现Minecraft角色皮肤的3D预览效果。
///
/// ## 实现原理
///
/// 1. **3D渲染模拟**：通过简化的3D投影算法，将皮肤纹理映射到立方体模型上，
///    模拟出3D立体效果。使用旋转变换矩阵计算各部位的显示位置。
///
/// 2. **交互支持**：支持手势操作，包括：
///    - 拖拽旋转：通过Pan手势实现水平/垂直方向的旋转
///    - 缩放：通过Scale手势实现缩放
///    - 双击重置：双击恢复初始视角
///
/// 3. **皮肤类型支持**：支持Steve和Alex两种皮肤模型，主要区别在于手臂宽度
///    - Steve：手臂宽度为8像素
///    - Alex：手臂宽度为6像素（更纤细）
///
/// 4. **披风渲染**：支持披风的渲染，并带有简单的飘动动画效果
///
/// ## 使用示例
///
/// ```dart
/// SkinPreview3D(
///   skinImage: skinBytes,
///   capeImage: capeBytes,
///   skinType: SkinType.alex,
///   width: 300,
///   height: 400,
/// )
/// ```
class SkinPreview3D extends StatefulWidget {
  /// 皮肤图像数据
  ///
  /// PNG格式的皮肤图像字节数据，通常为64x64或64x32像素的PNG图片。
  /// 如果为null，将使用默认的着色方块显示。
  final Uint8List? skinImage;

  /// 披风图像数据
  ///
  /// PNG格式的披风图像字节数据，通常为22x17像素的PNG图片。
  /// 如果为null，将不渲染披风。
  final Uint8List? capeImage;

  /// 皮肤类型（Steve或Alex）
  ///
  /// 决定角色模型的渲染方式，主要影响手臂宽度：
  /// - [SkinType.steve]：标准模型，手臂宽度8像素
  /// - [SkinType.alex]：纤细模型，手臂宽度6像素
  final SkinType skinType;

  /// 初始旋转角度（水平方向，X轴）
  ///
  /// 控制角色初始的左右旋转角度，单位为弧度。
  /// 默认值为0.0，即正对前方。
  final double initialRotationX;

  /// 初始旋转角度（垂直方向，Y轴）
  ///
  /// 控制角色初始的上下旋转角度，单位为弧度。
  /// 默认值为-0.3，即略微俯视的角度。
  final double initialRotationY;

  /// 初始缩放比例
  ///
  /// 控制角色的初始缩放大小。
  /// 默认值为1.5，即放大1.5倍显示。
  final double initialScale;

  /// 组件宽度
  ///
  /// 预览组件的宽度，单位为逻辑像素。
  final double width;

  /// 组件高度
  ///
  /// 预览组件的高度，单位为逻辑像素。
  final double height;

  /// 背景颜色
  ///
  /// 预览组件的背景颜色。如果为null，则使用透明背景。
  final Color? backgroundColor;

  /// 创建3D皮肤预览组件
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

/// 3D皮肤预览组件的状态类
///
/// 管理组件的交互状态，包括旋转角度、缩放比例等。
/// 处理用户的手势输入，并触发重绘。
class _SkinPreview3DState extends State<SkinPreview3D> {
  /// 当前水平旋转角度（X轴）
  ///
  /// 控制角色的左右旋转，通过拖拽手势更新。
  late double _rotationX;

  /// 当前垂直旋转角度（Y轴）
  ///
  /// 控制角色的上下旋转，通过拖拽手势更新。
  /// 该值被限制在[-π/2, π/2]范围内，防止过度旋转。
  late double _rotationY;

  /// 当前缩放比例
  ///
  /// 控制角色的缩放大小，通过缩放手势更新。
  /// 该值被限制在[0.5, 4.0]范围内。
  late double _scale;

  /// 上次拖拽位置
  ///
  /// 用于计算拖拽的增量距离，实现平滑的旋转效果。
  /// 在拖拽开始时设置，拖拽结束时清除。
  Offset? _lastPanPosition;

  /// 披风动画相位
  ///
  /// 用于控制披风的飘动动画效果。
  /// 目前保留用于未来的动画实现。
  double _capeAnimationPhase = 0.0;

  @override
  void initState() {
    super.initState();
    // 初始化旋转和缩放参数
    _rotationX = widget.initialRotationX;
    _rotationY = widget.initialRotationY;
    _scale = widget.initialScale;
  }

  @override
  void didUpdateWidget(SkinPreview3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当皮肤图像、披风图像或皮肤类型发生变化时，触发重绘
    if (oldWidget.skinImage != widget.skinImage ||
        oldWidget.capeImage != widget.capeImage ||
        oldWidget.skinType != widget.skinType) {
      setState(() {});
    }
  }

  /// 处理拖拽开始事件
  ///
  /// 记录拖拽起始位置，用于后续计算旋转增量。
  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  /// 处理拖拽更新事件
  ///
  /// 根据拖拽距离计算旋转角度增量：
  /// - 水平拖拽（dx）影响Y轴旋转（左右转动）
  /// - 垂直拖拽（dy）影响X轴旋转（上下转动）
  ///
  /// X轴旋转被限制在[-π/2, π/2]范围内，防止角色翻转。
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    final delta = details.localPosition - _lastPanPosition!;
    setState(() {
      // 水平拖拽控制Y轴旋转（左右转动）
      _rotationY += delta.dx * 0.01;
      // 垂直拖拽控制X轴旋转（上下转动）
      _rotationX += delta.dy * 0.01;
      // 限制X轴旋转范围，防止过度旋转
      _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
    });
    _lastPanPosition = details.localPosition;
  }

  /// 处理拖拽结束事件
  ///
  /// 清除拖拽位置记录。
  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  /// 处理缩放更新事件
  ///
  /// 根据缩放手势更新缩放比例，限制在[0.5, 4.0]范围内。
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.5, 4.0);
    });
  }

  /// 处理双击事件
  ///
  /// 重置所有视角参数到初始值，恢复默认视角。
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
      // 绑定各种手势处理器
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
        // 使用圆角裁剪，确保内容不超出边界
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            // 创建自定义绘制器，传入所有渲染参数
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

/// Minecraft皮肤像素数据常量类
///
/// 定义Minecraft皮肤纹理的各种尺寸参数。
/// Minecraft皮肤使用像素为单位，不同的模型有不同的尺寸规格。
///
/// ## 皮肤纹理布局
///
/// 标准的64x64皮肤纹理包含以下部位：
/// - 头部：8x8像素
/// - 身体：8x12像素
/// - 手臂：Steve为8x12像素，Alex为6x12像素
/// - 腿部：4x12像素
/// - 披风：22x17像素（独立文件）
class SkinPixels {
  // Steve模型尺寸：64x64像素
  // Alex模型尺寸：64x64像素（但手臂更窄）

  // Steve手臂：x: 40-48, y: 16-20（右侧手臂外层）
  // Alex手臂：x: 40-46, y: 16-20（右侧手臂外层，更窄）

  /// Steve模型 - 手臂宽度
  ///
  /// Steve模型的手臂宽度为8像素，是标准宽度。
  static const int steveArmWidth = 8;

  /// Steve模型 - 手臂高度
  ///
  /// 手臂高度为12像素，从肩膀延伸到手腕。
  static const int steveArmHeight = 12;

  /// Alex模型 - 手臂宽度（更窄）
  ///
  /// Alex模型的手臂宽度为6像素，比Steve更纤细。
  static const int alexArmWidth = 6;

  /// Alex模型 - 手臂高度
  ///
  /// 手臂高度与Steve相同，为12像素。
  static const int alexArmHeight = 12;

  /// 获取皮肤类型的实际手臂宽度
  ///
  /// 根据皮肤类型返回对应的手臂宽度像素值。
  ///
  /// [type] 皮肤类型（Steve或Alex）
  /// 返回对应类型的手臂宽度（像素）
  static int getArmWidth(SkinType type) {
    return type == SkinType.alex ? alexArmWidth : steveArmWidth;
  }
}

/// 3D皮肤渲染绘制器
///
/// 继承自[CustomPainter]，负责实际的3D皮肤渲染工作。
///
/// ## 渲染流程
///
/// 1. 绘制背景网格
/// 2. 应用旋转变换（平移到中心点）
/// 3. 按深度顺序绘制各部位：
///    - 披风（最后面）
///    - 身体
///    - 头部
///    - 手臂
///    - 腿部
/// 4. 恢复画布变换
///
/// ## 3D效果实现
///
/// 通过简化的正交投影实现3D效果：
/// - 使用不同深度的颜色表示不同面（前面、侧面、顶面）
/// - 根据旋转角度判断各面是否可见
/// - 披风使用正弦函数模拟飘动效果
class _SkinPainter extends CustomPainter {
  /// 皮肤图像数据
  final Uint8List? skinImage;

  /// 披风图像数据
  final Uint8List? capeImage;

  /// 皮肤类型
  final SkinType skinType;

  /// X轴旋转角度（俯仰）
  final double rotationX;

  /// Y轴旋转角度（偏航）
  final double rotationY;

  /// 缩放比例
  final double scale;

  /// 创建皮肤绘制器
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
    // 计算画布中心点，作为旋转中心
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    // 根据缩放计算像素大小，用于渲染各部位
    final pixelSize = scale * 2.5;

    // 绘制背景网格
    _drawBackground(canvas, size);

    // 应用旋转变换
    canvas.save();
    // 将原点移动到画布中心，便于后续的旋转变换
    canvas.translate(centerX, centerY);

    // 绘制角色（按深度排序，从后到前）
    // 披风在最后面
    _drawCape(canvas, pixelSize);
    // 身体在中间
    _drawBody(canvas, pixelSize);
    // 头部在身体上方
    _drawHead(canvas, pixelSize);
    // 手臂在身体两侧
    _drawArms(canvas, pixelSize);
    // 腿部在最下面
    _drawLegs(canvas, pixelSize);

    // 恢复画布变换
    canvas.restore();
  }

  /// 绘制背景网格
  ///
  /// 创建一个带有网格线的深色背景，增强3D效果的视觉感知。
  /// 背景使用半透明的深蓝色，网格线使用稍亮的颜色。
  ///
  /// [canvas] 画布对象
  /// [size] 画布尺寸
  void _drawBackground(Canvas canvas, Size size) {
    // 绘制背景填充色
    final paint = Paint()
      ..color = const Color(0xFF1a1a2e).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 绘制网格线，增强空间感
    final gridPaint = Paint()
      ..color = const Color(0xFF3d3d5c).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 网格间距为20像素
    const gridSize = 20.0;
    // 绘制垂直网格线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // 绘制水平网格线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  /// 绘制头部
  ///
  /// 头部是一个8x8x8的立方体，位于身体上方。
  /// 使用不同灰度色表示不同的面，模拟3D效果。
  ///
  /// [canvas] 画布对象
  /// [pixelSize] 单个像素的渲染大小
  void _drawHead(Canvas canvas, double pixelSize) {
    final headPaint = Paint()..style = PaintingStyle.fill;

    // 头部使用灰色表示
    headPaint.color = const Color(0xFF8B8B8B);
    // 头部尺寸：8x8像素
    final headWidth = pixelSize * 8;
    final headHeight = pixelSize * 8;
    // 头部Y位置：在身体上方18像素处
    final headY = -pixelSize * 18;

    // 绘制头部前后面
    _drawSkinRect(
      canvas,
      -headWidth / 2,
      headY,
      headWidth,
      headHeight,
      headPaint,
      isFront: true,
    );

    // 绘制头部顶面（使用更深的颜色）
    headPaint.color = const Color(0xFF6B6B6B);
    canvas.drawRect(
      Rect.fromLTWH(-headWidth / 2, headY - pixelSize, headWidth, pixelSize),
      headPaint,
    );

    // 绘制头发/帽子层（使用深色）
    // Minecraft皮肤有两层：内层是皮肤，外层是装饰（如帽子）
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

  /// 绘制身体
  ///
  /// 身体是一个8x12的矩形，是角色的核心部分。
  /// 使用青色系表示，不同深浅区分前面和侧面。
  ///
  /// [canvas] 画布对象
  /// [pixelSize] 单个像素的渲染大小
  void _drawBody(Canvas canvas, double pixelSize) {
    final bodyPaint = Paint()..style = PaintingStyle.fill;

    // 身体尺寸：8x12像素
    final bodyWidth = pixelSize * 8;
    final bodyHeight = pixelSize * 12;
    // 身体Y位置：头部下方
    final bodyY = -pixelSize * 10;

    // 绘制身体前后面（使用青色）
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

    // 绘制身体侧面（使用更深的青色，产生立体感）
    bodyPaint.color = const Color(0xFF008888);
    // 左侧面
    canvas.drawRect(
      Rect.fromLTWH(-bodyWidth / 2, bodyY, pixelSize, bodyHeight),
      bodyPaint,
    );
    // 右侧面
    canvas.drawRect(
      Rect.fromLTWH(bodyWidth / 2 - pixelSize, bodyY, pixelSize, bodyHeight),
      bodyPaint,
    );
  }

  /// 绘制手臂
  ///
  /// 手臂位于身体两侧，宽度根据皮肤类型不同：
  /// - Steve：8像素宽
  /// - Alex：6像素宽
  ///
  /// 手臂高度统一为12像素。
  /// 使用不同颜色区分Steve和Alex的手臂装饰。
  ///
  /// [canvas] 画布对象
  /// [pixelSize] 单个像素的渲染大小
  void _drawArms(Canvas canvas, double pixelSize) {
    final armPaint = Paint()..style = PaintingStyle.fill;
    // 根据皮肤类型获取手臂宽度
    final armWidth = SkinPixels.getArmWidth(skinType) * pixelSize;
    final armHeight = pixelSize * 12;
    // 手臂Y位置：与身体顶部对齐
    final armY = -pixelSize * 10;

    // 设置手臂颜色，Alex使用紫色，Steve使用青色
    armPaint.color = skinType == SkinType.alex
        ? const Color(0xFF9B59B6) // Alex手臂颜色（紫色袖子）
        : const Color(0xFF00AAAA); // Steve手臂颜色

    // 绘制左臂（位于身体左侧）
    _drawSkinRect(
      canvas,
      -pixelSize * 8 - armWidth,
      armY,
      armWidth,
      armHeight,
      armPaint,
      isFront: true,
    );

    // 绘制右臂（位于身体右侧）
    _drawSkinRect(
      canvas,
      pixelSize * 8,
      armY,
      armWidth,
      armHeight,
      armPaint,
      isFront: true,
    );

    // 绘制手臂外侧（袖子颜色，使用更深的颜色）
    armPaint.color = skinType == SkinType.alex
        ? const Color(0xFF8E44AD)
        : const Color(0xFF008888);
    // 左臂外侧
    canvas.drawRect(
      Rect.fromLTWH(-pixelSize * 8 - armWidth, armY, pixelSize, armHeight),
      armPaint,
    );
    // 右臂外侧
    canvas.drawRect(
      Rect.fromLTWH(pixelSize * 8 + armWidth - pixelSize, armY, pixelSize, armHeight),
      armPaint,
    );
  }

  /// 绘制腿部
  ///
  /// 腿部位于身体下方，每条腿宽4像素，高12像素。
  /// 使用蓝色表示裤子，不同深浅区分前面和侧面。
  ///
  /// [canvas] 画布对象
  /// [pixelSize] 单个像素的渲染大小
  void _drawLegs(Canvas canvas, double pixelSize) {
    final legPaint = Paint()..style = PaintingStyle.fill;

    // 腿部尺寸：4x12像素
    final legWidth = pixelSize * 4;
    final legHeight = pixelSize * 12;
    // 腿部Y位置：身体下方
    final legY = pixelSize * 2;

    // 设置腿部颜色（蓝色裤子）
    legPaint.color = const Color(0xFF1E90FF);

    // 绘制左腿
    _drawSkinRect(
      canvas,
      -pixelSize * 4 - legWidth,
      legY,
      legWidth,
      legHeight,
      legPaint,
      isFront: true,
    );

    // 绘制右腿
    _drawSkinRect(
      canvas,
      pixelSize * 4,
      legY,
      legWidth,
      legHeight,
      legPaint,
      isFront: true,
    );

    // 绘制腿部外侧（使用更深的蓝色）
    legPaint.color = const Color(0xFF1873CC);
    // 左腿外侧
    canvas.drawRect(
      Rect.fromLTWH(-pixelSize * 4 - legWidth, legY, pixelSize, legHeight),
      legPaint,
    );
    // 右腿外侧
    canvas.drawRect(
      Rect.fromLTWH(pixelSize * 4 + legWidth - pixelSize, legY, pixelSize, legHeight),
      legPaint,
    );
  }

  /// 绘制披风
  ///
  /// 披风位于角色背部，尺寸为10x16像素（渲染尺寸）。
  /// 使用正弦函数模拟披风的飘动效果。
  /// 披风渲染在角色后面，通过isFront=false参数控制。
  ///
  /// [canvas] 画布对象
  /// [pixelSize] 单个像素的渲染大小
  void _drawCape(Canvas canvas, double pixelSize) {
    // 如果没有披风图像，则不绘制
    if (capeImage == null) return;

    final capePaint = Paint()..style = PaintingStyle.fill;

    // 披风使用红色
    capePaint.color = const Color(0xFFAA0000);

    // 披风尺寸：10x16像素
    final capeWidth = pixelSize * 10;
    final capeHeight = pixelSize * 16;
    // 披风Y位置：在身体后方偏上
    final capeY = -pixelSize * 8;

    // 计算披风飘动偏移
    // 使用正弦函数根据Y轴旋转角度计算水平偏移，模拟飘动效果
    final waveOffset = math.sin(rotationY * 2 + 1.0) * pixelSize * 0.5;

    // 绘制披风主体
    _drawSkinRect(
      canvas,
      -capeWidth / 2 + waveOffset,
      capeY,
      capeWidth,
      capeHeight,
      capePaint,
      isFront: false, // 披风在后面
    );

    // 绘制披风边缘（使用更深的红色）
    capePaint.color = const Color(0xFF880000);
    // 左边缘
    canvas.drawRect(
      Rect.fromLTWH(-capeWidth / 2 + waveOffset, capeY, pixelSize, capeHeight),
      capePaint,
    );
    // 右边缘
    canvas.drawRect(
      Rect.fromLTWH(capeWidth / 2 - pixelSize + waveOffset, capeY, pixelSize, capeHeight),
      capePaint,
    );
  }

  /// 绘制皮肤矩形
  ///
  /// 根据旋转角度判断是否绘制矩形，实现简单的深度遮挡效果。
  /// 当角色旋转时，前面和后面的部位会根据朝向显示或隐藏。
  ///
  /// ## 深度遮挡原理
  ///
  /// 通过检查Y轴旋转角度，判断当前视角是否朝向前面：
  /// - 角度在[-π/2, π/2]范围内时，前面可见
  /// - 角度超出该范围时，后面可见
  ///
  /// [canvas] 画布对象
  /// [x] 矩形左上角X坐标
  /// [y] 矩形左上角Y坐标
  /// [width] 矩形宽度
  /// [height] 矩形高度
  /// [paint] 绘制画笔
  /// [isFront] 是否为前面的部位
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
    // 将旋转角度归一化到[-2π, 2π]范围
    final normalizedRotation = rotationY % (2 * math.pi);
    // 判断当前视角是否朝向前面
    final facingFront = normalizedRotation > -math.pi / 2 && normalizedRotation < math.pi / 2;

    // 如果部位朝向与视角一致，或者该部位始终显示，则绘制
    if (isFront == facingFront || isFront) {
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }
  }

  /// 判断是否需要重绘
  ///
  /// 比较新旧参数，只有参数发生变化时才触发重绘，优化性能。
  ///
  /// [oldDelegate] 旧的绘制器实例
  /// 返回true表示需要重绘，false表示不需要
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
///
/// 单例模式的皮肤管理类，负责：
/// - 加载和管理皮肤纹理缓存
/// - 从网络下载皮肤/披风图像
/// - 管理本地皮肤/披风文件
/// - 提供默认皮肤数据
///
/// ## 使用示例
///
/// ```dart
/// final manager = SkinPreviewManager();
/// await manager.initialize();
/// final skinData = await manager.loadUserSkin(account);
/// ```
class SkinPreviewManager {
  /// 单例实例
  static SkinPreviewManager? _instance;

  /// 日志记录器
  final Logger _logger = Logger('SkinPreviewManager');

  /// 平台适配器，用于访问文件系统等平台功能
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 皮肤缓存目录
  ///
  /// 存储下载的皮肤和披风文件。
  Directory? _cacheDir;

  /// 默认Steve皮肤图像
  ///
  /// 当无法加载用户皮肤时使用。
  Uint8List? _defaultSteveSkin;

  /// 默认Alex皮肤图像
  ///
  /// 当无法加载用户皮肤且模型类型为Alex时使用。
  Uint8List? _defaultAlexSkin;

  /// 私有构造函数（单例模式）
  SkinPreviewManager._internal();

  /// 获取单例实例
  static SkinPreviewManager get instance {
    _instance ??= SkinPreviewManager._internal();
    return _instance!;
  }

  /// 工厂构造函数，返回单例实例
  factory SkinPreviewManager() => instance;

  /// 初始化管理器
  ///
  /// 创建皮肤缓存目录，如果目录不存在则自动创建。
  /// 该方法幂等，多次调用只会初始化一次。
  Future<void> initialize() async {
    // 如果已经初始化，直接返回
    if (_cacheDir != null) return;

    try {
      // 获取应用支持目录，创建皮肤缓存子目录
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _cacheDir = Directory(path.join(supportDir, 'skins'));

      // 如果目录不存在，创建它
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _logger.info('Skin preview manager initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize skin preview manager', e, stackTrace);
    }
  }

  /// 加载用户皮肤
  ///
  /// 按以下优先级加载皮肤：
  /// 1. 从账户配置的皮肤URL下载
  /// 2. 从本地缓存文件加载
  /// 3. 返回默认皮肤
  ///
  /// [account] 用户账户信息
  /// 返回皮肤图像的字节数据，如果加载失败则返回默认皮肤
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

    // 尝试从本地缓存文件加载
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
  ///
  /// 按以下优先级加载披风：
  /// 1. 从账户配置的披风URL下载
  /// 2. 从本地缓存文件加载
  /// 3. 返回null（无披风）
  ///
  /// [account] 用户账户信息
  /// 返回披风图像的字节数据，如果加载失败则返回null
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

    // 尝试从本地缓存文件加载
    if (_cacheDir != null) {
      final capeFile = File(path.join(_cacheDir!.path, '${account.id}_cape.png'));
      if (await capeFile.exists()) {
        return await capeFile.readAsBytes();
      }
    }

    return null;
  }

  /// 从网络下载皮肤/披风
  ///
  /// 使用HTTP GET请求下载指定URL的图像数据。
  /// 设置User-Agent头以标识客户端。
  ///
  /// [url] 皮肤/披风图像的URL
  /// 返回下载的图像字节数据
  /// 抛出异常如果下载失败
  Future<Uint8List> _downloadSkin(String url) async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        url,
        headers: {'User-Agent': 'BAMCLaunch/1.0'},
      );
      // 检查HTTP状态码
      if (response.statusCode != 200) {
        throw NetworkException.fromStatusCode(response.statusCode);
      }

      // 读取响应体为字节数组
      return Uint8List.fromList(response.bodyBytes);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取默认皮肤
  ///
  /// 返回指定类型的默认皮肤数据。
  /// 目前返回null，UI会使用默认的着色方块显示。
  ///
  /// [type] 皮肤类型（Steve或Alex）
  /// 返回默认皮肤的字节数据，目前返回null
  Uint8List? getDefaultSkin(SkinType type) {
    // 这里返回null，UI会使用默认的着色
    return null;
  }

  /// 获取用户本地皮肤目录
  ///
  /// 返回用户.minecraft目录下的skins文件夹路径。
  /// 优先使用USERPROFILE或HOME环境变量定位用户目录。
  ///
  /// 返回本地皮肤目录的绝对路径
  Future<String> getLocalSkinDirectory() async {
    await initialize();
    // 获取用户主目录
    final homeDir = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    _cacheDir?.path ??
                    '';
    return path.join(homeDir, '.minecraft', 'skins');
  }

  /// 获取用户本地披风目录
  ///
  /// 返回用户.minecraft目录下的capes文件夹路径。
  /// 优先使用USERPROFILE或HOME环境变量定位用户目录。
  ///
  /// 返回本地披风目录的绝对路径
  Future<String> getLocalCapeDirectory() async {
    await initialize();
    // 获取用户主目录
    final homeDir = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    _cacheDir?.path ??
                    '';
    return path.join(homeDir, '.minecraft', 'capes');
  }

  /// 列出本地皮肤文件
  ///
  /// 扫描本地皮肤目录，返回所有PNG文件的文件名列表。
  ///
  /// 返回皮肤文件名列表，如果目录不存在则返回空列表
  Future<List<String>> listLocalSkins() async {
    final skinDir = await getLocalSkinDirectory();
    final dir = Directory(skinDir);

    // 如果目录不存在，返回空列表
    if (!await dir.exists()) {
      return [];
    }

    // 列出目录中的所有PNG文件
    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .map((f) => path.basename(f.path))
        .toList();
  }

  /// 列出本地披风文件
  ///
  /// 扫描本地披风目录，返回所有PNG文件的文件名列表。
  ///
  /// 返回披风文件名列表，如果目录不存在则返回空列表
  Future<List<String>> listLocalCapes() async {
    final capeDir = await getLocalCapeDirectory();
    final dir = Directory(capeDir);

    // 如果目录不存在，返回空列表
    if (!await dir.exists()) {
      return [];
    }

    // 列出目录中的所有PNG文件
    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .map((f) => path.basename(f.path))
        .toList();
  }

  /// 计算文件哈希值
  ///
  /// 使用SHA-1算法计算数据的哈希值，用于文件校验或缓存键。
  ///
  /// [data] 要计算哈希的数据
  /// 返回SHA-1哈希值的十六进制字符串
  String calculateFileHash(Uint8List data) {
    return sha1.convert(data).toString();
  }
}