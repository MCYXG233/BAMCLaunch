import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';

/// 游戏会话记录
class GameSession {
  /// 会话唯一ID
  final String id;

  /// 实例名称
  final String instanceName;

  /// 实例ID
  final String instanceId;

  /// 游戏版本
  final String gameVersion;

  /// 启动时间
  final DateTime startTime;

  /// 结束时间
  final DateTime? endTime;

  /// 游戏时长（秒）
  int get playTimeSeconds =>
      endTime?.difference(startTime).inSeconds ??
      DateTime.now().difference(startTime).inSeconds;

  /// 服务器地址（如果有的话）
  final String? serverAddress;

  /// 服务器端口
  final int? serverPort;

  /// 账户ID
  final String? accountId;

  /// 用户名
  final String? username;

  /// 是否成功启动
  final bool launchedSuccessfully;

  /// 退出代码
  final int? exitCode;

  GameSession({
    required this.id,
    required this.instanceName,
    required this.instanceId,
    required this.gameVersion,
    required this.startTime,
    this.endTime,
    this.serverAddress,
    this.serverPort,
    this.accountId,
    this.username,
    this.launchedSuccessfully = true,
    this.exitCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceName': instanceName,
      'instanceId': instanceId,
      'gameVersion': gameVersion,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'serverAddress': serverAddress,
      'serverPort': serverPort,
      'accountId': accountId,
      'username': username,
      'launchedSuccessfully': launchedSuccessfully,
      'exitCode': exitCode,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String? ?? '',
      instanceName: json['instanceName'] as String? ?? '',
      instanceId: json['instanceId'] as String? ?? '',
      gameVersion: json['gameVersion'] as String? ?? '',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      serverAddress: json['serverAddress'] as String?,
      serverPort: json['serverPort'] as int?,
      accountId: json['accountId'] as String?,
      username: json['username'] as String?,
      launchedSuccessfully: json['launchedSuccessfully'] as bool? ?? true,
      exitCode: json['exitCode'] as int?,
    );
  }

