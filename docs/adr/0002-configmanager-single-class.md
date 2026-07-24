# 0002: ConfigManager 单类化（删除包装器）

## 状态

已接受

## 上下文

当前 ConfigManager 存在三层错位抽象：

```
IConfigManager (abstract)
    └── ConfigManager (单例包装器) ── 内含 final IConfigManager _impl = ConfigManagerImpl()
            └── ConfigManagerImpl (另一个单例)
```

问题：
1. `ConfigManager._internal()` 每次 `ConfigManager()` 工厂调用都 new 一个新 `ConfigManagerImpl()`，与 `ConfigManagerImpl._instance` 单例脱钩
2. `ServiceLocator.get<ConfigManager>()` 与 `get<ConfigManagerImpl>()` 拿到不同实例，状态不同步
3. 三层抽象增加认知负担，无实际价值

## 决策

采用**方案 A：删除包装器**，用 `@Deprecated` 标记过渡 1 个版本。

### 变更内容

1. 删除 `ConfigManager` 包装类（标记 `@Deprecated`）
2. `ConfigManagerImpl` 改名为 `ConfigManager`，移除自身 `_instance` 字段，构造函数改为公开
3. `ServiceRegistry` 只注册 `IConfigManager` → 新 `ConfigManager`
4. 旧 `ConfigManager.instance` / `ConfigManager()` 内部转发到 `ServiceRegistry.get<IConfigManager>()`，过渡期不崩

### 过渡策略

- 旧 `ConfigManager` 类标记 `@Deprecated('使用 ServiceRegistry.get<IConfigManager>() 替代')`
- 内部所有方法转发到新实现
- 下个版本删除旧类

## 替代方案

- **方案 B（修复委托）**：保留包装器，`_internal()` 改为复用 `ConfigManagerImpl.instance`。改动最小但保留不必要的抽象层。
- **方案 C（合并为单类 + ServiceLocator）**：保留三层但工厂内不 new。中等改动但未解决根本问题。

## 影响

### 正面
- 消除运行期 bug 风险（实例不同步）
- 减少认知负担（一层而非三层）
- 统一访问路径（`ServiceRegistry.get<IConfigManager>()`）

### 负面
- 20+ 文件需要更新 import
- 过渡期存在 `@Deprecated` 警告

## 参考

- `lib/src/config/config_manager.dart` - 包装器（将删除）
- `lib/src/config/config_manager_impl.dart` - 实现类（将改名）
- `lib/src/di/service_registry.dart` - 注册表
