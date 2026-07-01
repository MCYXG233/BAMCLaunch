import 'config_manager_impl.dart';
import 'config_models.dart';
import '../di/service_locator.dart';

/// 配置管理器统一接口
///
/// 该接口定义了配置管理器的核心功能抽象，包括：
/// - 配置的读写操作（支持泛型）
/// - 敏感数据的加密存储
/// - 配置的持久化（保存到文件/从文件加载）
/// - 配置变更的监听机制
/// - 启动器专用配置的管理
///
/// ## 使用方式
///
/// ```dart
/// // 通过 ConfigManager 单例访问
/// final config = ConfigManager.instance;
/// await config.initialize();
///
/// // 读取配置
/// final value = config.getString('key', defaultValue: 'default');
///
/// // 写入配置
/// await config.setString('key', 'value');
/// await config.save();
/// ```
///
/// ## 实现说明
///
/// 具体实现由 [ConfigManagerImpl] 类提供，[ConfigManager] 类作为单例包装器使用。
/// 这种设计允许在测试时替换实现，同时保持全局访问的便利性。
///
/// ## 线程安全
///
/// 所有方法都是异步的，应确保在并发访问时的安全性。
abstract class IConfigManager {
  /// 初始化配置管理器
  ///
  /// 加载配置文件并初始化内部状态。在调用其他配置操作之前，
  /// 必须先调用此方法完成初始化。
  ///
  /// ## 异常
  ///
  /// - [FileSystemException] 当配置文件存在但无法读取时
  /// - [FormatException] 当配置文件格式不正确时
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final config = ConfigManager.instance;
  /// await config.initialize();
  /// // 现在可以安全地使用其他配置操作
  /// ```
  Future<void> initialize();

  /// 获取配置值
  ///
  /// 根据指定的键获取配置值，支持泛型类型推断。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名，用于标识配置项
  /// - [defaultValue] 当配置不存在时返回的默认值，可选参数
  ///
  /// ## 返回值
  ///
  /// 返回配置值，如果配置不存在且未提供默认值则返回 `null`。
  /// 如果提供了默认值且配置不存在，则返回默认值。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// // 获取字符串配置
  /// final name = config.get<String>('username');
  ///
  /// // 使用默认值
  /// final theme = config.get<String>('theme', defaultValue: 'dark');
  /// ```
  T? get<T>(String key, {T? defaultValue});

  /// 设置配置值
  ///
  /// 将指定键值对保存到内存中的配置存储。注意此操作不会自动持久化到文件，
  /// 需要调用 [save] 方法才会写入文件。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [value] 配置值，支持任意可序列化的类型
  ///
  /// ## 异常
  ///
  /// - [ArgumentError] 当 key 为空字符串时
  /// - [TypeError] 当 value 类型无法序列化时
  ///
  /// ## 示例
  ///
  /// ```dart
  /// await config.set('username', 'player1');
  /// await config.save(); // 持久化到文件
  /// ```
  Future<void> set<T>(String key, T value);

  /// 设置加密配置值
  ///
  /// 用于存储敏感信息，如密码、令牌、API密钥等。值会在存储前进行加密处理。
  /// 加密后的值与普通配置分开存储，以确保安全性。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [value] 明文值，存储前会被加密
  ///
  /// ## 安全说明
  ///
  /// - 加密算法由实现类决定
  /// - 加密密钥应安全存储
  /// - 不建议存储极长的字符串，加密性能可能受影响
  ///
  /// ## 示例
  ///
  /// ```dart
  /// // 存储敏感信息
  /// await config.setEncrypted('api_token', 'secret_token_123');
  /// await config.save();
  /// ```
  Future<void> setEncrypted(String key, String value);