  GameSession copyWith({
    String? id,
    String? instanceName,
    String? instanceId,
    String? gameVersion,
    DateTime? startTime,
    DateTime? endTime,
    String? serverAddress,
    int? serverPort,
    String? accountId,
    String? username,
    bool? launchedSuccessfully,
    int? exitCode,
  }) {
    return GameSession(
      id: id ?? this.id,
      instanceName: instanceName ?? this.instanceName,
      instanceId: instanceId ?? this.instanceId,
      gameVersion: gameVersion ?? this.gameVersion,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
      accountId: accountId ?? this.accountId,
      username: username ?? this.username,
      launchedSuccessfully: launchedSuccessfully ?? this.launchedSuccessfully,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}

/// 服务器记录
class ServerRecord {
  /// 服务器地址
  final String address;

  /// 服务器端口
  final int port;

  /// 服务器名称（用户备注）
  final String? name;

  /// 连接次数
  int connectionCount;

  /// 最后连接时间
  DateTime lastConnected;

  /// 总游戏时长（秒）
  int totalPlayTimeSeconds;

  ServerRecord({
    required this.address,
    this.port = 25565,
    this.name,
    this.connectionCount = 0,
    required this.lastConnected,
    this.totalPlayTimeSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'port': port,
      'name': name,
      'connectionCount': connectionCount,
      'lastConnected': lastConnected.toIso8601String(),
      'totalPlayTimeSeconds': totalPlayTimeSeconds,
    };
  }

  factory ServerRecord.fromJson(Map<String, dynamic> json) {
    return ServerRecord(
      address: json['address'] as String? ?? '',
      port: json['port'] as int? ?? 25565,
      name: json['name'] as String?,
      connectionCount: json['connectionCount'] as int? ?? 0,
      lastConnected: json['lastConnected'] != null
          ? DateTime.tryParse(json['lastConnected'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
    );
  }
}

/// 实例统计
class InstanceStatistics {
  /// 实例ID
  final String instanceId;

  /// 实例名称
  final String instanceName;

  /// 启动次数
  int launchCount;

  /// 总游戏时长（秒）
  int totalPlayTimeSeconds;

  /// 最后启动时间
  DateTime? lastLaunchTime;

  /// 最后游戏时长
  int lastPlayTimeSeconds;

  /// 平均游戏时长（秒）
  double get averagePlayTimeSeconds {
    return launchCount > 0 ? totalPlayTimeSeconds / launchCount : 0;
  }

  InstanceStatistics({
    required this.instanceId,
    required this.instanceName,
    this.launchCount = 0,
    this.totalPlayTimeSeconds = 0,
    this.lastLaunchTime,
    this.lastPlayTimeSeconds = 0,
  });
}

/// 游戏统计管理器
class GameStatisticsManager {
  static GameStatisticsManager? _instance;

  final Logger _logger = Logger('GameStatisticsManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 数据文件
  File? _dataFile;

  /// 所有会话记录
  final List<GameSession> _sessions = [];

  /// 服务器记录
  final Map<String, ServerRecord> _servers = {};

  /// 实例统计缓存
  final Map<String, InstanceStatistics> _instanceStats = {};

  /// 当前进行中的会话
  GameSession? _activeSession;

  /// 是否已经初始化
  bool _initialized = false;

  GameStatisticsManager._internal();

  /// 获取单例实例
  static GameStatisticsManager get instance {
    return ServiceLocator.instance.tryGet<GameStatisticsManager>() ??
        (_instance ??= GameStatisticsManager._internal());
  }

  /// 工厂构造函数
  factory GameStatisticsManager() => instance;

  /// 初始化统计管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      final dataPath = path.join(supportDir, 'statistics');
      final dataDir = Directory(dataPath);

      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      _dataFile = File(path.join(dataPath, 'sessions.json'));

      if (await _dataFile!.exists()) {
        await _loadData();
      }

      _logger.info('Game statistics manager initialized, ${_sessions.length} sessions loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize statistics manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载数据
  Future<void> _loadData() async {
    if (_dataFile == null) return;

    try {
      final content = await _dataFile!.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        _logger.warn('Statistics file format invalid, starting fresh');
        return;
      }
      final data = decoded;

      // 加载会话
      final sessionsData = data['sessions'] as List?;
      if (sessionsData != null) {
        _sessions.clear();
        for (final item in sessionsData) {
          try {
            if (item is Map<String, dynamic>) {
              _sessions.add(GameSession.fromJson(item));
            }
          } catch (e) {
            _logger.warn('Skipping invalid session entry: $e');
          }
        }
      }

      // 加载服务器记录
      final serversData = data['servers'] as Map?;
      if (serversData != null) {
        _servers.clear();
        serversData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            try {
              _servers[key.toString()] = ServerRecord.fromJson(value);
            } catch (e) {
              _logger.warn('Skipping invalid server entry: $e');
            }
          }
        });
      }

      // 重建实例统计缓存
      _rebuildInstanceStats();
    } catch (e, stackTrace) {
      _logger.error('Failed to load statistics data', e, stackTrace);
    }
  }

  /// 保存数据
  Future<void> _saveData() async {
    if (_dataFile == null) return;

    try {
      final data = {
        'sessions': _sessions.map((e) => e.toJson()).toList(),
        'servers': _servers.map((key, value) => MapEntry(key, value.toJson())),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // 原子写入：先写入临时文件，再重命名
      final tempFile = File('${_dataFile!.path}.tmp');
      await tempFile.writeAsString(jsonEncode(data));
      if (await _dataFile!.exists()) {
        await _dataFile!.delete();
      }
      await tempFile.rename(_dataFile!.path);
    } catch (e, stackTrace) {
      _logger.error('Failed to save statistics data', e, stackTrace);
    }
  }

  /// 重建实例统计缓存
  void _rebuildInstanceStats() {
    _instanceStats.clear();

    for (final session in _sessions) {
      final stats = _instanceStats.putIfAbsent(
        session.instanceId,
        () => InstanceStatistics(
          instanceId: session.instanceId,
          instanceName: session.instanceName,
        ),
      );

      stats.launchCount++;
      stats.totalPlayTimeSeconds += session.playTimeSeconds;
      stats.lastPlayTimeSeconds = session.playTimeSeconds;

      if (stats.lastLaunchTime == null ||
          session.startTime.isAfter(stats.lastLaunchTime!)) {
        stats.lastLaunchTime = session.startTime;
      }
    }
  }

  /// 开始新的游戏会话
  GameSession startSession({
    required String instanceName,
    required String instanceId,
    required String gameVersion,
    String? serverAddress,
    int? serverPort,
    String? accountId,
    String? username,
  }) {
    final session = GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      instanceName: instanceName,
      instanceId: instanceId,
      gameVersion: gameVersion,
      startTime: DateTime.now(),
      serverAddress: serverAddress,
      serverPort: serverPort,
      accountId: accountId,
      username: username,
    );

    _activeSession = session;
    _sessions.add(session);

    _logger.info('Started new session: ${session.id} for $instanceName');
    // fire-and-forget 保存，不阻塞调用方
    _saveData().catchError((e) {
      _logger.error('Failed to save session start data', e);
    });

    return session;
  }

  /// 结束当前会话
  Future<GameSession?> endSession({int? exitCode}) async {
    if (_activeSession == null) return null;

    final updatedSession = _activeSession!.copyWith(
      endTime: DateTime.now(),
      exitCode: exitCode,
    );

    // 更新会话列表
    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index >= 0) {
      _sessions[index] = updatedSession;
    }

    // 更新服务器记录
    if (updatedSession.serverAddress != null) {
      final serverKey =
          '${updatedSession.serverAddress}:${updatedSession.serverPort ?? 25565}';

      final server = _servers.putIfAbsent(
        serverKey,
        () => ServerRecord(
          address: updatedSession.serverAddress!,
          port: updatedSession.serverPort ?? 25565,
          lastConnected: updatedSession.startTime,
        ),
      );

      server.connectionCount++;
      server.lastConnected = updatedSession.endTime!;
      server.totalPlayTimeSeconds += updatedSession.playTimeSeconds;
    }

    // 更新实例统计（不手动累加 launchCount/totalPlayTimeSeconds，
    // 完全依赖 _rebuildInstanceStats() 从 sessions 重建，避免双重计数）
    final stats = _instanceStats.putIfAbsent(
      updatedSession.instanceId,
      () => InstanceStatistics(
        instanceId: updatedSession.instanceId,
        instanceName: updatedSession.instanceName,
      ),
    );

    stats.lastLaunchTime = updatedSession.startTime;
    stats.lastPlayTimeSeconds = updatedSession.playTimeSeconds;

    _activeSession = null;
    _logger.info('Ended session: ${updatedSession.id}, played ${updatedSession.playTimeSeconds}s');

    await _saveData();
    return updatedSession;
  }

  /// 获取所有会话记录
  List<GameSession> getAllSessions({int limit = 100}) {
    final sorted = List<GameSession>.from(_sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(limit).toList();
  }

  /// 获取特定实例的会话
  List<GameSession> getSessionsForInstance(String instanceId, {int limit = 100}) {
    final filtered = _sessions
        .where((s) => s.instanceId == instanceId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered.take(limit).toList();
  }

  /// 获取服务器记录
  List<ServerRecord> getServers({int limit = 50}) {
    final servers = _servers.values.toList()
      ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
    return servers.take(limit).toList();
  }

  /// 获取实例统计
  InstanceStatistics? getInstanceStatistics(String instanceId) {
    return _instanceStats[instanceId];
  }

  /// 获取所有实例统计
  List<InstanceStatistics> getAllInstanceStatistics() {
    return _instanceStats.values.toList()
      ..sort((a, b) {
        if (a.lastLaunchTime == null) return 1;
        if (b.lastLaunchTime == null) return -1;
        return b.lastLaunchTime!.compareTo(a.lastLaunchTime!);
      });
  }

  /// 获取总游戏时长
  Duration getTotalPlayTime() {
    int total = 0;
    for (final session in _sessions) {
      total += session.playTimeSeconds;
    }
    return Duration(seconds: total);
  }

  /// 获取总启动次数
  int getTotalLaunchCount() => _sessions.length;

  /// 获取今日游戏时长
  Duration getTodayPlayTime() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int total = 0;
    for (final session in _sessions) {
      if (session.startTime.isAfter(todayStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取本周游戏时长
  Duration getWeekPlayTime() {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    int total = 0;
    for (final session in _sessions) {
      if (session.startTime.isAfter(weekStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取最常玩的实例
  InstanceStatistics? getMostPlayedInstance() {
    if (_instanceStats.isEmpty) return null;

    final sorted = _instanceStats.values.toList()
      ..sort((a, b) => b.totalPlayTimeSeconds.compareTo(a.totalPlayTimeSeconds));
    return sorted.first;
  }

  /// 获取最常连接的服务器
  ServerRecord? getMostConnectedServer() {
    if (_servers.isEmpty) return null;

    final sorted = _servers.values.toList()
      ..sort((a, b) => b.connectionCount.compareTo(a.connectionCount));
    return sorted.first;
  }

  /// 删除旧的会话记录
  Future<void> cleanOldSessions({Duration keepDuration = const Duration(days: 90)}) async {
    final cutoff = DateTime.now().subtract(keepDuration);
    final beforeCount = _sessions.length;

    _sessions.removeWhere((s) => s.startTime.isBefore(cutoff));

    if (_sessions.length < beforeCount) {
      _logger.info('Cleaned ${beforeCount - _sessions.length} old sessions');
      _rebuildInstanceStats();
      await _saveData();
    }
  }

  /// 清除所有统计数据
  Future<void> clearAllData() async {
    _sessions.clear();
    _servers.clear();
    _instanceStats.clear();
    _activeSession = null;

    await _saveData();
    _logger.info('Cleared all statistics data');
  }

  /// 获取当前活跃的会话
  GameSession? get activeSession => _activeSession;

  /// 是否有活跃的会话
  bool get hasActiveSession => _activeSession != null;
}
