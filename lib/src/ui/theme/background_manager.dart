import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../config/background_config.dart';

/// 背景管理器
///
/// 该类负责管理应用程序的背景设置，支持多种背景类型：
/// - 纯色背景（solid）
/// - 渐变背景（gradient）
/// - 图片背景（image）
/// - 视频背景（video）
/// - 模糊背景（blur）
///
/// 使用单例模式确保全局只有一个实例，并通过 [ChangeNotifier]
/// 实现响应式更新，当背景配置发生变化时通知监听者。
///
/// 使用示例：
/// ```dart
/// final backgroundManager = BackgroundManager.instance;
/// await backgroundManager.initialize();
/// ```
class BackgroundManager extends ChangeNotifier {
  /// 单例实例
  static BackgroundManager? _instance;

  /// 配置管理器，用于读写持久化配置
  final ConfigManager _configManager = ConfigManager();

  /// 当前背景配置
  BackgroundConfig _currentConfig = BackgroundConfig.classic;

  /// 视频播放控制器，仅在视频背景类型时使用
  VideoPlayerController? _videoController;

  /// 视频是否已初始化完成的标志
  bool _isVideoInitialized = false;

  /// 私有构造函数，确保只能通过 [instance] 获取实例
  BackgroundManager._internal();

  /// 获取单例实例
  ///
  /// 如果实例不存在，则创建一个新实例。
  /// 使用懒加载模式，仅在首次访问时创建。
  static BackgroundManager get instance {
    _instance ??= BackgroundManager._internal();
    return _instance!;
  }

  /// 工厂构造函数，返回单例实例
  factory BackgroundManager() => instance;

  /// 获取当前背景配置
  ///
  /// 返回当前应用的背景配置对象，包含背景类型、颜色、路径等信息。
  BackgroundConfig get currentConfig => _currentConfig;

  /// 初始化背景管理器
  ///
  /// 该方法应在应用启动时调用，用于加载持久化的背景配置。
  /// 会自动从配置文件中读取并应用之前保存的背景设置。
  ///
  /// 示例：
  /// ```dart
  /// await BackgroundManager.instance.initialize();
  /// ```
  Future<void> initialize() async {
    await loadBackgroundConfig();
  }