  /// 获取解密配置值
  ///
  /// 获取之前通过 [setEncrypted] 存储的加密配置，并返回解密后的明文。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  ///
  /// ## 返回值
  ///
  /// 返回解密后的明文值。如果配置不存在或解密失败，返回 `null`。
  ///
  /// ## 异常
  ///
  /// 通常不抛出异常，解密失败时返回 `null`。但具体行为取决于实现。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final token = await config.getEncrypted('api_token');
  /// if (token != null) {
  ///   // 使用解密后的令牌
  /// }
  /// ```
  Future<String?> getEncrypted(String key);

  /// 删除配置
  ///
  /// 从配置存储中移除指定的配置项。此操作同时删除普通配置和加密配置。
  ///
  /// ## 参数
  ///
  /// - [key] 要删除的配置键名
  ///
  /// ## 注意
  ///
  /// 如果指定的键不存在，此操作不会抛出异常，而是静默完成。
  Future<void> remove(String key);

  /// 清空所有配置
  ///
  /// 删除所有配置项，包括普通配置和加密配置。
  /// 此操作不可逆，请谨慎使用。
  ///
  /// ## 警告
  ///
  /// 此操作会清除所有用户设置，通常只在重置应用时使用。
  Future<void> clear();

  /// 保存配置到文件
  ///
  /// 将内存中的所有配置持久化到本地文件。通常在修改配置后调用。
  ///
  /// ## 异常
  ///
  /// - [FileSystemException] 当无法写入配置文件时（如权限不足、磁盘空间不足）
  ///
  /// ## 示例
  ///
  /// ```dart
  /// await config.setString('theme', 'dark');
  /// await config.setInt('volume', 80);
  /// await config.save(); // 一次性保存所有更改
  /// ```
  Future<void> save();

  /// 从文件加载配置
  ///
  /// 从本地文件重新加载配置到内存。这会覆盖内存中未保存的更改。
  ///
  /// ## 用途
  ///
  /// - 当需要放弃内存中的更改时
  /// - 当外部程序可能修改了配置文件时
  /// - 当需要刷新配置状态时
  ///
  /// ## 异常
  ///
  /// - [FileSystemException] 当配置文件存在但无法读取时
  /// - [FormatException] 当配置文件格式不正确时
  Future<void> load();

  /// 配置变更流
  ///
  /// 当配置发生变化时，此流会发出变更的配置键名。
  /// 可用于监听配置变化并做出响应。
  ///
  /// ## 返回值
  ///
  /// 返回一个 [Stream<String>]，每次配置变更时发出变更的键名。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// config.configChanges.listen((key) {
  ///   print('配置 $key 已变更');
  ///   if (key == 'theme') {
  ///     // 重新加载主题
  ///   }
  /// });
  /// ```
  Stream<String> get configChanges;

  /// 获取字符串配置值的便捷方法
  ///
  /// 这是 [get] 方法的类型特化版本，专门用于获取字符串类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [defaultValue] 默认值，可选
  ///
  /// ## 返回值
  ///
  /// 返回字符串配置值或默认值，如果配置不存在且无默认值则返回 `null`。
  String? getString(String key, {String? defaultValue}) =>
      get<String>(key, defaultValue: defaultValue);

  /// 设置字符串配置值的便捷方法
  ///
  /// 这是 [set] 方法的类型特化版本，专门用于设置字符串类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [value] 字符串配置值
  Future<void> setString(String key, String value) => set(key, value);

  /// 获取整数配置值的便捷方法
  ///
  /// 这是 [get] 方法的类型特化版本，专门用于获取整数类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [defaultValue] 默认值，可选
  ///
  /// ## 返回值
  ///
  /// 返回整数配置值或默认值，如果配置不存在且无默认值则返回 `null`。
  int? getInt(String key, {int? defaultValue}) =>
      get<int>(key, defaultValue: defaultValue);

  /// 设置整数配置值的便捷方法
  ///
  /// 这是 [set] 方法的类型特化版本，专门用于设置整数类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [value] 整数配置值
  Future<void> setInt(String key, int value) => set(key, value);

