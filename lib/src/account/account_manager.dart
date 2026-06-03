import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../core/logger.dart';
import 'account.dart';

/// 账户管理器接口
///
/// 定义了账户管理器的标准接口，用于管理用户账户的增删改查操作。
/// 该接口提供了账户管理的基本功能，包括：
/// - 获取所有账户列表
/// - 获取和设置当前选中的账户
/// - 添加离线账户和微软账户
/// - 更新和删除账户
/// - 监听账户变更事件
///
/// 使用示例：
/// ```dart
/// IAccountManager accountManager = AccountManager.instance;
/// final accounts = await accountManager.getAccounts();
/// ```
abstract class IAccountManager {
  /// 获取所有账户列表
  ///
  /// 返回当前管理的所有账户的不可变列表。
  ///
  /// 返回值：
  /// - `Future<List<Account>>`: 包含所有账户的列表，如果没有任何账户则返回空列表
  ///
  /// 示例：
  /// ```dart
  /// final accounts = await accountManager.getAccounts();
  /// for (final account in accounts) {
  ///   print('账户: ${account.username}');
  /// }
  /// ```
  Future<List<Account>> getAccounts();

  /// 获取当前选中的账户
  ///
  /// 返回用户当前选中的账户。如果没有任何账户被选中，则返回 null。
  ///
  /// 返回值：
  /// - `Future<Account?>`: 当前选中的账户，如果没有选中账户则返回 null
  ///
  /// 示例：
  /// ```dart
  /// final selected = await accountManager.getSelectedAccount();
  /// if (selected != null) {
  ///   print('当前选中: ${selected.username}');
  /// }
  /// ```
  Future<Account?> getSelectedAccount();

  /// 选中指定账户
  ///
  /// 将指定的账户设置为当前选中状态，并更新其最后使用时间。
  /// 如果账户不存在，将抛出异常。
  ///
  /// 参数：
  /// - `accountId` (String): 要选中的账户的唯一标识符
  ///
  /// 异常：
  /// - `ArgumentError`: 当指定的账户ID不存在时抛出
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   await accountManager.selectAccount('account_123');
  ///   print('账户已选中');
  /// } catch (e) {
  ///   print('选中失败: $e');
  /// }
  /// ```
  Future<void> selectAccount(String accountId);

  /// 添加离线账户
  ///
  /// 创建一个新的离线模式账户。离线账户不需要验证，仅用于本地游戏。
  ///
  /// 参数：
  /// - `username` (String): 用户名，不能为空或仅包含空白字符
  ///
  /// 返回值：
  /// - `Future<Account>`: 新创建的账户对象
  ///
  /// 异常：
  /// - `ArgumentError`: 当用户名为空或仅包含空白字符时抛出
  ///
  /// 示例：
  /// ```dart
  /// final account = await accountManager.addOfflineAccount('Player123');
  /// print('创建离线账户: ${account.id}');
  /// ```
  Future<Account> addOfflineAccount(String username);

  /// 添加微软账户
  ///
  /// 创建一个新的微软账户或更新已存在的微软账户。
  /// 如果相同UUID的微软账户已存在，将更新该账户的用户名和最后使用时间。
  ///
  /// 参数：
  /// - `username` (String): 微软账户的用户名，不能为空
  /// - `uuid` (String): 微软账户的唯一标识符，不能为空
  ///
  /// 返回值：
  /// - `Future<Account>`: 新创建或更新后的账户对象
  ///
  /// 异常：
  /// - `ArgumentError`: 当用户名或UUID为空时抛出
  ///
  /// 示例：
  /// ```dart
  /// final account = await accountManager.addMicrosoftAccount(
  ///   'Steve',
  ///   '550e8400-e29b-41d4-a716-446655440000',
  /// );
  /// ```
  Future<Account> addMicrosoftAccount(String username, String uuid);

  /// 更新账户信息
  ///
  /// 更新指定账户的信息。账户ID必须存在，否则将抛出异常。
  ///
  /// 参数：
  /// - `account` (Account): 包含更新信息的账户对象，必须包含有效的ID
  ///
  /// 异常：
  /// - `ArgumentError`: 当账户ID不存在时抛出
  ///
  /// 示例：
  /// ```dart
  /// final updated = account.copyWith(username: 'NewName');
  /// await accountManager.updateAccount(updated);
  /// ```
  Future<void> updateAccount(Account account);

