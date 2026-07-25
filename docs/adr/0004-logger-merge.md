# 0004: 日志系统合并

## 状态

已接受

## 上下文

项目存在双日志系统并存：

1. `core/logger.dart`：`Logger` + `LogRecord` + `LogLevel` 枚举（基础设施层）
2. `system/log_manager.dart`：`LogManager` + `LogEntry` + 自己的 `LogLevel` 枚举

问题：
- 两套 `LogLevel` 枚举值域相同但类型不同
- `ServiceRegistry` 同时注册两者
- 调用方混用：`Logger.instance.info()` vs `LogManager.instance.writeLog()`
- `LogEntry` 与 `LogRecord` 字段几乎相同但结构不同

## 决策

以 `core/logger.dart` 为权威（基础设施层），合并 `system/log_manager.dart`。

### 变更内容

1. `LogManager` 移除自有 `LogEntry` / `LogLevel`，消费 `LogRecord` / `LogLevel`
2. `LogManager` 改为 `Logger` 的"文件轮转 + 诊断导出"装饰器
3. 构造函数改为 `LogManager(Logger logger)`
4. `ServiceRegistry` 移除 `LogManager` 独立注册，改为 `Logger` 的内部组件
5. 旧 `LogEntry` / `LogManager.instance` 调用方 `@Deprecated` 转发 1 版本

### 日志流向

```
应用代码 → Logger.info/warn/error
                ↓
        LogRecord（时间戳、级别、消息、数据）
                ↓
        ┌───────┼───────┐
        ↓       ↓       ↓
    控制台    文件    事件总线
              ↓
        LogManager（轮转、诊断导出）
```

## 替代方案

- **保留双系统**：各管各的，但增加维护负担
- **以 LogManager 为权威**：LogManager 在 system/ 层，不适合做基础设施

## 影响

### 正面
- 消除 `LogLevel` 类型冲突
- 统一日志入口
- 减少 ServiceRegistry 注册项

### 负面
- 需要更新所有 `LogManager.instance.writeLog()` 调用
- 过渡期有 `@Deprecated` 警告

## 参考

- `lib/src/core/logger.dart` - 日志基础设施（权威）
- `lib/src/system/log_manager.dart` - 日志管理器（将合并）
- `lib/src/di/service_registry.dart` - 注册表