  /// 获取布尔配置值的便捷方法
  ///
  /// 这是 [get] 方法的类型特化版本，专门用于获取布尔类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [defaultValue] 默认值，可选
  ///
  /// ## 返回值
  ///
  /// 返回布尔配置值或默认值，如果配置不存在且无默认值则返回 `null`。
  bool? getBool(String key, {bool? defaultValue}) =>
      get<bool>(key, defaultValue: defaultValue);

  /// 设置布尔配置值的便捷方法
  ///
  /// 这是 [set] 方法的类型特化版本，专门用于设置布尔类型的配置。
  ///
  /// ## 参数
  ///
  /// - [key] 配置键名
  /// - [value] 布尔配置值
  Future<void> setBool(String key, bool value) => set(key, value);

  /// 获取完整的启动器配置
  ///
  /// 返回包含所有启动器设置的 [LauncherConfig] 对象。
  /// 这是一个聚合配置对象，包含了启动器的各种设置项。
  ///
  /// ## 返回值
  ///
  /// 返回当前启动器的完整配置对象。
  ///
  /// ## 注意
  ///
  /// 返回的是配置的副本或不可变视图，修改返回值不会影响实际配置。
  /// 要修改配置，请使用 [setLauncherConfig] 或其他设置方法。
  LauncherConfig getLauncherConfig();

  /// 保存完整的启动器配置
  ///
  /// 用新的配置对象替换当前的所有启动器配置。
  /// 这是一个全量更新操作，会覆盖之前的所有设置。
  ///
  /// ## 参数
  ///
  /// - [config] 新的启动器配置对象
  ///
  /// ## 注意
  ///
  /// 此操作会完全替换现有配置，请确保传入完整的配置对象。
  /// 调用后需要调用 [save] 才能持久化到文件。
  Future<void> setLauncherConfig(LauncherConfig config);

  /// 批量更新配置
  ///
  /// 一次性更新多个配置项，比逐个调用 [set] 更高效。
  ///
  /// ## 参数
  ///
  /// - [updates] 包含多个键值对的 Map，键为配置名，值为配置值
  ///
  /// ## 示例
  ///
  /// ```dart
  /// await config.updateConfig({
  ///   'theme': 'dark',
  ///   'language': 'zh_CN',
  ///   'volume': 80,
  /// });
  /// await config.save();
  /// ```
  Future<void> updateConfig(Map<String, dynamic> updates);

  /// 增加运行计数
  ///
  /// 将启动器的运行次数加一，并返回新的计数值。
  /// 通常用于统计应用启动次数。
  ///
  /// ## 返回值
  ///
  /// 返回增加后的运行计数（新值）。
  ///
  /// ## 用途
  ///
  /// - 统计用户使用频率
  /// - 在特定启动次数时显示提示或引导
  /// - 用于分析用户留存
  Future<int> incrementRunCount();

  /// 获取额外的 Java 路径列表
  ///
  /// 返回用户手动添加的 Java 安装路径列表。
  /// 这些路径用于在系统 PATH 之外查找 Java 运行时。
  ///
  /// ## 返回值
  ///
  /// 返回 Java 路径字符串列表，如果没有额外路径则返回空列表。
  ///
  /// ## 用途
  ///
  /// - Minecraft 启动器需要指定 Java 路径
  /// - 支持多版本 Java 管理
  List<String> getExtraJavaPaths();

  /// 添加额外的 Java 路径
  ///
  /// 向额外 Java 路径列表中添加新路径。
  /// 如果路径已存在，通常不会重复添加（取决于实现）。
  ///
  /// ## 参数
  ///
  /// - [path] Java 安装目录的路径
  ///
  /// ## 注意
  ///
  /// - 路径有效性检查由调用方负责
  /// - 调用后需要 [save] 才能持久化
  Future<void> addExtraJavaPath(String path);

  /// 移除额外的 Java 路径
  ///
  /// 从额外 Java 路径列表中移除指定路径。
  ///
  /// ## 参数
  ///
  /// - [path] 要移除的 Java 路径
  ///
  /// ## 注意
  ///
  /// 如果路径不存在于列表中，此操作静默完成，不抛出异常。
  Future<void> removeExtraJavaPath(String path);

