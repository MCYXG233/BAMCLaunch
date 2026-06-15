# BAMCLaunch 架构设计文档

> 本文档记录 BAMCLaunch Minecraft 启动器的完整架构设计决策。

## 目录

- [1. 项目概述](#1-项目概述)
- [2. 核心领域模型](#2-核心领域模型)
- [3. 架构原则](#3-架构原则)
- [4. 目录结构](#4-目录结构)
- [5. 依赖注入](#5-依赖注入)
- [6. 事件系统](#6-事件系统)
- [7. 错误处理](#7-错误处理)
- [8. 日志规范](#8-日志规范)
- [9. 状态管理](#9-状态管理)
- [10. 平台适配](#10-平台适配)
- [11. 便携模式](#11-便携模式)
- [12. 核心功能](#12-核心功能)
- [13. 测试策略](#13-测试策略)
- [14. CI/CD](#14-cicd)

---

## 1. 项目概述

**BAMCLaunch** 是一个基于 Flutter 开发的跨平台 Minecraft 启动器，支持 Windows、macOS、Linux。

### 1.1 核心特性

- 多版本 Minecraft 安装和管理
- 微软账户/离线账户认证
- Mod、资源包、Shader 下载和管理
- 模组兼容性检查
- 蔚蓝档案风格的现代 UI

### 1.2 技术栈

| 组件 | 技术选型 |
|------|---------|
| 框架 | Flutter 3.x |
| 语言 | Dart 3.x |
| 状态管理 | Riverpod |
| 依赖注入 | ServiceLocator + Provider |
| 日志 | 自定义 LogManager |
| CI/CD | GitHub Actions |

---

## 2. 核心领域模型

### 2.1 术语定义

| 术语 | 定义 | 避免使用 |
|------|------|---------|
| **Account** | Minecraft 玩家账户，包含认证凭证 | user, profile |
| **Instance** | 配置好的 Minecraft 游戏环境 | game instance, configuration |
| **Resource** | Instance 使用的 Mod、资源包、Shader | addon, plugin |
| **Launcher** | 负责启动 Minecraft 的核心组件 | - |

### 2.2 领域关系

```
Account ──1:N──> Instance (可选绑定)
Instance ──1:N──> Resource
Launcher ──使用──> Account + Instance
ServiceLocator ──管理──> 所有核心服务
```

---

## 3. 架构原则

### 3.1 核心原则

1. **面向接口编程**：所有服务依赖抽象接口，而非具体实现
2. **依赖注入**：通过构造函数或 Provider 注入依赖
3. **单向依赖**：依赖方向必须单向，禁止循环依赖
4. **单一职责**：每个模块/类只负责一件事
5. **测试友好**：所有业务逻辑必须可单元测试

### 3.2 依赖方向

```
shared/  <--  core/  <--  features/
   ^           ^           ^
   |           |           |
  共享类型    基础设施     功能模块
```

---

## 4. 目录结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用根组件
├── shared/                   # 跨模块共享
│   ├── models/              # 领域模型
│   │   ├── account.dart
│   │   ├── instance.dart
│   │   ├── mod.dart
│   │   └── download_task.dart
│   ├── constants/           # 常量定义
│   │   ├── minecraft_versions.dart
│   │   └── api_endpoints.dart
│   └── utils/               # 工具函数
│       └── file_utils.dart
├── core/                    # 基础设施层
│   ├── di/                 # 依赖注入
│   │   ├── service_locator.dart
│   │   └── service_registry.dart
│   ├── error/              # 错误处理
│   │   ├── app_exception.dart
│   │   ├── network_exception.dart
│   │   ├── auth_exception.dart
│   │   └── file_system_exception.dart
│   ├── event/              # 事件系统
│   │   ├── event_bus.dart
│   │   └── events/
│   ├── logging/            # 日志系统
│   │   ├── log_manager.dart
│   │   └── log_sanitizer.dart
│   └── platform/           # 平台适配
│       ├── platform_adapter.dart
│       └── platform_adapter_impl.dart
└── features/               # 功能模块
    ├── auth/
    │   ├── services/
    │   ├── models/
    │   ├── viewmodels/
    │   └── views/
    ├── download/
    ├── instance/
    ├── mod/
    ├── resource_center/
    └── settings/
```

### 4.1 模块内组织

每个功能模块包含：

```
features/<module>/
├── services/           # 业务逻辑服务
├── models/             # 私有数据模型
├── viewmodels/         # UI 状态管理
├── views/              # UI 组件
└── index.dart          # Barrel export
```

---

## 5. 依赖注入

### 5.1 ServiceLocator 设计

**ServiceLocator 不是单例**，而是通过 Provider 注入到 Widget 树中。

```dart
// 创建并注册
final locator = ServiceLocator();
locator.register<IConfigManager>((loc) => ConfigManagerImpl());
locator.register<AuthManager>((loc) => AuthManager(
  configManager: loc.get<IConfigManager>(),
));

// 注入到应用
runApp(
  Provider<ServiceLocator>.value(
    value: locator,
    child: const BAMCApp(),
  ),
);

// 获取服务
final authManager = Provider.of<ServiceLocator>(context).get<AuthManager>();
```

### 5.2 服务注册顺序

1. `IPlatformAdapter`
2. `IConfigManager`
3. `Logger`
4. `EventBus`
5. `AccountManager`
6. `AuthManager`
7. `InstanceManager`
8. `DownloadEngine`
9. `GameLauncher`

### 5.3 测试隔离

```dart
// 每个测试创建独立的 ServiceLocator
setUp(() {
  testLocator = ServiceLocator();
  testLocator.register<AuthManager>(MockAuthManager());
});

tearDown(() {
  testLocator = null;
});
```

---

## 6. 事件系统

### 6.1 事件分类

| 类型 | 示例 | 实现 |
|------|------|------|
| **全局事件** | 主题切换、用户登出 | GlobalEventBus (单例) |
| **局部事件** | 下载进度、列表刷新 | Riverpod StateNotifier |

### 6.2 GlobalEventBus 规则

```dart
// 必须返回 StreamSubscription
StreamSubscription<T> on<T>(void Function(T event) handler) {
  // ...
}

// 使用 EventBusMixin 自动清理
mixin EventBusMixin<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  
  void listenToEvent<TEvent>(void Function(TEvent) handler) {
    final sub = GlobalEventBus().on<TEvent>(handler);
    _subscriptions.add(sub);
  }
  
  @override
  void dispose() {
    for (final sub in _subscriptions) sub.cancel();
    super.dispose();
  }
}
```

### 6.3 禁止事项

- 禁止使用全局 EventBus 发送 UI 绑定的局部事件
- 禁止在 EventBus 中发送涉及 Widget 生命周期的回调

---

## 7. 错误处理

### 7.1 异常层次结构

```dart
sealed class AppException implements Exception {
  String get userFriendlyMessage;
  String get debugDescription;
}

final class NetworkException extends AppException {
  final int? statusCode;
  final Uri? uri;
}

final class AuthException extends AppException {
  final AuthErrorType type;
}

final class FileSystemException extends AppException {
  final String path;
  final FileSystemErrorCode code;
}

final class GameLaunchException extends AppException {
  final String? javaPath;
  final int? exitCode;
}
```

### 7.2 错误展示策略

| 层级 | 内容 | 用途 |
|------|------|------|
| `userFriendlyMessage` | "网络连接失败，请检查网络" | UI 显示 |
| `debugDescription` | "NetworkException: GET https://... timeout" | 日志记录 |

### 7.3 失败严重性分级

| 级别 | 示例 | 处理策略 |
|------|------|----------|
| Low | 后台刷新失败 | 静默失败 + 记录日志 |
| Medium | 用户操作失败 | 显示 SnackBar |
| High | 配置保存失败 | 弹窗 + 重试选项 |
| Critical | 游戏启动失败 | 诊断界面 |
| Auth | 令牌过期 | 自动弹出登录 |

### 7.4 Result 类型

对于可预期的失败，使用 `Result<T, E>` 而非异常：

```dart
sealed class Result<T, E> {
  factory Result.success(T value) = Success;
  factory Result.failure(E error) = Failure;
}

Future<Result<String, FileSystemException>> readFile(String path) async {
  // ...
}
```

---

## 8. 日志规范

### 8.1 日志级别

| 级别 | 用途 | 生产默认 |
|------|------|---------|
| DEBUG | 开发调试 | ❌ 输出 |
| INFO | 关键里程碑 | ✅ 输出 |
| WARN | 潜在问题 | ✅ 输出 |
| ERROR | 可恢复错误 | ✅ 输出 |
| FATAL | 不可恢复崩溃 | ✅ 输出 |

### 8.2 日志格式

```
[2025-01-15T10:23:45.123Z] [INFO] [AuthManager] Token refreshed
```

### 8.3 输出目标

| 级别 | 控制台 | 文件 | 远程上报 |
|------|--------|------|----------|
| DEBUG | 仅开发 | ❌ | ❌ |
| INFO | 仅开发 | ✅ | ❌ |
| ERROR | ✅ | ✅ | 10% 采样 |
| FATAL | ✅ | ✅ | 100% |

### 8.4 日志轮转

- 单文件最大：10 MB
- 保留文件数：5 个
- 格式：`app.log`, `app.log.1`, ..., `app.log.4`

### 8.5 敏感信息脱敏

| 类型 | 脱敏方式 | 示例 |
|------|----------|------|
| Token | `<redacted>` | `refresh_token: <redacted>` |
| UUID | 保留前 8 位 | `a1b2c3d4***` |
| 路径 | 用户名替换为 `~` | `C:\Users\John\...` → `~\...` |

---

## 9. 状态管理

### 9.1 选型：Riverpod

| 特性 | Provider | Riverpod |
|------|----------|----------|
| 依赖 Context | ✅ | ❌ |
| 编译时安全 | ❌ | ✅ |
| 可组合性 | 一般 | ✅ |

### 9.2 状态分层

```
┌─────────────────────────────────────┐
│  Global App State (Riverpod)        │
│  - Theme, Account, Download Queue   │
├─────────────────────────────────────┤
│  Page/Component State               │
│  - Selected Instance, Dialog        │
├─────────────────────────────────────┤
│  Persisted State (Hive/SharedPrefs) │
│  - User Preferences                │
└─────────────────────────────────────┘
```

### 9.3 Provider 示例

```dart
// 全局状态
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

// 派生状态
final blurStrengthProvider = Provider<double>((ref) {
  final theme = ref.watch(themeProvider);
  return theme == AppTheme.baStyle ? 12.0 : 8.0;
});

// 消费
final blur = ref.watch(blurStrengthProvider);
```

### 9.4 持久化策略

- 状态变化时自动保存到 `SharedPreferences` / `Hive`
- 应用启动时读取持久化值初始化 Provider

---

## 10. 平台适配

### 10.1 PlatformAdapter 接口

```dart
abstract class IPlatformAdapter {
  String getApplicationSupportDirectory();
  String getDefaultGameDirectory();
  String getLauncherDirectory();
  Future<bool> canAccessDirectory(String path);
  Future<void> openDirectory(String path);
  Future<void> openUrl(Uri url);
}
```

### 10.2 实现类

| 平台 | 类名 |
|------|------|
| Windows | `WindowsPlatformAdapter` |
| macOS | `MacOSPlatformAdapter` |
| Linux | `LinuxPlatformAdapter` |

### 10.3 路径规范

| 平台 | 游戏目录 | 应用数据 |
|------|----------|----------|
| Windows | `%APPDATA%\.minecraft` | `%LOCALAPPDATA%\BAMCLaunch` |
| macOS | `~/Library/Application Support/minecraft` | `~/Library/Application Support/BAMCLaunch` |
| Linux | `~/.minecraft` | `~/.local/share/BAMCLaunch` |

---

## 11. 便携模式

### 11.1 检测机制

1. 检查可执行文件同级目录是否存在 `portable.txt`
2. macOS：向上查找 `.app` 包，取其父目录
3. 其他平台：使用可执行文件所在目录

### 11.2 优先级

```
便携模式标记 (portable.txt)
    ↓ 存在
便携数据目录 (<launcher>/.minecraft)
    ↓ 不存在
平台标准路径 (如 ~/.minecraft)
```

### 11.3 Linux 沙箱检测

```dart
bool get isSandboxed {
  return Platform.environment.containsKey('FLATPAK_ID') ||
         Platform.environment.containsKey('SNAP');
}
```

**降级策略**：
1. 尝试 `~/.minecraft`
2. 失败则使用沙箱内目录
3. 绝不平滑降级到安装模式

---

## 12. 核心功能

### 12.1 账户认证

**令牌刷新策略**：
- 惰性刷新：API 调用前检查
- 启动预检：1 小时内过期则刷新
- 启动游戏前：10 分钟内过期则强制刷新

**多账户模型**：
- 全局激活账户（只能一个）
- 实例绑定账户（可选覆盖）
- 选择优先级：实例绑定 > 全局激活 > 首个有效 > 提示用户

### 12.2 下载引擎

**断点续传**：
- HTTP Range 请求
- 元数据文件存储：URL、大小、Etag、已下载字节
- 完成后验证 SHA-1/SHA-256

**多源策略**：
- 主源：官方 CDN
- 备用：BMCLAPI 镜像
- 自动切换：5xx、超时、连接错误

**并发控制**：
- 默认 3-5 个并发
- 可配置 1-20
- 优先级队列：游戏核心 > Mod

### 12.3 Mod 兼容性

**版本过滤**：
- 浏览时按 Loader 和版本过滤
- 手动添加后标记警告

**冲突检测**：
- 已知冲突数据库（OptiFine vs Sodium 等）
- 不自动禁用，仅警告

**依赖检查**：
- 启动前验证所有依赖存在
- 缺失时提示下载

---

## 13. 测试策略

### 13.1 测试金字塔

```
        ┌───────┐
        │  UI   │   10%
       ┌┴───────┴┐
       │ Integration│  20%
      ┌┴──────────┴┐
      │    Unit     │  70%
     ┌┴────────────┴┐
```

### 13.2 测试优先级

| 优先级 | 目标 | 原因 |
|--------|------|------|
| P0 | AuthManager, DownloadEngine | 核心功能 |
| P1 | InstanceManager, Version parsing | 文件操作 |
| P2 | Error handling, Mod compatibility | 诊断、复杂 |
| P3 | UI rendering | 关键路径 |

### 13.3 Mock 策略

- 使用 `mocktail` 进行 Mock
- Fake 实现：文件系统、时钟、HTTP 客户端
- 通过 DI 注入 Fake

### 13.4 CI 测试

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - flutter test --coverage
      - flutter test integration_test
```

---

## 14. CI/CD

### 14.1 流水线触发

| 事件 | 动作 |
|------|------|
| PR | flutter analyze + 单元测试 |
| Push main | + 集成测试 + 开发构建 |
| Tag v* | + 生产构建 + Release |

### 14.2 多平台构建

```yaml
strategy:
  matrix:
    os: [windows-latest, macos-latest, ubuntu-latest]
```

### 14.3 版本管理

- 基于 Git 标签（`v1.2.3`）
- CI 自动同步 `pubspec.yaml`

### 14.4 构建产物

| 平台 | 格式 |
|------|------|
| Windows | `.exe` 安装程序 / `.zip` |
| macOS | `.dmg` |
| Linux | `.AppImage` / `.deb` |

### 14.5 代码签名

| 平台 | 方案 |
|------|------|
| Windows | EV 代码签名证书 |
| macOS | Developer ID + 公证 |
| Linux | 可选 GPG |

---

## 附录

### A. 参考资料

- [Flutter 官方文档](https://flutter.dev/docs)
- [Riverpod 文档](https://riverpod.dev/)
- [Minecraft 官方 API](https://wiki.vg/Mojang_API)
- [BMCLAPI 镜像](https://bmclapidoc.bangbang93.com/)

### B. 术语表

| 术语 | 定义 |
|------|------|
| Instance | 一个配置好的 Minecraft 游戏环境 |
| Account | Minecraft 玩家账户 |
| Resource | Mod、资源包、Shader |
| Loader | Fabric / Forge / NeoForge |
| Modpack | 包含 Mod 和配置的整合包 |

### C. 文档变更历史

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2025-01-15 | 1.0 | 初始版本 |

---

*本文档由 grill-with-docs 流程生成*
