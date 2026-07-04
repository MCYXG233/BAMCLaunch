import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../game/game_statistics.dart';

/// 实例时长排行榜条目
///
/// 该类用于存储单个游戏实例的游玩时长统计数据，包括：
/// - 实例ID和名称
/// - 累计游玩时长（秒）
/// - 启动次数
/// - 最后游玩时间
///
/// 该类支持JSON序列化和反序列化，用于数据持久化存储。
class PlayTimeEntry {
  /// 实例唯一标识符
  final String instanceId;

  /// 实例显示名称
  final String instanceName;

  /// 累计游玩时长（秒）
  final int playTimeSeconds;

  /// 游戏启动次数
  final int launchCount;

  /// 最后一次游玩的时间，可能为空（表示从未游玩过）
  final DateTime? lastPlayed;

  /// 创建一个新的游玩时长条目
  ///
  /// [instanceId] 实例唯一标识符，不能为空
  /// [instanceName] 实例显示名称，不能为空
  /// [playTimeSeconds] 累计游玩时长（秒）
  /// [launchCount] 游戏启动次数
  /// [lastPlayed] 最后一次游玩的时间，可选
  PlayTimeEntry({
    required this.instanceId,
    required this.instanceName,
    required this.playTimeSeconds,
    required this.launchCount,
    this.lastPlayed,
  });

  /// 将当前条目转换为JSON格式的Map
  ///
  /// 返回包含所有字段的Map，用于数据持久化存储。
  /// [lastPlayed] 字段会被转换为ISO8601格式的字符串。
  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'instanceName': instanceName,
      'playTimeSeconds': playTimeSeconds,
      'launchCount': launchCount,
      'lastPlayed': lastPlayed?.toIso8601String(),
    };
  }

  /// 从JSON格式的Map创建游玩时长条目实例
  ///
  /// [json] 包含条目数据的Map，必须包含以下字段：
  /// - instanceId: 实例ID（字符串）
  /// - instanceName: 实例名称（字符串）
  /// - playTimeSeconds: 游玩时长（整数）
  /// - launchCount: 启动次数（整数）
  /// - lastPlayed: 最后游玩时间（ISO8601格式字符串，可选）
  ///
  /// 返回新创建的 [PlayTimeEntry] 实例。
  factory PlayTimeEntry.fromJson(Map<String, dynamic> json) {
    return PlayTimeEntry(
      instanceId: json['instanceId'] as String,
      instanceName: json['instanceName'] as String,
      playTimeSeconds: json['playTimeSeconds'] as int,
      launchCount: json['launchCount'] as int,
      // 解析ISO8601格式的日期时间字符串
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.tryParse(json['lastPlayed'] as String)
          : null,
    );
  }
}

/// 精确计时器状态枚举
///
/// 定义了游戏时长追踪器的三种运行状态：
/// - [idle]: 空闲状态，未在进行任何计时
/// - [running]: 运行状态，正在计时中
/// - [paused]: 暂停状态，计时已暂停但未结束
enum PlayTimeTrackerState {
  /// 空闲状态：未在进行任何计时
  idle,

  /// 运行状态：正在计时中
  running,

  /// 暂停状态：计时已暂停但未结束
  paused,
}

/// 游戏时长追踪器
///
/// 提供精确计时功能，支持在实例维度累计游戏时长。
/// 该类采用单例模式，确保整个应用程序中只有一个计时器实例。
///
/// 主要功能：
/// - 开始/暂停/恢复/停止计时
/// - 按实例维度累计游玩时长
/// - 记录启动次数和最后游玩时间
/// - 支持数据持久化存储
/// - 提供时长排行榜功能
/// - 提供今日/本周/本月时长统计
///
/// 使用示例：
/// ```dart
/// final tracker = PlayTimeTracker.instance;
/// await tracker.initialize();
/// await tracker.startTracking('instance-1', '我的世界');
/// // 游戏运行中...
/// await tracker.stopTracking(exitCode: 0);
/// ```
class PlayTimeTracker {
  /// 单例实例
  static PlayTimeTracker? _instance;

  /// 日志记录器，用于记录追踪器的操作日志
  final Logger _logger = Logger('PlayTimeTracker');

  /// 平台适配器，用于获取应用数据存储目录
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 游戏统计管理器，用于同步会话数据
  final GameStatisticsManager _statisticsManager = GameStatisticsManager.instance;