  /// 获取被抑制的对话框列表
  ///
  /// 返回用户选择不再显示的对话框 ID 列表。
  /// 这些对话框在后续启动时将不再弹出。
  ///
  /// ## 返回值
  ///
  /// 返回被抑制的对话框 ID 字符串列表。
  ///
  /// ## 用途
  ///
  /// - 实现"不再显示此对话框"功能
  /// - 记录用户的对话框偏好
  List<String> getSuppressedDialogs();

  /// 抑制对话框
  ///
  /// 将指定对话框标记为不再显示。
  ///
  /// ## 参数
  ///
  /// - [dialogId] 对话框的唯一标识符
  ///
  /// ## 示例
  ///
  /// ```dart
  /// // 用户勾选"不再显示"
  /// if (userCheckedDontShowAgain) {
  ///   await config.suppressDialog('welcome_dialog');
  ///   await config.save();
  /// }
  /// ```
  Future<void> suppressDialog(String dialogId);

  /// 检查对话框是否被抑制
  ///
  /// 判断指定的对话框是否已被用户标记为不再显示。
  ///
  /// ## 参数
  ///
  /// - [dialogId] 对话框的唯一标识符
  ///
  /// ## 返回值
  ///
  /// 如果对话框已被抑制返回 `true`，否则返回 `false`。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// if (!config.isDialogSuppressed('welcome_dialog')) {
  ///   showWelcomeDialog();
  /// }
  /// ```
  bool isDialogSuppressed(String dialogId);

  /// 获取本地游戏目录列表
  ///
  /// 返回用户添加的本地游戏目录列表。
  /// 这些目录用于扫描和管理本地安装的游戏实例。
  ///
  /// ## 返回值
  ///
  /// 返回 [GameDirectory] 对象列表，每个对象包含目录路径和相关元数据。
  ///
  /// ## 用途
  ///
  /// - 管理多个游戏安装位置
  /// - 支持便携版或自定义位置的游戏
  List<GameDirectory> getLocalGameDirectories();

  /// 添加本地游戏目录
  ///
  /// 向本地游戏目录列表中添加新目录。
  ///
  /// ## 参数
  ///
  /// - [dir] 要添加的游戏目录对象，包含路径和其他元数据
  ///
  /// ## 注意
  ///
  /// - 目录有效性检查由调用方负责
  /// - 调用后需要 [save] 才能持久化
  Future<void> addLocalGameDirectory(GameDirectory dir);

  /// 移除本地游戏目录
  ///
  /// 从本地游戏目录列表中移除指定路径的目录。
  ///
  /// ## 参数
  ///
  /// - [dirPath] 要移除的目录路径
  ///
  /// ## 注意
  ///
  /// 此操作只从配置中移除目录记录，不会删除实际的游戏文件。
  Future<void> removeLocalGameDirectory(String dirPath);
}

/// 配置管理器（单例模式）
///
/// 这是 [IConfigManager] 接口的具体实现类，采用单例模式设计。
/// 内部委托给 [ConfigManagerImpl] 实例进行实际的配置操作。
///
/// ## 设计模式
///
/// 使用单例模式确保整个应用只有一个配置管理器实例，
/// 避免配置状态不一致的问题。
///
/// ## 使用方式
///
/// ```dart
/// // 方式一：通过静态属性访问（推荐）
/// final config = ConfigManager.instance;
///
/// // 方式二：通过工厂构造函数访问
/// final config = ConfigManager();
///
/// // 初始化
/// await config.initialize();
///
/// // 使用配置
/// final theme = config.getString('theme', defaultValue: 'light');
/// await config.setString('theme', 'dark');
/// await config.save();
/// ```
///
/// ## 测试支持
///
/// 在单元测试中，可以使用 [reset] 方法重置单例状态，
/// 以便在每个测试用例之间隔离状态。
///
/// ```dart
/// setUp(() {
///   ConfigManager.reset();
/// });
/// ```
///
/// ## 实现委托
///
/// 此类是一个代理/装饰器，所有方法调用都委托给内部的 [ConfigManagerImpl] 实例。
/// 这种设计允许：
/// - 保持单例的便利性
/// - 实现细节可以独立变化
/// - 便于测试时替换实现
class ConfigManager implements IConfigManager {
  /// 单例实例
  ///
  /// 使用可空类型和延迟初始化，确保线程安全的单例模式。
  /// 通过 [instance] getter 访问时会自动创建实例。
  static ConfigManager? _instance;

