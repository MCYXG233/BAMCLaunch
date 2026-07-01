import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';

/// 资源收藏管理器
///
/// 管理用户收藏的资源列表，使用 ConfigManager 进行持久化存储。
///
/// ## 使用方式
///
/// ```dart
/// // 获取单例
/// final manager = FavoriteManager.instance;
///
/// // 初始化
/// await manager.initialize();
///
/// // 收藏一个资源
/// await manager.addFavorite('resource-123');
///
/// // 取消收藏
/// await manager.removeFavorite('resource-123');
///
/// // 是否已收藏
/// final isFavorite = manager.isFavorite('resource-123');
///
/// // 获取全部收藏ID
/// final favorites = manager.favorites;
/// ```
///
/// ## 数据结构
///
/// 存储格式：`List<String>` - 资源ID列表
/// 存储键：[ConfigKeys.favoriteResources]
class FavoriteManager {
  /// 单例实例
  static FavoriteManager? _instance;

  /// 内部存储的收藏列表
  List<String> _favorites = [];

  /// 是否已初始化
  bool _isInitialized = false;

  /// 日志记录器
  final Logger _logger = Logger();

  /// 获取单例实例
  static FavoriteManager get instance {
    return ServiceLocator.instance.tryGet<FavoriteManager>() ??
        (_instance ??= FavoriteManager._internal());
  }

  /// 工厂构造函数
  factory FavoriteManager() => instance;

  FavoriteManager._internal();

  /// 重置单例（用于测试）
  static void reset() {
    _instance = null;
  }

  /// 初始化收藏管理器
  ///
  /// 从配置文件加载收藏列表。
  Future<void> initialize() async {
    final config = ConfigManager.instance;
    final isConfigInitialized = config.getBool('config_initialized');
    if (isConfigInitialized == null || !isConfigInitialized) {
      await config.initialize();
    }

    final saved = config.get<List<dynamic>>(ConfigKeys.favoriteResources);
    if (saved != null) {
      _favorites = [];
      for (final item in saved) {
        if (item is String) {
          _favorites.add(item);
        }
      }
    } else {
      _favorites = [];
    }
    _isInitialized = true;
  }

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取所有收藏的资源ID
  List<String> get favorites => List.unmodifiable(_favorites);

  /// 获取收藏数量
  int get count => _favorites.length;

  /// 检查资源是否已收藏
  ///
  /// [resourceId] 资源ID
  bool isFavorite(String resourceId) {
    return _favorites.contains(resourceId);
  }

  /// 添加收藏
  ///
  /// [resourceId] 资源ID
  /// [resourceName] 资源名称（用于日志）
  ///
  /// 返回 `true` 表示新增收藏，`false` 表示已在收藏列表中
  Future<bool> addFavorite(String resourceId, {String? resourceName}) async {
    if (_favorites.contains(resourceId)) {
      return false;
    }

    _favorites.add(resourceId);
    try {
      await ConfigManager.instance.set<List<String>>(
        ConfigKeys.favoriteResources,
        List.from(_favorites),
      );
      await ConfigManager.instance.save();
    } catch (e) {
      _logger.error('Failed to persist favorite add: $e');
      // 回滚内存状态
      _favorites.remove(resourceId);
      return false;
    }
    return true;
  }

  /// 移除收藏
  ///
  /// [resourceId] 资源ID
  ///
  /// 返回 `true` 表示已移除，`false` 表示资源不在收藏列表中
  Future<bool> removeFavorite(String resourceId) async {
    if (!_favorites.contains(resourceId)) {
      return false;
    }

    _favorites.remove(resourceId);
    try {
      await ConfigManager.instance.set<List<String>>(
        ConfigKeys.favoriteResources,
        List.from(_favorites),
      );
      await ConfigManager.instance.save();
    } catch (e) {
      _logger.error('Failed to persist favorite remove: $e');
      // 回滚内存状态
      _favorites.add(resourceId);
      return false;
    }
    return true;
  }

  /// 切换收藏状态
  ///
  /// 已收藏则取消收藏，未收藏则添加收藏。
  ///
  /// 返回切换后的收藏状态（`true` 表示现在已收藏）
  Future<bool> toggleFavorite(String resourceId, {String? resourceName}) async {
    if (isFavorite(resourceId)) {
      await removeFavorite(resourceId);
      return false;
    } else {
      await addFavorite(resourceId, resourceName: resourceName);
      return true;
    }
  }

  /// 清空所有收藏
  Future<void> clearAllFavorites() async {
    final previousFavorites = List<String>.from(_favorites);
    _favorites.clear();
    try {
      await ConfigManager.instance.remove(ConfigKeys.favoriteResources);
      await ConfigManager.instance.save();
    } catch (e) {
      _logger.error('Failed to clear favorites: $e');
      // 回滚内存状态
      _favorites = previousFavorites;
    }
  }

  /// 批量添加收藏
  Future<void> addFavorites(List<String> resourceIds) async {
    final added = <String>[];
    for (final id in resourceIds) {
      if (!_favorites.contains(id)) {
        _favorites.add(id);
        added.add(id);
      }
    }
    if (added.isEmpty) return;
    try {
      await ConfigManager.instance.set<List<String>>(
        ConfigKeys.favoriteResources,
        List.from(_favorites),
      );
      await ConfigManager.instance.save();
    } catch (e) {
      _logger.error('Failed to persist batch favorites: $e');
      // 回滚内存状态
      for (final id in added) {
        _favorites.remove(id);
      }
    }
  }
}