  /// 删除账户
  ///
  /// 删除指定的账户。如果删除的是当前选中的账户，
  /// 将自动取消选中状态并触发相应的事件。
  ///
  /// 参数：
  /// - `accountId` (String): 要删除的账户的唯一标识符
  ///
  /// 异常：
  /// - `ArgumentError`: 当账户ID不存在时抛出
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   await accountManager.removeAccount('account_123');
  ///   print('账户已删除');
  /// } catch (e) {
  ///   print('删除失败: $e');
  /// }
  /// ```
  Future<void> removeAccount(String accountId);

  /// 账户变更事件流
  ///
  /// 提供一个广播流，用于监听账户列表的变更事件。
  /// 当账户被添加、更新或删除时，会向该流发送新的账户列表。
  ///
  /// 返回值：
  /// - `Stream<List<Account>>`: 账户列表变更事件流
  ///
  /// 示例：
  /// ```dart
  /// accountManager.accountsStream.listen((accounts) {
  ///   print('账户列表已更新，共 ${accounts.length} 个账户');
  /// });
  /// ```
  Stream<List<Account>> get accountsStream;
}

/// 账户管理器实现类（单例模式）
///
/// 提供账户管理的完整实现，支持离线账户和微软账户的管理。
/// 该类使用单例模式确保全局只有一个账户管理器实例。
///
/// 主要职责：
/// - 管理账户的持久化存储（通过配置管理器）
/// - 提供账户的增删改查操作
/// - 管理当前选中账户的状态
/// - 验证和刷新账户令牌
/// - 发布账户相关事件
///
/// 使用方式：
/// ```dart
/// // 获取单例实例
/// final accountManager = AccountManager.instance;
///
/// // 初始化（通常在应用启动时调用）
/// await accountManager.initialize(
///   configManager: ConfigManager.instance,
///   eventBus: EventBus.instance,
/// );
///
/// // 使用账户管理功能
/// final accounts = await accountManager.getAccounts();
/// ```
///
/// 注意事项：
/// - 使用前必须调用 [initialize] 方法进行初始化
/// - 所有异步操作都会自动确保已初始化
/// - 账户数据会自动持久化到配置文件
class AccountManager implements IAccountManager {
  /// 单例实例
  static AccountManager? _instance;

  /// 工厂构造函数，返回单例实例
  ///
  /// 如果实例不存在，会自动创建一个新的实例。
  factory AccountManager() => _instance ??= AccountManager._internal();

  /// 私有内部构造函数，用于创建单例实例
  AccountManager._internal();

  /// 获取单例实例的静态方法
  ///
  /// 这是获取 AccountManager 实例的推荐方式。
  /// 如果实例不存在，会自动创建。
  ///
  /// 示例：
  /// ```dart
  /// final accountManager = AccountManager.instance;
  /// ```
  static AccountManager get instance =>
      _instance ??= AccountManager._internal();

  /// 重置单例实例
  ///
  /// 仅用于测试目的。调用后，下次访问 instance 将创建新的实例。
  /// 注意：此操作会清除所有缓存数据和状态。
  static void reset() {
    _instance = null;
  }

  /// 配置管理器实例，用于持久化账户数据
  IConfigManager? _configManager;

  /// 事件总线实例，用于发布账户相关事件
  EventBus? _eventBus;

  /// 账户缓存列表
  ///
  /// 存储所有已加载的账户对象，避免频繁读取配置文件。
  /// 对此列表的修改应通过 [_saveAccounts] 方法持久化。
  List<Account> _cachedAccounts = [];

  /// 账户变更流控制器
  ///
  /// 用于向订阅者广播账户列表变更事件。
  /// 使用广播模式，允许多个监听者同时订阅。
  StreamController<List<Account>>? _accountsStreamController;

  /// 初始化状态标志
  ///
  /// 标记账户管理器是否已完成初始化。
  /// 初始化包括加载账户数据和创建流控制器。
  bool _isInitialized = false;

  /// 日志记录器实例
  ///
  /// 用于记录账户管理器的操作日志，包括调试信息、错误信息等。
  final Logger _logger = Logger('AccountManager');

