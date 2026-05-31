import 'config_manager_impl.dart';
import 'config_models.dart';

/// 配置管理器统一接口
/// 定义了配置读写、加密存储、持久化和变更监听的抽象
abstract class IConfigManager {
  /// 初始化配置管理器
  /// 加载配置文件并初始化内部状态
  Future<void> initialize();

  /// 获取配置值
  /// [key] 配置键
  /// [defaultValue] 当配置不存在时返回的默认值
  T? get<T>(String key, {T? defaultValue});

  /// 设置配置值
  /// [key] 配置键
  /// [value] 配置值
  Future<void> set<T>(String key, T value);

  /// 设置加密配置值
  /// 用于存储敏感信息，如密码、令牌等
  /// [key] 配置键
  /// [value] 明文值
  Future<void> setEncrypted(String key, String value);

  /// 获取解密配置值
  /// [key] 配置键
  /// 返回解密后的明文值，如果解密失败返回null
  Future<String?> getEncrypted(String key);

  /// 删除配置
  /// [key] 要删除的配置键
  Future<void> remove(String key);

  /// 清空所有配置
  Future<void> clear();

  /// 保存配置到文件
  Future<void> save();

  /// 从文件加载配置
  Future<void> load();

  /// 配置变更流
  /// 当配置发生变化时，会发出变更的键名
  Stream<String> get configChanges;

  /// 获取字符串配置值的便捷方法
  String? getString(String key, {String? defaultValue}) =>
      get<String>(key, defaultValue: defaultValue);

  /// 设置字符串配置值的便捷方法
  Future<void> setString(String key, String value) => set(key, value);

  /// 获取整数配置值的便捷方法
  int? getInt(String key, {int? defaultValue}) =>
      get<int>(key, defaultValue: defaultValue);

  /// 设置整数配置值的便捷方法
  Future<void> setInt(String key, int value) => set(key, value);

  /// 获取布尔配置值的便捷方法
  bool? getBool(String key, {bool? defaultValue}) =>
      get<bool>(key, defaultValue: defaultValue);

  /// 设置布尔配置值的便捷方法
  Future<void> setBool(String key, bool value) => set(key, value);

  /// 获取完整的启动器配置
  LauncherConfig getLauncherConfig();

  /// 保存完整的启动器配置
  Future<void> setLauncherConfig(LauncherConfig config);

  /// 批量更新配置
  Future<void> updateConfig(Map<String, dynamic> updates);

  /// 增加运行计数
  Future<int> incrementRunCount();

  /// 获取额外的 Java 路径列表
  List<String> getExtraJavaPaths();

  /// 添加额外的 Java 路径
  Future<void> addExtraJavaPath(String path);

  /// 移除额外的 Java 路径
  Future<void> removeExtraJavaPath(String path);

  /// 获取被抑制的对话框列表
  List<String> getSuppressedDialogs();

  /// 抑制对话框
  Future<void> suppressDialog(String dialogId);

  /// 检查对话框是否被抑制
  bool isDialogSuppressed(String dialogId);

  /// 获取本地游戏目录列表
  List<GameDirectory> getLocalGameDirectories();

  /// 添加本地游戏目录
  Future<void> addLocalGameDirectory(GameDirectory dir);

  /// 移除本地游戏目录
  Future<void> removeLocalGameDirectory(String dirPath);
}

/// 配置管理器（单例）
/// 使用 ConfigManagerImpl 作为实现
class ConfigManager implements IConfigManager {
  static ConfigManager? _instance;
  final IConfigManager _impl = ConfigManagerImpl();

  /// 获取单例实例
  static ConfigManager get instance {
    _instance ??= ConfigManager._internal();
    return _instance!;
  }

  /// 私有构造函数
  ConfigManager._internal();

  /// 工厂构造函数
  factory ConfigManager() => instance;

  /// 重置单例（用于测试）
  static void reset() {
    _instance = null;
  }

  @override
  Future<void> initialize() => _impl.initialize();

  @override
  T? get<T>(String key, {T? defaultValue}) =>
      _impl.get(key, defaultValue: defaultValue);

  @override
  Future<void> set<T>(String key, T value) => _impl.set(key, value);

  @override
  Future<void> setEncrypted(String key, String value) =>
      _impl.setEncrypted(key, value);

  @override
  Future<String?> getEncrypted(String key) => _impl.getEncrypted(key);

  @override
  Future<void> remove(String key) => _impl.remove(key);

  @override
  Future<void> clear() => _impl.clear();

  @override
  Future<void> save() => _impl.save();

  @override
  Future<void> load() => _impl.load();

  @override
  Stream<String> get configChanges => _impl.configChanges;

  @override
  String? getString(String key, {String? defaultValue}) =>
      _impl.getString(key, defaultValue: defaultValue);

  @override
  Future<void> setString(String key, String value) =>
      _impl.setString(key, value);

  @override
  int? getInt(String key, {int? defaultValue}) =>
      _impl.getInt(key, defaultValue: defaultValue);

  @override
  Future<void> setInt(String key, int value) => _impl.setInt(key, value);

  @override
  bool? getBool(String key, {bool? defaultValue}) =>
      _impl.getBool(key, defaultValue: defaultValue);

  @override
  Future<void> setBool(String key, bool value) => _impl.setBool(key, value);

  @override
  LauncherConfig getLauncherConfig() => _impl.getLauncherConfig();

  @override
  Future<void> setLauncherConfig(LauncherConfig config) =>
      _impl.setLauncherConfig(config);

  @override
  Future<void> updateConfig(Map<String, dynamic> updates) =>
      _impl.updateConfig(updates);

  @override
  Future<int> incrementRunCount() => _impl.incrementRunCount();

  @override
  List<String> getExtraJavaPaths() => _impl.getExtraJavaPaths();

  @override
  Future<void> addExtraJavaPath(String path) => _impl.addExtraJavaPath(path);

  @override
  Future<void> removeExtraJavaPath(String path) => _impl.removeExtraJavaPath(path);

  @override
  List<String> getSuppressedDialogs() => _impl.getSuppressedDialogs();

  @override
  Future<void> suppressDialog(String dialogId) => _impl.suppressDialog(dialogId);

  @override
  bool isDialogSuppressed(String dialogId) => _impl.isDialogSuppressed(dialogId);

  @override
  List<GameDirectory> getLocalGameDirectories() => _impl.getLocalGameDirectories();

  @override
  Future<void> addLocalGameDirectory(GameDirectory dir) =>
      _impl.addLocalGameDirectory(dir);

  @override
  Future<void> removeLocalGameDirectory(String dirPath) =>
      _impl.removeLocalGameDirectory(dirPath);
}