  /// 从持久化存储加载背景配置
  ///
  /// 从配置管理器中读取背景配置的 JSON 字符串，
  /// 解析为 [BackgroundConfig] 对象并应用。
  ///
  /// 如果配置不存在或解析失败，将使用默认的经典背景配置。
  /// 加载完成后会通知所有监听者更新。
  Future<void> loadBackgroundConfig() async {
    try {
      // 从配置存储中获取背景配置的 JSON 字符串
      final jsonStr = _configManager.getString(ConfigKeys.backgroundChoice);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        // 解析 JSON 并创建配置对象
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _currentConfig = BackgroundConfig.fromJson(json);
        // 如果是视频背景，需要初始化视频播放器
        await _initializeVideoIfNeeded();
      }
    } catch (e) {
      // 解析失败时使用默认配置
      _currentConfig = BackgroundConfig.classic;
    }
    // 通知监听者配置已更新
    notifyListeners();
  }

  /// 保存背景配置到持久化存储
  ///
  /// 将传入的 [config] 配置对象序列化为 JSON 并保存到配置存储中。
  /// 同时更新内存中的当前配置，并根据需要初始化视频播放器。
  ///
  /// 参数：
  /// - [config] 要保存的背景配置对象
  ///
  /// 注意：
  /// - 如果背景类型发生变化，或之前是视频背景，会重新初始化视频播放器
  /// - 保存成功后会通知所有监听者更新
  Future<void> saveBackgroundConfig(BackgroundConfig config) async {
    try {
      // 将配置对象序列化为 JSON 字符串
      final jsonStr = jsonEncode(config.toJson());
      // 保存到持久化存储
      await _configManager.setString(ConfigKeys.backgroundChoice, jsonStr);

      // 记录旧的背景类型，用于判断是否需要重新初始化视频
      final oldType = _currentConfig.type;
      _currentConfig = config;

      // 如果背景类型改变，或之前是视频背景，需要重新初始化视频播放器
      if (oldType != config.type || oldType == BackgroundType.video) {
        await _initializeVideoIfNeeded();
      }

      // 通知监听者配置已更新
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save background config: $e');
    }
  }

  /// 根据需要初始化视频播放器
  ///
  /// 该方法会在以下情况下初始化视频播放器：
  /// 1. 当前背景类型为视频（[BackgroundType.video]）
  /// 2. 视频路径已配置且有效
  ///
  /// 初始化过程包括：
  /// - 释放之前的视频控制器（如果存在）
  /// - 创建新的视频控制器并加载视频文件
  /// - 设置循环播放和静音
  /// - 开始播放视频
  ///
  /// 如果视频加载失败，会将视频控制器置空并标记为未初始化。
  Future<void> _initializeVideoIfNeeded() async {
    // 先释放之前的视频控制器
    await _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    // 仅在视频背景类型且有视频路径时初始化
    if (_currentConfig.type == BackgroundType.video && _currentConfig.videoPath != null) {
      try {
        // 从文件创建视频控制器
        _videoController = VideoPlayerController.file(File(_currentConfig.videoPath!));
        // 初始化视频播放器
        await _videoController!.initialize();
        // 设置循环播放
        await _videoController!.setLooping(true);
        // 设置静音（背景视频通常不需要声音）
        await _videoController!.setVolume(0);
        // 标记初始化完成
        _isVideoInitialized = true;
        // 开始播放
        _videoController!.play();
      } catch (e) {
        debugPrint('Failed to load video: $e');
        // 加载失败时清理状态
        _videoController = null;
        _isVideoInitialized = false;
      }
    }
  }

  /// 构建背景 Widget
  ///
  /// 创建一个包含背景层和子组件的堆叠布局。
  /// 背景层会根据当前配置显示相应的背景效果，
  /// 子组件显示在背景层之上。
  ///
  /// 参数：
  /// - [child] 要显示在背景之上的子组件
  ///
  /// 返回：
  /// - 包含背景和子组件的 [Stack] Widget
  ///
  /// 示例：
  /// ```dart
  /// BackgroundManager.instance.buildBackground(
  ///   child: YourContentWidget(),
  /// );
  /// ```
  Widget buildBackground({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景层
        _buildBackgroundLayer(),
        // 内容层（显示在背景之上）
        child,
      ],
    );
  }

  /// 构建背景层 Widget
  ///
  /// 根据当前背景配置的类型，构建相应的背景 Widget。
  /// 支持以下背景类型：
  ///
  /// - [BackgroundType.solid]: 纯色背景，使用配置的颜色和透明度
  /// - [BackgroundType.gradient]: 渐变背景，使用配置的颜色列表和起始位置
  /// - [BackgroundType.image]: 图片背景，从文件加载图片并覆盖整个区域
  /// - [BackgroundType.video]: 视频背景，播放视频文件作为背景
  /// - [BackgroundType.blur]: 模糊背景，使用半透明白色覆盖
  ///
  /// 返回：
  /// - 对应类型的背景 Widget
  Widget _buildBackgroundLayer() {
    switch (_currentConfig.type) {
      case BackgroundType.solid:
        // 纯色背景：使用配置的颜色，如果未配置则使用白色
        return Container(
          decoration: BoxDecoration(
            color: _currentConfig.solidColor != null
                ? Color(_currentConfig.solidColor!).withOpacity(_currentConfig.opacity)
                : Colors.white.withOpacity(_currentConfig.opacity),
          ),
        );

      case BackgroundType.gradient:
        // 渐变背景：使用配置的颜色列表创建线性渐变
        // 如果未配置颜色，则使用默认的白色到浅灰色渐变
        final colors = _currentConfig.gradientColors
                ?.map((c) => Color(c).withOpacity(_currentConfig.opacity))
                .toList() ??
            [Colors.white, Colors.grey.shade200];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              // 渐变起始位置，根据配置的 alignment 值确定
              begin: _getAlignment(_currentConfig.alignment),
              end: Alignment.bottomRight,
            ),
          ),
        );

      case BackgroundType.image:
        // 图片背景：从文件加载图片，覆盖整个区域
        return Container(
          decoration: BoxDecoration(
            image: _currentConfig.imagePath != null
                ? DecorationImage(
                    image: FileImage(File(_currentConfig.imagePath!)),
                    fit: BoxFit.cover,
                    opacity: _currentConfig.opacity,
                  )
                : null,
          ),
        );

      case BackgroundType.video:
        // 视频背景：如果视频已初始化，则显示视频播放器
        // 使用 FittedBox 确保视频覆盖整个区域
        if (_isVideoInitialized && _videoController != null) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                // 使用视频的原始尺寸
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: Opacity(
                  // 应用配置的透明度
                  opacity: _currentConfig.opacity,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          );
        }
        // 视频未初始化时显示黑色背景
        return Container(color: Colors.black);

      case BackgroundType.blur:
        // 模糊背景：使用半透明白色覆盖
        // opacity 乘以 0.5 使效果更加柔和
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_currentConfig.opacity * 0.5),
          ),
        );
    }
  }

  /// 将整数对齐值转换为 [Alignment] 对象
  ///
  /// 用于渐变背景的起始位置配置。
  /// 对齐值与位置的对应关系：
  /// - 0: 左上 (topLeft)
  /// - 1: 上中 (topCenter)
  /// - 2: 右上 (topRight)
  /// - 3: 左中 (centerLeft)
  /// - 4: 居中 (center)
  /// - 5: 右中 (centerRight)
  /// - 6: 左下 (bottomLeft)
  /// - 7: 下中 (bottomCenter)
  /// - 8: 右下 (bottomRight)
  /// - 其他: 默认左上 (topLeft)
  ///
  /// 参数：
  /// - [alignment] 整数对齐值（0-8）
  ///
  /// 返回：
  /// - 对应的 [Alignment] 对象
  Alignment _getAlignment(int? alignment) {
    switch (alignment) {
      case 0:
        return Alignment.topLeft;
      case 1:
        return Alignment.topCenter;
      case 2:
        return Alignment.topRight;
      case 3:
        return Alignment.centerLeft;
      case 4:
        return Alignment.center;
      case 5:
        return Alignment.centerRight;
      case 6:
        return Alignment.bottomLeft;
      case 7:
        return Alignment.bottomCenter;
      case 8:
        return Alignment.bottomRight;
      default:
        return Alignment.topLeft;
    }
  }

  /// 释放资源
  ///
  /// 当背景管理器不再使用时，释放视频控制器等资源。
  /// 调用此方法后，不应再使用该实例。
  @override
  void dispose() {
    // 释放视频控制器资源
    _videoController?.dispose();
    super.dispose();
  }
}