  /// 令牌过期时间阈值
  ///
  /// 当账户的最后使用时间超过此阈值时，认为令牌即将过期。
  /// 默认值为7天，用于判断是否需要刷新令牌。
  static const Duration _tokenExpiryThreshold = Duration(days: 7);

  /// 初始化账户管理器
  ///
  /// 必须在使用账户管理器之前调用此方法。
  /// 初始化过程包括：
  /// 1. 设置配置管理器和事件总线
  /// 2. 创建账户变更流控制器
  /// 3. 从配置文件加载账户数据
  ///
  /// 参数：
  /// - `configManager` (IConfigManager): 配置管理器，用于持久化账户数据
  /// - `eventBus` (EventBus): 事件总线，用于发布账户相关事件
  ///
  /// 注意：
  /// - 如果已经初始化，此方法会直接返回，不会重复初始化
  /// - 初始化是幂等操作
  ///
  /// 示例：
  /// ```dart
  /// final accountManager = AccountManager.instance;
  /// await accountManager.initialize(
  ///   configManager: ConfigManager.instance,
  ///   eventBus: EventBus.instance,
  /// );
  /// ```
  Future<void> initialize({
    required IConfigManager configManager,
    required EventBus eventBus,
  }) async {
    // 如果已初始化，直接返回，避免重复初始化
    if (_isInitialized) return;

    _configManager = configManager;
    _eventBus = eventBus;

    // 创建广播模式的流控制器，支持多个监听者
    _accountsStreamController = StreamController<List<Account>>.broadcast();

    // 从配置文件加载账户数据到缓存
    await _loadAccounts();

    _isInitialized = true;
  }

  /// 确保账户管理器已初始化
  ///
  /// 这是一个内部方法，用于在执行操作前确保管理器已初始化。
  /// 如果未初始化，会使用默认的配置管理器和事件总线实例进行自动初始化。
  ///
  /// 这种设计允许用户无需显式调用 initialize 方法，
  /// 在首次使用时自动完成初始化。
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // 使用默认实例进行自动初始化
    _configManager = ConfigManager.instance;
    _eventBus = EventBus.instance;
    _accountsStreamController = StreamController<List<Account>>.broadcast();

