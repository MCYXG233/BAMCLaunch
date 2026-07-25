# BAMCLaunch 测试规范

本目录按业务域组织测试，与 `lib/src/` 结构镜像。

## 目录结构

```
test/
├── core/                # 核心基础设施（安全关键）
│   └── safe_archive_extractor_test.dart
├── instance/            # 实例管理
│   ├── instance_path_service_test.dart
│   ├── instance_cloner_test.dart
│   └── path_resolver_test.dart
├── game/                # 游戏启动
│   ├── launcher/
│   │   └── game_launcher_test.dart    # Models
│   ├── game_output_monitor_test.dart
│   ├── game_error_detector_test.dart
│   └── game_ready_detector_test.dart
├── account/             # 账户管理（待迁移）
├── config/              # 配置管理（待迁移）
├── di/                  # DI 容器
│   └── service_locator_test.dart
├── event/               # 事件总线（待迁移）
└── ui/                  # UI 层（待迁移）
```

## 命名规范

- 测试文件：`{被测类}_test.dart`，与 `lib/src/.../{类名}.dart` 一一对应
- 测试 group：被测类名（如 `SafeArchiveExtractor - 路径安全`）
- 测试用例：行为描述（如 `应拒绝 ../ 攻击`）

## 编写原则

### 1. 单一职责

每个 test 只验证一件事。复杂场景拆成多个小 test。

### 2. 隔离性

- 每个测试独立创建被测对象，避免共享状态
- 使用 `setUp` / `tearDown` 清理临时目录、订阅、监听器
- 单例类（`ThemeManager`、`AccountStore` 等）必须通过
  `resetForTesting()` 或 `setConfigForTesting()` 重置

### 3. 临时文件

```dart
late Directory tempDir;

setUp(() {
  tempDir = Directory.systemTemp.createTempSync('test_xxx_');
});

tearDown(() {
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
});
```

### 4. 避免副作用

避免调用真实 IO（`SharedPreferences`、`window_manager`、`process` 等）。
若必须调用，要么 mock（`SharedPreferences.setMockInitialValues`），要么测试前用
`overrideWith` 注入测试实例。

### 5. 安全关键模块

项目 Hard Constraint：
- `SafeArchiveExtractor`：防 Zip Slip、绝对路径、Zip 炸弹
- `MinecraftPathResolver`：防硬编码路径，支持配置驱动

这些模块必须 100% 覆盖正向与攻击用例。

## 运行测试

```bash
# 全部测试
flutter test

# 单独测试文件
flutter test test/core/safe_archive_extractor_test.dart

# 按 group 过滤
flutter test --plain-name "GameErrorDetector"

# 串行运行（避免单例污染问题排查时使用）
flutter test --concurrency=1
```

## 已知约束

- `ThemeManager` 是单例，Riverpod `ChangeNotifierProvider` 在
  `ProviderContainer.dispose()` 时会调用其 `dispose()`。
  测试须在 `setUp` 中调用 `ThemeManager.resetForTesting()` 清理。
- 部分测试共享 `flutter test` runner，单例污染可能跨文件传播。
  如遇 "ThemeManager was used after being disposed" 类错误，
  检查是否有测试遗漏 reset 调用。

## 新增测试 checklist

- [ ] 文件位于正确业务域目录
- [ ] 命名遵循 `{类名}_test.dart`
- [ ] group 名称为类名或功能分组
- [ ] 每个 test 独立，可单独运行
- [ ] 临时资源在 tearDown 清理
- [ ] 单例 reset 在 setUp 处理
- [ ] 至少覆盖正向 + 1 个边界/异常用例