  /// 数据文件，用于持久化存储时长数据
  File? _dataFile;

  /// 实例时长累计数据映射表
  ///
  /// 键为实例ID，值为对应的游玩时长条目。
  /// 存储所有实例的累计时长统计数据。
  final Map<String, PlayTimeEntry> _instancePlayTimes = {};

  /// 当前正在计时的实例ID
  ///
  /// 当计时器处于运行或暂停状态时，此字段记录当前计时的实例。
  /// 当计时器处于空闲状态时，此字段为null。
  String? _currentTrackingInstanceId;

  /// 当前会话开始时间
  ///
  /// 记录当前计时会话的开始时间，用于计算会话时长。
  /// 当计时器处于空闲状态时，此字段为null。
  DateTime? _sessionStartTime;

  /// 当前已累计的时长（秒）
  ///
  /// 用于暂停/恢复场景：当计时器暂停时，保存已累计的时长，
  /// 恢复时在此基础上继续计时。
  int _accumulatedSeconds = 0;

  /// 计时器当前状态
  PlayTimeTrackerState _state = PlayTimeTrackerState.idle;

  /// 定时器，用于周期性更新（每秒触发一次）
  Timer? _timer;

  /// 是否已初始化标志
  ///
  /// 确保初始化操作只执行一次，避免重复初始化。
  bool _initialized = false;

  /// 私有构造函数，防止外部实例化
  PlayTimeTracker._internal();

  /// 获取单例实例
  ///
  /// 如果实例尚未创建，会自动创建一个新实例。
  /// 返回 [PlayTimeTracker] 的唯一实例。
  static PlayTimeTracker get instance {
    return ServiceLocator.instance.tryGet<PlayTimeTracker>() ??
        (_instance ??= PlayTimeTracker._internal());
  }

  /// 工厂构造函数
  ///
  /// 返回单例实例，等同于 [instance] getter。
  factory PlayTimeTracker() => instance;

