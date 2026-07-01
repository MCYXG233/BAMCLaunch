import 'dart:convert';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../core/logger.dart';

/// 隐私保护配置
class PrivacyConfig {
  /// 是否禁用聊天报告
  final bool disableChatReporting;

  /// 是否禁用遥测
  final bool disableTelemetry;

  /// 是否禁用崩溃报告
  final bool disableCrashReporting;

  /// 是否禁用分析
  final bool disableAnalytics;

  /// 是否禁用自动更新
  final bool disableAutoUpdate;

  const PrivacyConfig({
    this.disableChatReporting = true,
    this.disableTelemetry = true,
    this.disableCrashReporting = false,
    this.disableAnalytics = true,
    this.disableAutoUpdate = false,
  });

  PrivacyConfig copyWith({
    bool? disableChatReporting,
    bool? disableTelemetry,
    bool? disableCrashReporting,
    bool? disableAnalytics,
    bool? disableAutoUpdate,
  }) {
    return PrivacyConfig(
      disableChatReporting: disableChatReporting ?? this.disableChatReporting,
      disableTelemetry: disableTelemetry ?? this.disableTelemetry,
      disableCrashReporting: disableCrashReporting ?? this.disableCrashReporting,
      disableAnalytics: disableAnalytics ?? this.disableAnalytics,
      disableAutoUpdate: disableAutoUpdate ?? this.disableAutoUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disableChatReporting': disableChatReporting,
      'disableTelemetry': disableTelemetry,
      'disableCrashReporting': disableCrashReporting,
      'disableAnalytics': disableAnalytics,
      'disableAutoUpdate': disableAutoUpdate,
    };
  }

  factory PrivacyConfig.fromJson(Map<String, dynamic> json) {
    return PrivacyConfig(
      disableChatReporting: json['disableChatReporting'] as bool? ?? true,
      disableTelemetry: json['disableTelemetry'] as bool? ?? true,
      disableCrashReporting: json['disableCrashReporting'] as bool? ?? false,
      disableAnalytics: json['disableAnalytics'] as bool? ?? true,
      disableAutoUpdate: json['disableAutoUpdate'] as bool? ?? false,
    );
  }
}

/// 隐私保护管理器
class PrivacyManager {
  static PrivacyManager? _instance;

  factory PrivacyManager() {
    _instance ??= PrivacyManager._internal();
    return _instance!;
  }

  PrivacyManager._internal();

  final Logger _logger = Logger('PrivacyManager');
  final ConfigManager _configManager = ConfigManager();

  /// 获取当前隐私配置
  PrivacyConfig get config {
    try {
      final json = _configManager.get<String>(
        ConfigKeys.privacyConfig,
      );
      if (json != null) {
        return PrivacyConfig.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      _logger.warn('Failed to load privacy config: $e');
    }
    return const PrivacyConfig();
  }

  /// 保存隐私配置
  Future<void> setConfig(PrivacyConfig config) async {
    try {
      final jsonString = jsonEncode(config.toJson());
      await _configManager.set(
        ConfigKeys.privacyConfig,
        jsonString,
      );
      _logger.info('Privacy config saved');
    } catch (e) {
      _logger.error('Failed to save privacy config', e);
      rethrow;
    }
  }

  /// 获取隐私保护的JVM参数
  List<String> getPrivacyJvmArgs() {
    final args = <String>[];
    final cfg = config;

    if (cfg.disableChatReporting) {
      // 禁用Minecraft聊天报告功能
      args.add('-Dfml.chatReporting.disabled=true');
    }

    if (cfg.disableTelemetry) {
      // 禁用遥测
      args.add('-Dmixin.env.disableReportRemoteChanges=true');
      args.add('-Dpolyref.refmap.remap=false');
    }

    return args;
  }

  /// 获取隐私保护的游戏参数
  List<String> getPrivacyGameArgs() {
    final args = <String>[];
    final cfg = config;

    // 禁用崩溃报告
    if (cfg.disableCrashReporting) {
      args.add('--disable-crash-reporting');
      args.add('--no-report');
    }

    return args;
  }

  /// 获取所有隐私保护参数
  Map<String, List<String>> getAllPrivacyArgs() {
    return {
      'jvm': getPrivacyJvmArgs(),
      'game': getPrivacyGameArgs(),
    };
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    await setConfig(const PrivacyConfig());
  }

}