    await _loadAccounts();
    _isInitialized = true;
  }

  /// 从配置文件加载账户数据
  ///
  /// 从配置管理器中读取账户列表JSON数据，并解析为Account对象列表。
  /// 加载后的数据会缓存到 [_cachedAccounts] 中。
  ///
  /// 如果配置管理器未设置，会使用 ConfigManager.instance 作为默认值。
  /// 如果配置中没有账户数据，会初始化为空列表。
  Future<void> _loadAccounts() async {
    // 确保配置管理器可用
    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    // 从配置中读取账户列表JSON
    final accountsJson = _configManager!.get<List<dynamic>>(
      ConfigKeys.accounts,
      defaultValue: [],
    );

    // 解析JSON为Account对象列表
    // 使用安全转换确保类型正确
    _cachedAccounts =
        accountsJson
            ?.map(
              (json) =>
                  Account.fromJson(Map<String, dynamic>.from(json as Map)),
            )
            .toList() ??
        [];
  }

  /// 保存账户数据到配置文件
  ///
  /// 将当前缓存的账户列表序列化为JSON格式，并保存到配置管理器。
  /// 同时向流控制器发送账户变更通知。
  ///
  /// 此方法应在任何修改账户缓存后调用，确保数据持久化。
  Future<void> _saveAccounts() async {
    // 确保配置管理器可用
    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    // 将账户列表序列化为JSON
    final accountsJson = _cachedAccounts
        .map((account) => account.toJson())
        .toList();

    // 保存到配置并通知监听者
    await _configManager!.set(ConfigKeys.accounts, accountsJson);
    _accountsStreamController?.add(_cachedAccounts);
  }

  /// 获取所有账户列表
  ///
  /// 返回当前管理的所有账户的不可变列表。
  /// 返回的列表是不可变的，不能直接修改。
  ///
  /// 返回值：
  /// - `Future<List<Account>>`: 包含所有账户的不可变列表
  @override
  Future<List<Account>> getAccounts() async {
    await _ensureInitialized();
    // 返回不可变列表，防止外部直接修改缓存
    return List.unmodifiable(_cachedAccounts);
  }

  /// 获取当前选中的账户
  ///
  /// 从配置中读取当前选中的账户ID，并在缓存中查找对应的账户对象。
  ///
  /// 返回值：
  /// - `Future<Account?>`: 当前选中的账户，如果没有选中账户或账户不存在则返回 null
  @override
  Future<Account?> getSelectedAccount() async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    // 从配置中获取选中的账户ID
    final selectedId = _configManager!.get<String>(ConfigKeys.selectedAccount);
    if (selectedId == null) return null;

    // 在缓存中查找对应的账户
    try {
      return _cachedAccounts.firstWhere((account) => account.id == selectedId);
    } catch (e) {
      // 如果找不到账户，返回null而不是抛出异常
      return null;
    }
  }

  /// 选中指定账户
  ///
  /// 将指定的账户设置为当前选中状态，并更新其最后使用时间。
  /// 会发布选中账户变更事件。
  ///
  /// 参数：
  /// - `accountId` (String): 要选中的账户ID
  ///
  /// 异常：
  /// - `ArgumentError`: 当账户不存在时抛出
  @override
  Future<void> selectAccount(String accountId) async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    // 保存旧的选中账户ID，用于事件通知
    final oldAccountId = _configManager!.get<String>(ConfigKeys.selectedAccount);

    // 验证账户是否存在
    final accountExists = _cachedAccounts.any(
      (account) => account.id == accountId,
    );
    if (!accountExists) {
      throw ArgumentError('账户不存在: $accountId');
    }

    // 更新配置中的选中账户
    await _configManager!.set(ConfigKeys.selectedAccount, accountId);

    // 更新账户的最后使用时间
    final index = _cachedAccounts.indexWhere(
      (account) => account.id == accountId,
    );
    if (index != -1) {
      _cachedAccounts[index] = _cachedAccounts[index].copyWith(
        lastUsedAt: DateTime.now(),
      );
      await _saveAccounts();
    }

    // 发布选中账户变更事件
    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(
      SelectedAccountChangedEvent(
        newAccountId: accountId,
        oldAccountId: oldAccountId,
      ),
    );
  }

  /// 添加离线账户
  ///
  /// 创建一个新的离线模式账户。离线账户不需要在线验证，
  /// 仅使用用户名进行本地游戏。
  ///
  /// 参数：
  /// - `username` (String): 用户名，不能为空或仅包含空白字符
  ///
  /// 返回值：
  /// - `Future<Account>`: 新创建的账户对象
  ///
  /// 异常：
  /// - `ArgumentError`: 当用户名为空或仅包含空白字符时抛出
  @override
  Future<Account> addOfflineAccount(String username) async {
    await _ensureInitialized();

    // 验证用户名不为空
    if (username.trim().isEmpty) {
      throw ArgumentError('用户名不能为空');
    }

    // 创建新的离线账户
    final now = DateTime.now();
    final account = Account(
      id: _generateId(), // 生成唯一ID
      username: username.trim(), // 去除首尾空白
      type: AccountType.offline,
      createdAt: now,
      lastUsedAt: now,
    );

    // 添加到缓存并持久化
    _cachedAccounts.add(account);
    await _saveAccounts();

    // 发布账户添加事件
    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountAddedEvent(accountId: account.id));

    return account;
  }

  /// 添加微软账户
  ///
  /// 创建一个新的微软账户或更新已存在的微软账户。
  /// 如果相同UUID的微软账户已存在，将更新该账户的信息而不是创建新账户。
  ///
  /// 参数：
  /// - `username` (String): 微软账户的用户名
  /// - `uuid` (String): 微软账户的唯一标识符
  ///
  /// 返回值：
  /// - `Future<Account>`: 新创建或更新后的账户对象
  ///
  /// 异常：
  /// - `ArgumentError`: 当用户名或UUID为空时抛出
  @override
  Future<Account> addMicrosoftAccount(String username, String uuid) async {
    await _ensureInitialized();

    // 验证参数不为空
    if (username.trim().isEmpty) {
      throw ArgumentError('用户名不能为空');
    }
    if (uuid.trim().isEmpty) {
      throw ArgumentError('UUID不能为空');
    }

    // 检查是否已存在相同UUID的微软账户
    final existingAccountIndex = _cachedAccounts.indexWhere(
      (acc) => acc.uuid == uuid && acc.type == AccountType.microsoft,
    );

    if (existingAccountIndex != -1) {
      // 账户已存在，更新用户名和最后使用时间
      final existingAccount = _cachedAccounts[existingAccountIndex];
      final updatedAccount = existingAccount.copyWith(
        username: username.trim(),
        lastUsedAt: DateTime.now(),
      );
      _cachedAccounts[existingAccountIndex] = updatedAccount;
      await _saveAccounts();

      // 发布账户更新事件
      if (_eventBus == null) {
        _eventBus = EventBus.instance;
      }
      _eventBus!.publish(AccountUpdatedEvent(accountId: updatedAccount.id));
      return updatedAccount;
    }

    // 创建新的微软账户
    final now = DateTime.now();
    final account = Account(
      id: _generateId(),
      username: username.trim(),
      uuid: uuid,
      type: AccountType.microsoft,
      createdAt: now,
      lastUsedAt: now,
    );

    _cachedAccounts.add(account);
    await _saveAccounts();

    // 发布账户添加事件
    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountAddedEvent(accountId: account.id));

    return account;
  }

  /// 更新账户信息
  ///
  /// 更新指定账户的信息。账户ID必须存在。
  ///
  /// 参数：
  /// - `account` (Account): 包含更新信息的账户对象
  ///
  /// 异常：
  /// - `ArgumentError`: 当账户ID不存在时抛出
  @override
  Future<void> updateAccount(Account account) async {
    await _ensureInitialized();

    // 查找账户索引
    final index = _cachedAccounts.indexWhere((a) => a.id == account.id);
    if (index == -1) {
      throw ArgumentError('账户不存在: ${account.id}');
    }

    // 更新账户并保存
    _cachedAccounts[index] = account;
    await _saveAccounts();

    // 发布账户更新事件
    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountUpdatedEvent(accountId: account.id));
  }

  /// 删除账户
  ///
  /// 删除指定的账户。如果删除的是当前选中的账户，
  /// 会自动清除选中状态并发布相应的事件。
  ///
  /// 参数：
  /// - `accountId` (String): 要删除的账户ID
  ///
  /// 异常：
  /// - `ArgumentError`: 当账户不存在时抛出
  @override
  Future<void> removeAccount(String accountId) async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    // 查找账户索引
    final index = _cachedAccounts.indexWhere(
      (account) => account.id == accountId,
    );
    if (index == -1) {
      throw ArgumentError('账户不存在: $accountId');
    }

    // 如果删除的是当前选中的账户，清除选中状态
    final selectedId = _configManager!.get<String>(ConfigKeys.selectedAccount);
    if (selectedId == accountId) {
      await _configManager!.remove(ConfigKeys.selectedAccount);

      // 发布选中账户变更事件（新账户ID为null）
      if (_eventBus == null) {
        _eventBus = EventBus.instance;
      }
      _eventBus!.publish(
        SelectedAccountChangedEvent(
          newAccountId: null,
          oldAccountId: selectedId,
        ),
      );
    }

    // 从缓存中移除账户
    _cachedAccounts.removeAt(index);
    await _saveAccounts();

    // 发布账户删除事件
    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountDeletedEvent(accountId: accountId));
  }

  /// 获取账户变更事件流
  ///
  /// 返回一个广播流，用于监听账户列表的变更。
  /// 当账户被添加、更新或删除时，会向该流发送新的账户列表。
  ///
  /// 返回值：
  /// - `Stream<List<Account>>`: 账户列表变更事件流
  @override
  Stream<List<Account>> get accountsStream {
    // 延迟创建流控制器，支持在初始化前访问
    if (_accountsStreamController == null) {
      _accountsStreamController = StreamController<List<Account>>.broadcast();
    }
    return _accountsStreamController!.stream;
  }

  /// 生成唯一的账户ID
  ///
  /// 使用当前时间戳和账户数量组合生成唯一标识符。
  /// 格式：`{时间戳毫秒数}_{当前账户数量}`
  ///
  /// 返回值：
  /// - `String`: 唯一的账户ID字符串
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_cachedAccounts.length}';
  }

  /// 检查账户令牌是否有效
  ///
  /// 验证指定账户的访问令牌是否仍然有效。
  /// - 离线账户始终返回 true（不需要令牌验证）
  /// - 微软账户需要通过API验证令牌有效性
  ///
  /// 参数：
  /// - `account` (Account): 要检查的账户对象
  ///
  /// 返回值：
  /// - `Future<bool>`: 令牌有效返回 true，否则返回 false
  ///
  /// 示例：
  /// ```dart
  /// final isValid = await accountManager.isTokenValid(account);
  /// if (!isValid) {
  ///   print('令牌已失效，需要刷新');
  /// }
  /// ```
  Future<bool> isTokenValid(Account account) async {
    // 离线账户不需要令牌验证
    if (account.type == AccountType.offline) {
      return true;
    }

    // 检查访问令牌是否存在
    if (account.accessToken == null || account.accessToken!.isEmpty) {
      _logger.debug('Account ${account.id} has no access token');
      return false;
    }

    // 验证微软账户令牌
    if (account.type == AccountType.microsoft) {
      return await _validateMicrosoftToken(account.accessToken!);
    }

    return false;
  }

  /// 验证微软账户令牌有效性
  ///
  /// 通过调用 Minecraft API 来验证访问令牌是否仍然有效。
  /// 发送请求到 https://api.minecraftservices.com/minecraft/profile
  /// 并检查响应状态码。
  ///
  /// 参数：
  /// - `accessToken` (String): 要验证的访问令牌
  ///
  /// 返回值：
  /// - `Future<bool>`: 令牌有效返回 true，否则返回 false
  ///
  /// 状态码说明：
  /// - 200: 令牌有效
  /// - 401: 令牌无效或已过期
  /// - 其他: 验证失败
  Future<bool> _validateMicrosoftToken(String accessToken) async {
    try {
      // 构建请求URI
      final uri = Uri.parse('https://api.minecraftservices.com/minecraft/profile');

      // 创建HTTP客户端并发送请求
      final client = HttpClient();
      final request = await client.getUrl(uri);

      // 设置授权头
      request.headers.set('Authorization', 'Bearer $accessToken');

      // 获取响应
      final response = await request.close();
      final statusCode = response.statusCode;

      // 清理资源
      await response.drain();
      client.close();

      // 根据状态码判断令牌有效性
      if (statusCode == 200) {
        _logger.debug('Microsoft token validation succeeded');
        return true;
      } else if (statusCode == 401) {
        _logger.debug('Microsoft token validation failed: Unauthorized');
        return false;
      } else {
        _logger.debug('Microsoft token validation failed with status: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      // 记录验证过程中的错误
      _logger.error('Failed to validate Microsoft token', e, stackTrace);
      return false;
    }
  }

  /// 检查账户令牌是否即将过期
  ///
  /// 根据账户的最后使用时间判断令牌是否即将过期。
  /// 如果距离上次使用时间超过 [_tokenExpiryThreshold]（默认7天），
  /// 则认为令牌即将过期。
  ///
  /// 参数：
  /// - `account` (Account): 要检查的账户对象
  ///
  /// 返回值：
  /// - `bool`: 令牌即将过期返回 true，否则返回 false
  ///
  /// 注意：
  /// - 离线账户始终返回 false
  /// - 此方法仅基于时间判断，不进行实际令牌验证
  bool isTokenExpiringSoon(Account account) {
    // 离线账户不存在令牌过期问题
    if (account.type == AccountType.offline) {
      return false;
    }

    // 计算距离上次使用的时间
    final lastUsed = account.lastUsedAt;
    final now = DateTime.now();
    final timeSinceLastUse = now.difference(lastUsed);

    // 判断是否超过过期阈值
    return timeSinceLastUse > _tokenExpiryThreshold;
  }

  /// 刷新账户令牌
  ///
  /// 尝试刷新指定账户的访问令牌。
  /// - 离线账户直接返回 true（不需要刷新）
  /// - 微软账户会调用相应的刷新逻辑
  ///
  /// 参数：
  /// - `account` (Account): 要刷新令牌的账户对象
  ///
  /// 返回值：
  /// - `Future<bool>`: 刷新成功返回 true，否则返回 false
  ///
  /// 注意：
  /// 当前微软账户刷新逻辑为占位实现，实际需要实现OAuth刷新流程
  Future<bool> refreshToken(Account account) async {
    _logger.info('Refreshing token for account: ${account.id}');

    // 离线账户不需要刷新
    if (account.type == AccountType.offline) {
      return true;
    }

    // 刷新微软账户令牌
    if (account.type == AccountType.microsoft) {
      return await _refreshMicrosoftToken(account);
    }

    return false;
  }

  /// 刷新微软账户令牌
  ///
  /// 刷新微软账户的访问令牌。
  /// 注意：当前实现为占位方法，实际需要实现完整的OAuth刷新流程。
  ///
  /// 参数：
  /// - `account` (Account): 要刷新令牌的微软账户对象
  ///
  /// 返回值：
  /// - `Future<bool>`: 刷新成功返回 true，否则返回 false
  ///
  /// TODO: 实现完整的微软OAuth令牌刷新流程
  Future<bool> _refreshMicrosoftToken(Account account) async {
    try {
      _logger.debug('Attempting to refresh Microsoft token for ${account.id}');

      // TODO: 这里应该实现实际的令牌刷新逻辑
      // 当前仅作为占位实现，模拟刷新过程
      await Future.delayed(const Duration(seconds: 1));

      // 更新账户的最后使用时间
      final updatedAccount = account.copyWith(
        lastUsedAt: DateTime.now(),
      );
      await updateAccount(updatedAccount);

      // 发布账户更新事件
      _eventBus?.publish(AccountUpdatedEvent(accountId: account.id));
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh Microsoft token', e, stackTrace);
      return false;
    }
  }

  /// 验证所有账户的令牌有效性
  ///
  /// 遍历所有账户，检查每个账户的令牌是否有效。
  /// 返回一个映射表，键为账户ID，值为令牌是否有效。
  ///
  /// 返回值：
  /// - `Future<Map<String, bool>>`: 账户ID到令牌有效性的映射
  ///
  /// 示例：
  /// ```dart
  /// final results = await accountManager.validateAllTokens();
  /// results.forEach((id, isValid) {
  ///   print('账户 $id 令牌状态: ${isValid ? "有效" : "无效"}');
  /// });
  /// ```
  Future<Map<String, bool>> validateAllTokens() async {
    final results = <String, bool>{};

    // 遍历所有账户进行验证
    for (final account in _cachedAccounts) {
      results[account.id] = await isTokenValid(account);
    }

    return results;
  }

  /// 清理无效令牌的账户
  ///
  /// 删除所有令牌无效的在线账户（离线账户不会被删除）。
  /// 主要用于清理那些访问令牌丢失或无效的账户。
  ///
  /// 返回值：
  /// - `Future<int>`: 被删除的账户数量
  ///
  /// 清理条件：
  /// - 账户类型不是离线账户
  /// - 访问令牌为 null 或空字符串
  ///
  /// 示例：
  /// ```dart
  /// final removedCount = await accountManager.cleanupInvalidAccounts();
  /// print('已清理 $removedCount 个无效账户');
  /// ```
  Future<int> cleanupInvalidAccounts() async {
    int removedCount = 0;

    // 筛选出需要清理的账户
    // 条件：非离线账户且没有访问令牌
    final accountsToRemove = _cachedAccounts.where((account) {
      if (account.type == AccountType.offline) {
        return false; // 离线账户不参与清理
      }
      return account.accessToken == null || account.accessToken!.isEmpty;
    }).toList();

    // 逐个删除无效账户
    for (final account in accountsToRemove) {
      try {
        await removeAccount(account.id);
        removedCount++;
      } catch (e) {
        // 记录删除失败的错误，但继续处理其他账户
        _logger.error('Failed to remove account ${account.id}', e, null);
      }
    }

    // 记录清理结果
    if (removedCount > 0) {
      _logger.info('Removed $removedCount accounts with invalid tokens');
    }

    return removedCount;
  }

  /// 清理资源
  ///
  /// 释放账户管理器占用的资源，包括：
  /// - 关闭流控制器
  /// - 重置初始化状态
  /// - 清空配置管理器和事件总线引用
  ///
  /// 调用此方法后，账户管理器将需要重新初始化才能使用。
  /// 通常在应用程序关闭或需要重置账户管理器时调用。
  void dispose() {
    // 关闭流控制器并释放资源
    _accountsStreamController?.close();
    _accountsStreamController = null;

    // 重置初始化状态
    _isInitialized = false;

    // 清空引用
    _configManager = null;
    _eventBus = null;
  }
}