  /// 内部实现实例
  ///
  /// 委托给 [ConfigManagerImpl] 进行实际的配置操作。
  /// 在构造时创建，确保每次单例重置后都能获得新的实现实例。
  final IConfigManager _impl = ConfigManagerImpl();

  /// 获取单例实例
  ///
  /// 如果实例不存在则创建新实例。
  /// 使用空值合并赋值运算符确保只创建一次实例。
  ///
  /// ## 返回值
  ///
  /// 返回 [ConfigManager] 的唯一实例。
  static ConfigManager get instance {
    return ServiceLocator.instance.tryGet<ConfigManager>() ??
        (_instance ??= ConfigManager._internal());
  }

  /// 私有构造函数
  ///
  /// 内部构造函数，防止外部直接创建实例。
  /// 初始化内部实现对象 [_impl]。
  ConfigManager._internal();

  /// 工厂构造函数
  ///
  /// 返回单例实例，等同于访问 [instance] 属性。
  /// 提供更自然的语法：`ConfigManager()` 而不是 `ConfigManager.instance`。
  factory ConfigManager() => instance;

  /// 重置单例
  ///
  /// 将单例实例设为 null，下次访问 [instance] 时会创建新实例。
  /// 主要用于单元测试，在测试之间隔离状态。
  ///
  /// ## 警告
  ///
  /// 此方法会丢弃当前实例的所有状态，包括未保存的配置更改。
  /// 生产代码中应谨慎使用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// // 在测试的 setUp 中重置
  /// setUp(() {
  ///   ConfigManager.reset();
  /// });
  ///
  /// // 在测试的 tearDown 中也可以重置
  /// tearDown(() {
  ///   ConfigManager.reset();
  /// });
  /// ```
  static void reset() {
    _instance = null;
  }

  /// 初始化配置管理器
  ///
  /// 委托给内部实现进行初始化。
  /// 必须在使用其他配置操作前调用。
  @override
  Future<void> initialize() => _impl.initialize();

  /// 获取配置值
  ///
  /// 委托给内部实现获取配置值。
  @override
  T? get<T>(String key, {T? defaultValue}) =>
      _impl.get(key, defaultValue: defaultValue);

  /// 设置配置值
  ///
  /// 委托给内部实现设置配置值。
  @override
  Future<void> set<T>(String key, T value) => _impl.set(key, value);

  /// 设置加密配置值
  ///
  /// 委托给内部实现进行加密存储。
  @override
  Future<void> setEncrypted(String key, String value) =>
      _impl.setEncrypted(key, value);

  /// 获取解密配置值
  ///
  /// 委托给内部实现进行解密读取。
  @override
  Future<String?> getEncrypted(String key) => _impl.getEncrypted(key);

  /// 删除配置
  ///
  /// 委托给内部实现删除指定配置。
  @override
  Future<void> remove(String key) => _impl.remove(key);

  /// 清空所有配置
  ///
  /// 委托给内部实现清空配置。
  @override
  Future<void> clear() => _impl.clear();

  /// 保存配置到文件
  ///
  /// 委托给内部实现进行持久化。
  @override
  Future<void> save() => _impl.save();

  /// 从文件加载配置
  ///
  /// 委托给内部实现从文件加载。
  @override
  Future<void> load() => _impl.load();

  /// 配置变更流
  ///
  /// 委托给内部实现的变更流。
  @override
  Stream<String> get configChanges => _impl.configChanges;

