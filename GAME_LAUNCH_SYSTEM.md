# BAMCLauncher 游戏启动系统架构说明

## 系统概述

BAMCLauncher 游戏启动系统采用模块化设计，提供完整的 Minecraft 游戏启动能力，包括 Java 环境检测、JVM 参数优化、游戏进程管理和日志输出等核心功能。

## 核心组件

### 1. JavaManager

Java 环境管理类，负责检测和管理系统中的 Java 环境。

**主要功能：**
- 检测系统中所有可用的 Java 版本
- 根据游戏版本推荐合适的 Java 版本
- 验证 Java 版本兼容性
- 支持多版本 Java 检测和管理

**使用示例：**
```dart
final javaManager = JavaManager(platformAdapter: platformAdapter, logger: logger);
final javaVersions = await javaManager.detectAllJavaVersions();
final recommendedJava = await javaManager.findRecommendedJava('1.20.1');
```

### 2. LaunchArgumentsBuilder

启动参数构建器，负责构建 JVM 参数和游戏参数。

**主要功能：**
- 智能构建优化的 JVM 参数
- 根据游戏版本构建正确的游戏启动参数
- 构建完整的 classpath
- 支持不同平台的参数适配

**参数优化特性：**
- G1GC 垃圾收集器优化
- 内存分配优化（-Xms/-Xmx）
- 并行 GC 线程优化（根据 CPU 核心数）
- 平台特定优化（如 Windows D3D 支持）
- Forge/Fabric 兼容性参数

### 3. GameLauncher

游戏启动器核心类，实现 `IGameLauncher` 接口。

**主要功能：**
- Java 环境检测
- JVM 参数优化
- 游戏启动配置构建
- 进程启动和监控
- 实时日志输出

**核心方法：**
- `detectJava()` - 检测 Java 环境
- `optimizeJvmParameters()` - 优化 JVM 参数
- `buildLaunchConfig()` - 构建启动配置
- `launchGame()` - 启动游戏进程
- `getGameOutput()` - 获取游戏输出流
- `killProcess()` - 终止游戏进程

### 4. GameLaunchProcessManager

游戏启动流程管理器，提供完整的启动流程控制。

**主要功能：**
- 完整的启动状态管理
- 进度监控和状态通知
- 异常处理和恢复
- 进程生命周期管理

**启动流程：**
1. 初始化（initializing）
2. 检测 Java（detectingJava）
3. 检查版本（checkingVersion）
4. 构建配置（buildingConfig）
5. 启动游戏（launching）
6. 运行中（running）
7. 完成（finished）或失败（failed）

## 架构设计

```
┌─────────────────────────────────────────┐
│          GameLaunchProcessManager       │
│  ┌───────────────────────────────────┐  │
│  │           GameLauncher            │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │      JavaManager            │  │  │
│  │  └─────────────────────────────┘  │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │ LaunchArgumentsBuilder      │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## 使用示例

### 基础启动流程

```dart
final launcher = GameLauncher(
  platformAdapter: platformAdapter,
  logger: logger,
  versionManager: versionManager,
);

// 检测Java
final javaResult = await launcher.detectJava();

// 优化JVM参数
final jvmArgs = await launcher.optimizeJvmParameters('1.20.1', 4096);

// 构建启动配置
final config = await launcher.buildLaunchConfig(
  gameVersion: '1.20.1',
  username: 'Player',
  uuid: '00000000-0000-0000-0000-000000000000',
  accessToken: 'dummy_token',
  memoryMb: 4096,
);

// 启动游戏
final process = await launcher.launchGame(config);

// 监听游戏输出
launcher.getGameOutput().listen((output) {
  print('[Game] $output');
});

// 监听进程状态
launcher.getProcessSignals().listen((signal) {
  switch (signal) {
    case ProcessSignal.started:
      print('游戏启动成功');
      break;
    case ProcessSignal.exited:
      print('游戏已退出');
      break;
    case ProcessSignal.error:
      print('启动失败');
      break;
  }
});
```

### 使用流程管理器

```dart
final processManager = GameLaunchProcessManager(
  platformAdapter: platformAdapter,
  logger: logger,
  versionManager: versionManager,
);

// 监听启动状态
processManager.statusStream.listen((status) {
  print('启动状态: $status');
});

// 监听进度
processManager.progressStream.listen((progress) {
  print('启动进度: ${(progress * 100).toStringAsFixed(1)}%');
});

// 启动游戏
await processManager.launchGame(
  gameVersion: '1.20.1',
  username: 'Player',
  uuid: '00000000-0000-0000-0000-000000000000',
  accessToken: 'dummy_token',
  memoryMb: 4096,
);
```

## 版本兼容性

游戏启动系统支持以下 Minecraft 版本和模组加载器：

### Minecraft 版本支持
- 1.8.x - 1.20.x 正式版
- 快照版本
- 远古版本（通过版本继承机制）

### Java 版本推荐
- Minecraft 1.17+：Java 17
- Minecraft 1.16.x：Java 16
- Minecraft 1.15.x 及以下：Java 8

### 模组加载器支持
- Forge
- Fabric
- Quilt
- NeoForge

## 错误处理

系统提供完善的错误处理机制：

1. **Java 环境错误**：检测不到 Java 或版本不兼容时提供明确错误信息
2. **版本错误**：版本不存在或损坏时自动尝试修复
3. **启动错误**：进程启动失败时提供详细的错误日志
4. **进程异常**：实时监控进程状态，捕获崩溃信息

## 性能优化

1. **JVM 参数优化**：根据游戏版本和系统配置动态优化
2. **内存管理**：智能内存分配，避免内存不足或浪费
3. **并行处理**：利用多核 CPU 进行并行 GC
4. **日志优化**：分级日志系统，支持调试和生产环境

## 跨平台支持

系统支持以下平台：
- Windows (x86, x64)
- macOS (Intel, Apple Silicon)
- Linux (x86, x64, ARM)

每个平台都有专门的 Java 路径检测逻辑和平台特定的优化参数。