  /// 初始化追踪器
  ///
  /// 执行以下初始化操作：
  /// 1. 获取应用数据存储目录
  /// 2. 创建统计数据目录（如果不存在）
  /// 3. 加载已有的时长数据（如果存在）
  ///
  /// 该方法是幂等的，多次调用只会执行一次初始化。
  /// 初始化失败时会记录错误日志，但不会抛出异常。
  Future<void> initialize() async {
    // 如果已经初始化，直接返回
    if (_initialized) return;

    try {
      // 获取应用支持目录（用于存储应用数据）
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();

      // 构建统计数据目录路径
      final dataPath = path.join(supportDir, 'statistics');
      final dataDir = Directory(dataPath);

      // 如果目录不存在，创建目录（包括所有父目录）
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      // 设置数据文件路径
      _dataFile = File(path.join(dataPath, 'play_time_tracker.json'));

      // 如果数据文件已存在，加载数据
      if (await _dataFile!.exists()) {
        await _loadData();
      }

      _logger.info('Play time tracker initialized, ${_instancePlayTimes.length} entries loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      // 初始化失败时记录错误，但标记为已初始化以避免重复尝试
      _logger.error('Failed to initialize play time tracker', e, stackTrace);
      _initialized = true;
    }
  }

  /// 从数据文件加载时长数据
  ///
  /// 读取JSON格式的数据文件，解析并填充 [_instancePlayTimes] 映射表。
  /// 如果数据文件不存在或解析失败，会记录错误日志但不抛出异常。
  Future<void> _loadData() async {
    if (_dataFile == null) return;

    try {
      // 读取文件内容
      final content = await _dataFile!.readAsString();

      // 解析JSON数据
      final data = jsonDecode(content) as Map<String, dynamic>;

      // 获取条目数据
      final entries = data['entries'] as Map<String, dynamic>?;
      if (entries != null) {
        // 清空现有数据
        _instancePlayTimes.clear();

        // 遍历并解析每个条目
        entries.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _instancePlayTimes[key] = PlayTimeEntry.fromJson(value);
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load play time data', e, stackTrace);
    }
  }

  /// 保存时长数据到文件（原子写入）
  ///
  /// 将 [_instancePlayTimes] 映射表序列化为JSON格式并写入数据文件。
  /// 使用临时文件+重命名的方式实现原子写入，防止写入中断导致数据损坏。
  /// 保存失败时会记录错误日志但不抛出异常。
  Future<void> _saveData() async {
    if (_dataFile == null) return;

    try {
      // 构建要保存的数据结构
      final data = {
        'entries': _instancePlayTimes.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(data);
      final tempFile = File('${_dataFile!.path}.tmp');

      if (await tempFile.exists()) await tempFile.delete();
      await tempFile.writeAsString(jsonString);
      if (await _dataFile!.exists()) await _dataFile!.delete();
      await tempFile.rename(_dataFile!.path);
    } catch (e, stackTrace) {
      _logger.error('Failed to save play time data', e, stackTrace);
    }
  }

  /// 开始计时
  ///
  /// 在游戏就绪后调用此方法开始计时。
  /// 如果计时器已经在运行中，会记录警告日志并直接返回。
  ///
  /// [instanceId] 要计时的实例唯一标识符
  /// [instanceName] 实例的显示名称
  ///
  /// 计时开始后，计时器状态变为 [PlayTimeTrackerState.running]。
  Future<void> startTracking(String instanceId, String instanceName) async {
    // 如果已经在计时中，拒绝重复开始
    if (_state == PlayTimeTrackerState.running) {
      _logger.warning('Already tracking instance: $_currentTrackingInstanceId');
      return;
    }

    // 确保已初始化
    await initialize();

    // 设置当前计时的实例信息
    _currentTrackingInstanceId = instanceId;
    _sessionStartTime = DateTime.now();
    _accumulatedSeconds = 0;
    _state = PlayTimeTrackerState.running;

    // 启动定时器
    _startTimer();

    _logger.info('Started tracking play time for instance: $instanceName ($instanceId)');
  }

  /// 暂停计时
  ///
  /// 暂停当前正在进行的计时。
  /// 只有在计时器处于运行状态时才能暂停。
  /// 暂停后，计时器状态变为 [PlayTimeTrackerState.paused]。
  /// 已累计的时长会被保存，以便后续恢复时继续计时。
  void pauseTracking() {
    // 只有运行状态才能暂停
    if (_state != PlayTimeTrackerState.running) return;

    // 停止定时器
    _stopTimer();

    // 更新状态为暂停
    _state = PlayTimeTrackerState.paused;

    _logger.info('Paused tracking for instance: $_currentTrackingInstanceId');
  }

  /// 恢复计时
  ///
  /// 恢复之前暂停的计时。
  /// 只有在计时器处于暂停状态时才能恢复。
  /// 恢复后，计时器状态变为 [PlayTimeTrackerState.running]。
  void resumeTracking() {
    // 只有暂停状态才能恢复
    if (_state != PlayTimeTrackerState.paused) return;

    // 更新状态为运行
    _state = PlayTimeTrackerState.running;

    // 重新启动定时器
    _startTimer();

    _logger.info('Resumed tracking for instance: $_currentTrackingInstanceId');
  }

  /// 停止计时并保存
  ///
  /// 结束当前计时会话，计算本次会话时长并更新实例累计数据。
  /// 同时会将数据同步到 [GameStatisticsManager]。
  ///
  /// [exitCode] 游戏退出代码，可选参数，用于记录游戏退出状态
  ///
  /// 停止后，计时器状态重置为 [PlayTimeTrackerState.idle]，
  /// 所有会话相关的临时数据会被清空。
  Future<void> stopTracking({int? exitCode}) async {
    // 如果已经是空闲状态，无需停止
    if (_state == PlayTimeTrackerState.idle) return;

    // 停止定时器
    _stopTimer();

    // 如果有正在计时的实例，计算并保存时长
    if (_currentTrackingInstanceId != null && _sessionStartTime != null) {
      // 计算本次会话时长
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;

      // 计算总时长（包括暂停前已累计的时长）
      final totalDuration = _accumulatedSeconds + sessionDuration;

      // 更新实例累计时长
      await _updateInstancePlayTime(_currentTrackingInstanceId!, totalDuration);

      // 同时通知GameStatisticsManager，保持数据同步
      final entry = _instancePlayTimes[_currentTrackingInstanceId];
      if (entry != null) {
        _statisticsManager.startSession(
          instanceName: entry.instanceName,
          instanceId: _currentTrackingInstanceId!,
          gameVersion: '',
        );
        await _statisticsManager.endSession(exitCode: exitCode);
      }
    }

    // 重置所有会话相关状态
    _currentTrackingInstanceId = null;
    _sessionStartTime = null;
    _accumulatedSeconds = 0;
    _state = PlayTimeTrackerState.idle;

    _logger.info('Stopped tracking');
  }

  /// 更新实例累计时长
  ///
  /// 更新指定实例的累计游玩时长、启动次数和最后游玩时间。
  /// 如果实例已存在，则累加时长和启动次数；
  /// 如果实例不存在，则创建新的条目。
  ///
  /// [instanceId] 实例唯一标识符
  /// [additionalSeconds] 本次会话新增的时长（秒）
  Future<void> _updateInstancePlayTime(String instanceId, int additionalSeconds) async {
    final existing = _instancePlayTimes[instanceId];

    if (existing != null) {
      // 实例已存在，更新累计数据
      _instancePlayTimes[instanceId] = PlayTimeEntry(
        instanceId: instanceId,
        instanceName: existing.instanceName,
        playTimeSeconds: existing.playTimeSeconds + additionalSeconds,
        launchCount: existing.launchCount + 1,
        lastPlayed: DateTime.now(),
      );
    } else {
      // 实例不存在，创建新条目
      _instancePlayTimes[instanceId] = PlayTimeEntry(
        instanceId: instanceId,
        instanceName: existing?.instanceName ?? 'Unknown',
        playTimeSeconds: additionalSeconds,
        launchCount: 1,
        lastPlayed: DateTime.now(),
      );
    }

    // 保存数据到文件
    await _saveData();
  }

  /// 获取指定实例的累计时长
  ///
  /// [instanceId] 实例唯一标识符
  ///
  /// 返回该实例的游玩时长条目，如果不存在则返回null。
  PlayTimeEntry? getInstancePlayTime(String instanceId) {
    return _instancePlayTimes[instanceId];
  }

  /// 获取所有实例的累计时长列表
  ///
  /// 返回所有实例的游玩时长条目列表，无特定排序。
  List<PlayTimeEntry> getAllInstancePlayTimes() {
    return _instancePlayTimes.values.toList();
  }

  /// 获取时长排行榜（Top N）
  ///
  /// 按游玩时长降序排列，返回前N个实例的时长条目。
  ///
  /// [limit] 返回的最大条目数量，默认为10
  ///
  /// 返回排序后的时长条目列表。
  List<PlayTimeEntry> getTopPlayTimeEntries({int limit = 10}) {
    // 获取所有条目并按游玩时长降序排序
    final entries = _instancePlayTimes.values.toList()
      ..sort((a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds));

    // 返回前N个条目
    return entries.take(limit).toList();
  }

  /// 获取当前正在计时的实例ID
  ///
  /// 如果计时器处于运行或暂停状态，返回当前计时的实例ID；
  /// 如果计时器处于空闲状态，返回null。
  String? get currentTrackingInstanceId => _currentTrackingInstanceId;

  /// 获取当前计时器状态
  PlayTimeTrackerState get state => _state;

  /// 获取当前会话已累计的时长（秒）
  ///
  /// 如果计时器正在运行，返回已累计时长加上当前会话时长；
  /// 如果计时器已暂停，返回暂停时已累计的时长；
  /// 如果计时器处于空闲状态，返回0。
  int get currentSessionSeconds {
    if (_state == PlayTimeTrackerState.running && _sessionStartTime != null) {
      // 运行状态：累计时长 + 当前会话时长
      return _accumulatedSeconds + DateTime.now().difference(_sessionStartTime!).inSeconds;
    }
    // 暂停或空闲状态：返回已累计时长
    return _accumulatedSeconds;
  }

  /// 格式化时长
  ///
  /// 将秒数转换为易读的中文时长格式。
  /// 例如：3661秒 -> "1小时1分钟1秒"
  ///
  /// [seconds] 要格式化的秒数
  ///
  /// 返回格式化后的时长字符串。
  String formatDuration(int seconds) {
    // 计算小时数
    final hours = seconds ~/ 3600;
    // 计算剩余分钟数
    final minutes = (seconds % 3600) ~/ 60;
    // 计算剩余秒数
    final secs = seconds % 60;

    // 根据时长大小选择合适的格式
    if (hours > 0) {
      return '${hours}小时${minutes}分钟${secs}秒';
    } else if (minutes > 0) {
      return '${minutes}分钟${secs}秒';
    } else {
      return '${secs}秒';
    }
  }

  /// 启动定时器
  ///
  /// 创建一个每秒触发一次的定时器。
  /// 定时器可用于通知UI更新当前会话时长显示。
  void _startTimer() {
    // 取消现有定时器（如果有）
    _timer?.cancel();

    // 创建新的周期性定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 计时器运行中，每秒触发一次更新
      // 可以在这里通知UI更新
    });
  }

  /// 停止计时器
  ///
  /// 取消并清除当前定时器。
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 获取总游戏时长
  ///
  /// 计算所有实例的累计游玩时长总和。
  ///
  /// 返回总时长的 [Duration] 对象。
  Duration getTotalPlayTime() {
    int total = 0;
    // 遍历所有实例，累加时长
    for (final entry in _instancePlayTimes.values) {
      total += entry.playTimeSeconds;
    }
    return Duration(seconds: total);
  }

  /// 获取今日游戏时长
  ///
  /// 计算从今天0点开始到现在的累计游玩时长。
  /// 使用 [GameStatisticsManager] 的会话数据进行计算。
  ///
  /// 返回今日总时长的 [Duration] 对象。
  Duration getTodayPlayTime() {
    final now = DateTime.now();
    // 计算今天0点的时间
    final todayStart = DateTime(now.year, now.month, now.day);

    int total = 0;
    // 获取所有会话并筛选今日会话
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      // 只统计今天0点之后的会话
      if (session.startTime.isAfter(todayStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取本周游戏时长
  ///
  /// 计算从本周一0点开始到现在的累计游玩时长。
  /// 使用 [GameStatisticsManager] 的会话数据进行计算。
  ///
  /// 返回本周总时长的 [Duration] 对象。
  Duration getWeekPlayTime() {
    final now = DateTime.now();
    // 计算本周一0点的时间
    // weekday: 1=周一, 7=周日
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int total = 0;
    // 获取所有会话并筛选本周会话
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      // 只统计本周一0点之后的会话
      if (session.startTime.isAfter(weekStartDate)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取本月游戏时长
  ///
  /// 计算从本月1日0点开始到现在的累计游玩时长。
  /// 使用 [GameStatisticsManager] 的会话数据进行计算。
  ///
  /// 返回本月总时长的 [Duration] 对象。
  Duration getMonthPlayTime() {
    final now = DateTime.now();
    // 计算本月1日0点的时间
    final monthStart = DateTime(now.year, now.month, 1);

    int total = 0;
    // 获取所有会话并筛选本月会话
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      // 只统计本月1日0点之后的会话
      if (session.startTime.isAfter(monthStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取每日游戏时长数据（用于图表）
  ///
  /// 返回最近N天每天的游玩时长数据，适合用于绘制时长趋势图表。
  ///
  /// [days] 要获取的天数，默认为7天
  ///
  /// 返回一个Map，键为日期（当天的0点时间），值为该天的游玩时长（秒）。
  /// 即使某天没有游玩记录，也会包含在结果中，值为0。
  Map<DateTime, int> getDailyPlayTimeData({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    // 初始化最近N天的数据，默认值为0
    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[date] = 0;
    }

    // 获取会话数据并按日期累加
    final sessions = _statisticsManager.getAllSessions(limit: 1000);
    for (final session in sessions) {
      // 提取会话开始日期（只保留年月日）
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      // 如果该日期在统计范围内，累加时长
      if (result.containsKey(sessionDate)) {
        result[sessionDate] = result[sessionDate]! + session.playTimeSeconds;
      }
    }

    return result;
  }

  /// 清除所有数据
  ///
  /// 清空内存中的所有时长数据，并同步更新数据文件。
  /// 此操作不可逆，请谨慎使用。
  Future<void> clearAllData() async {
    // 清空内存数据
    _instancePlayTimes.clear();

    // 同步保存到文件
    await _saveData();

    _logger.info('Cleared all play time data');
  }

  /// 释放资源
  ///
  /// 停止定时器并释放相关资源。
  /// 在不再需要使用追踪器时调用此方法。
  void dispose() {
    _stopTimer();
  }
}