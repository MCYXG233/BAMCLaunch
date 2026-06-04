# BAMCLauncher - 我的世界启动器

一个基于 Flutter 开发的 Minecraft 启动器，支持版本管理、账户管理、模组下载等功能。

## 特性

- 🎮 支持多个 Minecraft 版本的安装和管理
- 👤 支持离线和正版账户
- 📦 内置模组和资源包下载功能
- ⚙️ 自定义启动参数和内存分配
- 🎨 现代美观的界面设计（蔚蓝档案风格）
- 🚀 快速启动和流畅的用户体验
- 🔄 支持自动更新检测
- 🖼️ 支持自定义背景图片
- 🎬 支持视频背景（MP4、AVI、MOV、MKV 格式）
- 🎭 皮肤管理和预览功能
- 💾 备份和恢复系统
- 📊 游戏时长统计
- 🎵 NBS 音乐播放
- 🌐 Terracotta 联机功能
- 📁 实例管理和自动检测

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart 3.x
- **状态管理**: 内置状态管理 + 事件总线
- **UI 组件**: 自定义组件库（蔚蓝档案风格）
- **网络请求**: http
- **加密**: crypto, encrypt
- **文件操作**: path, path_provider, file_picker
- **平台特定**: window_manager (仅桌面平台)
- **视频播放**: video_player（Windows 平台默认支持 MP4，如需支持 WebM 请使用 media_kit）
- **图表**: fl_chart
- **归档**: archive

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
│   ├── background_config.dart    # 背景配置
│   ├── theme_config.dart         # 主题配置
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
├── auth/                         # 认证系统
│   ├── auth_manager.dart         # 认证管理器
│   └── microsoft_auth.dart      # 微软认证
├── download/                     # 下载管理
│   ├── download_engine.dart      # 下载引擎
│   ├── download_task.dart        # 下载任务
│   └── download_source.dart      # 下载源管理
├── game/                         # 游戏相关
│   ├── java/                     # Java 检测和管理
│   └── launcher/                 # 游戏启动器
├── mod/                          # 模组管理
│   ├── mod_manager.dart          # 模组管理器
│   └── mod_config.dart           # 模组配置
├── backup/                       # 备份系统
│   └── backup_manager.dart       # 备份管理器
├── ui/                           # UI 层
│   ├── theme/                    # 主题系统
│   │   ├── colors.dart           # 颜色定义
│   │   ├── app_theme.dart        # 主题配置
│   │   ├── background_manager.dart # 背景管理器
│   │   └── typography.dart       # 字体样式
│   ├── components/               # 通用组件
│   │   ├── ba_dialog.dart        # 对话框组件
│   │   ├── ba_buttons.dart       # 按钮组件
│   │   ├── ba_authlib_login_dialog.dart # 外置登录对话框
│   │   ├── ba_mod_manager_dialog.dart # 模组管理对话框
│   │   ├── ba_background_selector.dart # 背景选择器
│   │   └── ba_notification.dart  # 通知组件
│   └── pages/                    # 页面组件
│       ├── account_page.dart     # 账户页面（含皮肤管理）
│       ├── ba_settings_page.dart # 设置页面
│       ├── ba_game_log_page.dart # 游戏日志页面
│       └── ba_mod_manager_page.dart # 模组管理页面
└── index.dart                    # 模块导出
```

## 功能说明

### 背景系统

支持多种背景类型：
- **经典背景**: 默认的蔚蓝档案风格背景
- **纯色背景**: 自定义纯色背景
- **渐变背景**: 渐变色背景
- **图片背景**: 支持 JPG、PNG 等常见图片格式
- **视频背景**: 支持 MP4、AVI、MOV、MKV 格式（使用 video_player）
- **模糊背景**: 半透明模糊效果

**WebM 格式支持说明**：
当前使用 video_player，在 Windows 平台对 WebM 格式支持有限。如需完整支持 WebM，建议使用 media_kit 替代 video_player。
相关代码中有注释说明如何切换到 media_kit。

所有背景都支持透明度调节。

### 皮肤管理

- 支持 Minecraft 皮肤预览（3D 预览）
- 支持自定义皮肤上传
- 支持皮肤模型选择（经典、苗条）
- 支持披风显示
- 皮肤功能集成在账户页面

### 模组管理

- 模组管理通过对话框实现，不占用整个页面
- 支持模组启用/禁用
- 支持模组排序
- 支持模组冲突检测
- 支持模组多选操作

### 账户系统

- 支持离线账户
- 支持微软账户（使用设备代码流）
- 支持外置登录
- 支持账户切换
- 支持皮肤管理

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
- 为核心代码添加中文注释

## 许可证

本项目采用 GNU General Public License v3.0 (GPLv3) 许可证 - 详见 [LICENSE](LICENSE) 文件

## 版权声明

Copyright (C) 2025 BAMCLaunch 项目

本程序是自由软件：您可以重新分发和/或修改它，遵循由自由软件基金会发布的 GNU 通用公共许可证的条款，包括许可证的第3版，或（由您选择）任何更新版本。

本程序是为了希望它有用而分发的，但不带任何担保；甚至没有对适销性或特定用途的适用性的暗示担保。更多细节请参阅 GNU 通用公共许可证。

您应该已经收到了 GNU 通用公共许可证的副本连同本程序。如果没有，请参见 <https://www.gnu.org/licenses/>.

## 致谢

- Minecraft 官方 API 文档
- BMCLAPI 提供的加速镜像服务
- Flutter 和 Dart 社区
- HMCL、PCL2、SJMCL、BakaXL 等启动器项目的参考
- media_kit 提供的视频播放支持（如需 WebM 支持）
- 蔚蓝档案提供的设计灵感