  /// 获取字符串配置值
  ///
  /// 委托给内部实现获取字符串配置。
  @override
  String? getString(String key, {String? defaultValue}) =>
      _impl.getString(key, defaultValue: defaultValue);

  /// 设置字符串配置值
  ///
  /// 委托给内部实现设置字符串配置。
  @override
  Future<void> setString(String key, String value) =>
      _impl.setString(key, value);

  /// 获取整数配置值
  ///
  /// 委托给内部实现获取整数配置。
  @override
  int? getInt(String key, {int? defaultValue}) =>
      _impl.getInt(key, defaultValue: defaultValue);

  /// 设置整数配置值
  ///
  /// 委托给内部实现设置整数配置。
  @override
  Future<void> setInt(String key, int value) => _impl.setInt(key, value);

  /// 获取布尔配置值
  ///
  /// 委托给内部实现获取布尔配置。
  @override
  bool? getBool(String key, {bool? defaultValue}) =>
      _impl.getBool(key, defaultValue: defaultValue);

  /// 设置布尔配置值
  ///
  /// 委托给内部实现设置布尔配置。
  @override
  Future<void> setBool(String key, bool value) => _impl.setBool(key, value);

  /// 获取完整的启动器配置
  ///
  /// 委托给内部实现获取启动器配置。
  @override
  LauncherConfig getLauncherConfig() => _impl.getLauncherConfig();

  /// 保存完整的启动器配置
  ///
  /// 委托给内部实现设置启动器配置。
  @override
  Future<void> setLauncherConfig(LauncherConfig config) =>
      _impl.setLauncherConfig(config);

  /// 批量更新配置
  ///
  /// 委托给内部实现批量更新配置。
  @override
  Future<void> updateConfig(Map<String, dynamic> updates) =>
      _impl.updateConfig(updates);

  /// 增加运行计数
  ///
  /// 委托给内部实现增加运行计数。
  @override
  Future<int> incrementRunCount() => _impl.incrementRunCount();

  /// 获取额外的 Java 路径列表
  ///
  /// 委托给内部实现获取 Java 路径列表。
  @override
  List<String> getExtraJavaPaths() => _impl.getExtraJavaPaths();

  /// 添加额外的 Java 路径
  ///
  /// 委托给内部实现添加 Java 路径。
  @override
  Future<void> addExtraJavaPath(String path) => _impl.addExtraJavaPath(path);

  /// 移除额外的 Java 路径
  ///
  /// 委托给内部实现移除 Java 路径。
  @override
  Future<void> removeExtraJavaPath(String path) => _impl.removeExtraJavaPath(path);

  /// 获取被抑制的对话框列表
  ///
  /// 委托给内部实现获取抑制对话框列表。
  @override
  List<String> getSuppressedDialogs() => _impl.getSuppressedDialogs();

  /// 抑制对话框
  ///
  /// 委托给内部实现抑制对话框。
  @override
  Future<void> suppressDialog(String dialogId) => _impl.suppressDialog(dialogId);

  /// 检查对话框是否被抑制
  ///
  /// 委托给内部实现检查对话框抑制状态。
  @override
  bool isDialogSuppressed(String dialogId) => _impl.isDialogSuppressed(dialogId);

  /// 获取本地游戏目录列表
  ///
  /// 委托给内部实现获取游戏目录列表。
  @override
  List<GameDirectory> getLocalGameDirectories() => _impl.getLocalGameDirectories();

  /// 添加本地游戏目录
  ///
  /// 委托给内部实现添加游戏目录。
  @override
  Future<void> addLocalGameDirectory(GameDirectory dir) =>
      _impl.addLocalGameDirectory(dir);

  /// 移除本地游戏目录
  ///
  /// 委托给内部实现移除游戏目录。
  @override
  Future<void> removeLocalGameDirectory(String dirPath) =>
      _impl.removeLocalGameDirectory(dirPath);
}