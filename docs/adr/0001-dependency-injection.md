# 0001: 依赖注入容器设计

## 状态

已接受

## 上下文

项目初期使用单例模式管理核心服务（如 `Logger`、`EventBus`、`AccountManager` 等），导致：

1. **测试困难**：单例模式使得单元测试难以进行依赖替换和模拟
2. **耦合度高**：模块直接依赖具体实现而非抽象接口
3. **初始化顺序问题**：单例之间的依赖关系导致初始化顺序难以控制
4. **可维护性差**：难以追踪和管理依赖关系

## 决策

引入依赖注入容器 `ServiceLocator`，统一管理所有核心服务，并逐步将所有单例重构为通过依赖注入获取实例。

### 核心原则

1. **面向接口编程**：所有服务应依赖抽象接口而非具体实现
2. **构造函数注入**：依赖应通过构造函数传入，而非在类内部创建
3. **延迟初始化**：服务应在首次使用时创建，而非应用启动时
4. **单例管理**：容器负责管理服务的生命周期

### 服务注册规范

```dart
// 注册单例（已创建的实例）
locator.registerSingleton<Logger>(Logger());

// 注册延迟服务（首次获取时创建）
locator.register<IConfigManager>((locator) => ConfigManagerImpl());

// 注册工厂（每次获取都创建新实例）
locator.registerFactory<ApiClient>((locator) => ApiClient());
```

### 服务获取规范

```dart
// 在类的构造函数中获取依赖
class MyService {
  final Logger _logger;
  
  MyService({
    Logger? logger,
  }) : _logger = logger ?? ServiceLocator.instance.get<Logger>();
}
```

## 影响

### 正面影响

1. **可测试性提升**：可以轻松替换依赖进行单元测试
2. **耦合度降低**：模块依赖抽象接口，实现可以独立变化
3. **初始化控制**：可以精确控制服务的初始化顺序
4. **可维护性提升**：依赖关系清晰，便于追踪和管理

### 负面影响

1. **学习曲线**：开发人员需要理解依赖注入的概念和使用方式
2. **迁移成本**：需要修改大量现有代码以使用新的注入方式
3. **性能开销**：服务获取有轻微的性能开销（可忽略）

## 实现步骤

1. 创建 `ServiceLocator` 容器类
2. 创建服务接口（如 `IConfigManager`、`IPlatformAdapter`）
3. 重构核心服务以接受构造函数注入
4. 创建 `ServiceRegistry` 统一注册所有服务
5. 更新所有使用单例的地方改为通过容器获取

## 参考

- `lib/src/di/service_locator.dart` - 依赖注入容器实现
- `lib/src/platform/platform_adapter.dart` - 平台适配器接口
- `lib/src/config/config_manager.dart` - 配置管理器接口