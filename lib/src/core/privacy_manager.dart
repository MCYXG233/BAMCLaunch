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
          _parseJsonString(json),
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
      final jsonString = _encodeJsonString(config.toJson());
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

  /// JSON解析辅助方法
  Map<String, dynamic> _parseJsonString(String json) {
    // 简单的JSON解析
    try {
      // 处理基本类型
      if (json.startsWith('{') && json.endsWith('}')) {
        final map = <String, dynamic>{};
        final content = json.substring(1, json.length - 1);
        final pairs = _splitJsonPairs(content);
        
        for (final pair in pairs) {
          final colonIndex = pair.indexOf(':');
          if (colonIndex > 0) {
            final key = pair.substring(0, colonIndex).trim().replaceAll('"', '');
            final value = pair.substring(colonIndex + 1).trim();
            map[key] = _parseJsonValue(value);
          }
        }
        return map;
      }
    } catch (e) {
      _logger.warn('JSON parse error: $e');
    }
    return {};
  }

  List<String> _splitJsonPairs(String content) {
    final pairs = <String>[];
    var current = '';
    var depth = 0;
    var inString = false;
    
    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      
      if (char == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
        current += char;
      } else if (!inString) {
        if (char == '{' || char == '[') depth++;
        if (char == '}' || char == ']') depth--;
        
        if (char == ',' && depth == 0) {
          pairs.add(current.trim());
          current = '';
        } else {
          current += char;
        }
      } else {
        current += char;
      }
    }
    
    if (current.isNotEmpty) {
      pairs.add(current.trim());
    }
    
    return pairs;
  }

  dynamic _parseJsonValue(String value) {
    value = value.trim();
    
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null') return null;
    
    // 尝试解析数字
    final numValue = num.tryParse(value);
    if (numValue != null) {
      if (value.contains('.')) {
        return numValue.toDouble();
      }
      return numValue.toInt();
    }
    
    // 移除引号
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    
    return value;
  }

  /// JSON编码辅助方法
  String _encodeJsonString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.write('{');
    var first = true;
    
    for (final entry in map.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":');
      buffer.write(_encodeValue(entry.value));
    }
    
    buffer.write('}');
    return buffer.toString();
  }

  String _encodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return '"${_escapeString(value)}"';
    if (value is List) {
      return '[${value.map(_encodeValue).join(',')}]';
    }
    if (value is Map) {
      return _encodeJsonString(value.cast<String, dynamic>());
    }
    return '"$value"';
  }

  String _escapeString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
