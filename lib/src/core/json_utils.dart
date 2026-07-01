/// JSON 安全类型转换工具
///
/// 用于替代 JSON 解析中不安全的 `as` 强制类型转换。
/// 当服务端返回的类型与预期不符时，会尝试转换而非直接抛出 TypeError。
class JsonUtils {
  /// 安全获取字符串值
  static String? getString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// 安全获取字符串值（带默认值）
  static String getStringOrDefault(dynamic value, [String defaultValue = '']) {
    return getString(value) ?? defaultValue;
  }

  /// 安全获取整数值
  static int? getInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 安全获取整数值（带默认值）
  static int getIntOrDefault(dynamic value, [int defaultValue = 0]) {
    return getInt(value) ?? defaultValue;
  }

  /// 安全获取浮点数值
  static double? getDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 安全获取浮点数值（带默认值）
  static double getDoubleOrDefault(dynamic value, [double defaultValue = 0.0]) {
    return getDouble(value) ?? defaultValue;
  }

  /// 安全获取布尔值
  static bool? getBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  /// 安全获取布尔值（带默认值）
  static bool getBoolOrDefault(dynamic value, [bool defaultValue = false]) {
    return getBool(value) ?? defaultValue;
  }

  /// 安全获取列表
  static List<T>? getList<T>(dynamic value, T Function(dynamic) converter) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value.map(converter).toList();
    } catch (_) {
      return null;
    }
  }

  /// 安全获取 Map
  static Map<String, dynamic>? getMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
