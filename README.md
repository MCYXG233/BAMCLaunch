# BAMCLauncher - 我的世界启动器

一个基于 Flutter 开发的 Minecraft 启动器，支持版本管理、账户管理、模组下载等功能。

## 特性

- 🎮 支持多个 Minecraft 版本的安装和管理
- 👤 支持离线和正版账户
- 📦 内置模组和资源包下载功能
- ⚙️ 自定义启动参数和内存分配
- 🎨 现代美观的界面设计
- 🚀 快速启动和流畅的用户体验
- 🔄 支持自动更新检测

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart 3.x
- **状态管理**: 内置状态管理 + 事件总线
- **UI 组件**: 自定义组件库
- **网络请求**: http
- **加密**: crypto
- **文件操作**: path, path_provider
- **平台特定**: window_manager (仅桌面平台)

## 安装和运行

### 前置要求

- Flutter SDK 3.0 或更高版本
- Dart SDK 3.0 或更高版本
- 支持的平台: Windows, macOS, Linux

### 运行项目

1. 克隆仓库
```bash
git clone <repository-url>
cd BAMCLaunch
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 构建发布版本

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 开发环境搭建

### 环境配置

1. 确保已安装 Flutter SDK: [Flutter 官方下载](https://flutter.dev/docs/get-started/install)
2. 运行 `flutter doctor` 检查开发环境
3. 根据平台安装相应的工具链

### 项目结构

```
lib/
├── main.dart                      # 应用入口
├── config/                       # 配置管理
│   ├── config_manager.dart       # 配置管理器
│   ├── config_manager_impl.dart  # 配置管理器实现
│   └── config_keys.dart          # 配置键定义
├── core/                         # 核心功能
│   ├── logger.dart               # 日志系统
│   └── error_handler.dart        # 错误处理
├── event/                        # 事件系统
│   ├── event.dart                # 事件定义
│   └── event_bus.dart            # 事件总线
├── platform/                     # 平台适配
│   ├── platform_adapter.dart     # 平台适配器
│   └── platform_adapter_factory.dart
├── version/                      # 版本管理
│   ├── version_manager.dart      # 版本管理器
│   ├── install_version_task.dart # 版本安装任务
│   └── models.dart               # 版本数据模型
├── account/                      # 账户管理
│   ├── account_manager.dart      # 账户管理器
│   ├── account.dart              # 账户模型
│   └── account_widgets.dart      # 账户相关组件
├── download/                     # 下载管理
│   ├── download_engine.dart      # 下载引擎
│   ├── download_task.dart        # 下载任务
│   └── download_source.dart      # 下载源管理
├── game/                         # 游戏相关
│   ├── java/                     # Java 检测和管理
│   └── launcher/                 # 游戏启动器
├── ui/                           # UI 层
│   ├── theme/                    # 主题系统
│   ├── components/               # 通用组件
│   └── pages/                    # 页面组件
└── index.dart                    # 模块导出
```

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

### 代码规范

- 运行 `dart format .` 格式化代码
- 运行 `flutter analyze` 检查代码质量
- 确保所有测试通过 (`flutter test`)
- 遵循 Flutter 和 Dart 的最佳实践

## 许可证

本项目采用 GNU General Public License v3.0 (GPLv3) 许可证 - 详见 [LICENSE](LICENSE) 文件

## 版权声明

Copyright (C) 2025 BAMCLaunch 项目

本程序是自由软件：您可以重新分发和/或修改它，遵循由自由软件基金会发布的 GNU 通用公共许可证的条款，包括许可证的第3版，或（由您选择）任何更新版本。

本程序是为了希望它有用而分发的，但不带任何担保；甚至没有对适销性或特定用途的适用性的暗示担保。更多细节请参阅 GNU 通用公共许可证。

您应该已经收到了 GNU 通用公共许可证的副本连同本程序。如果没有，请参见 &lt;https://www.gnu.org/licenses/&gt;。

## 致谢

- Minecraft 官方 API 文档
- BMCLAPI 提供的加速镜像服务
- Flutter 和 Dart 社区
