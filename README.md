<div align="center">

# BAMCLauncher

### 一个基于 Flutter 的开源 Minecraft 启动器

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](#-平台支持)

一款拥有蔚蓝档案风格 UI 的跨平台 Minecraft 启动器，提供完整的版本管理、账户认证、模组整合、整合包导入与多镜像下载能力。

[功能特性](#-功能特性) · [快速开始](#-快速开始) · [构建发布](#-构建发布版本) · [项目结构](#-项目结构) · [贡献](#-贡献指南) · [许可证](#-许可证)

</div>

---

## 📑 目录

- [✨ 功能特性](#-功能特性)
- [🖼️ 界面预览](#-界面预览)
- [🛠️ 技术栈](#-技术栈)
- [📋 系统要求](#-系统要求)
- [🚀 快速开始](#-快速开始)
- [📦 构建发布版本](#-构建发布版本)
- [📁 项目结构](#-项目结构)
- [📖 功能详解](#-功能详解)
- [🧪 测试](#-测试)
- [🤝 贡献指南](#-贡献指南)
- [📜 许可证](#-许可证)
- [🙏 致谢](#-致谢)

---

## ✨ 功能特性

### 🎮 核心功能

- **多版本管理** — 完整支持原版、Forge、Fabric、Quilt、OptiFine 等加载器
- **多账户系统** — 离线账户、微软正版（OAuth 设备代码流）、Authlib 外置登录
- **实例隔离** — 每个实例独立管理版本、模组、设置和存档
- **多镜像加速** — 内置 BMCLAPI 等镜像源，自动故障切换，提升下载速度
- **资源中心** — 集成 Modrinth、CurseForge API 浏览和下载模组
- **整合包支持** — 支持 Modrinth/CurseForge 整合包导入与导出

### 🎨 界面与体验

- **蔚蓝档案风格 UI** — 自研主题系统，圆角、阴影、动画一应俱全
- **多类型背景** — 经典、纯色、渐变、图片、视频背景，支持透明度调节
- **视频背景** — 支持 MP4 / AVI / MOV / MKV 格式（详见 [WebM 支持说明](#-webm-支持说明)）
- **3D 皮肤预览** — 内置皮肤 3D 预览，支持经典和苗条模型
- **披风管理** — 上传、自定义披风显示
- **NBS 音乐播放** — 内置 NBS 格式音乐播放器
- **流畅动画** — Lottie + simple_animations 提供的过渡与启动动画

### 🔧 高级功能

- **下载引擎** — HTTP Range 断点续传、SHA1/SHA256 校验、多源并发（3-5 路）
- **备份与恢复** — 手动 + 自动备份，标签化管理
- **游戏时长统计** — 基于 fl_chart 的可视化统计
- **Terracotta 联机** — 内置 Terracotta 联机服务管理
- **诊断与修复** — 一键诊断 Java、网络、文件系统问题
- **插件系统** — 扩展管理器支持第三方扩展
- **游戏内 HUD** — FPS 与内存监控悬浮窗
- **跨平台** — Windows / macOS / Linux 全平台支持

---

## 🖼️ 界面预览

> 📌 截图占位区 — 建议在此处放置启动器主界面、设置页、皮肤预览、下载页等截图

| 主页面 | 启动动画 | 皮肤预览 |
|:---:|:---:|:---:|
| _待补充_ | _待补充_ | _待补充_ |

| 设置页 | 模组管理 | 整合包导入 |
|:---:|:---:|:---:|
| _待补充_ | _待补充_ | _待补充_ |

---

## 🛠️ 技术栈

### 框架与语言

| 项目 | 版本/说明 |
|---|---|
| Flutter | 3.x（Material 3） |
| Dart | 3.11.4+ |
| 最低 SDK | `^3.11.4` |

### 状态管理

| 库 | 用途 |
|---|---|
| `flutter_riverpod` ^2.4.10 | 全局应用状态、Provider 组合 |
| `provider` ^6.1.2 | 旧组件兼容、ServiceLocator 注入 |

### 核心依赖

| 类别 | 库 |
|---|---|
| **网络** | `http`, `url_launcher` |
| **加密** | `crypto`, `encrypt` |
| **数据存储** | `sqflite_common_ffi`, `shared_preferences` |
| **文件/路径** | `path`, `path_provider`, `file_picker` |
| **平台** | `window_manager`（桌面窗口控制） |
| **媒体播放** | `video_player`（视频背景）、`audioplayers`（NBS 音乐） |
| **解析/归档** | `xml`, `archive` |
| **可视化** | `fl_chart` |
| **动画** | `lottie`, `simple_animations` |
| **图标** | `cupertino_icons` |

### 开发与测试

- `flutter_lints` ^6.0.0
- `flutter_test`（单元 + Widget 测试）
- 持续集成：GitHub Actions（多平台矩阵构建）

---

## 📋 系统要求

### 运行环境

- **Flutter SDK** ≥ 3.0
- **Dart SDK** ≥ 3.0
- **支持的操作系统**：
  - 🪟 Windows 10/11（x64）
  - 🍎 macOS 11.0+
  - 🐧 Linux（Ubuntu 20.04+ / 其他主流发行版）

### 目标平台

- ✅ Windows（推荐，主要开发与测试平台）
- ✅ macOS
- ✅ Linux（注意：Flatpak/Snap 沙箱环境的兼容性已做适配）

---

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/your-username/BAMCLaunch.git
cd BAMCLaunch
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 检查开发环境

```bash
flutter doctor
```

### 4. 运行应用

```bash
# 默认平台运行
flutter run

# 指定平台运行
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

---

## 📦 构建发布版本

### 标准构建

```bash
# Windows（生成 .exe）
flutter build windows --release

# macOS（生成 .app）
flutter build macos --release

# Linux（生成可执行文件）
flutter build linux --release
```

### 便携版（Portable Mode）

在可执行文件同级目录创建 `portable.txt` 即可启用便携模式：

```text
{BAMCLaunch.exe 同级目录}/portable.txt
```

启用后，游戏数据将保存到 `{可执行文件目录}/.minecraft`，无需安装到系统。

> 💡 **macOS 注意**：`portable.txt` 应放在 `.app` 所在的**目录**中（因为 `.app` 是只读 bundle）。

---

## 📁 项目结构

```
lib/
├── main.dart                          # 应用入口
├── shared/                            # 跨模块共享类型
│   ├── models/                        # Account, Instance, Mod, DownloadTask
│   ├── constants/                     # 游戏版本、URL 常量
│   └── utils/                         # 通用工具方法
│
├── core/                              # 基础设施层
│   ├── di/                            # ServiceLocator 依赖注入
│   ├── error/                         # 异常体系（AppException, NetworkException 等）
│   ├── logger.dart                    # 日志系统
│   ├── network_client.dart            # HTTP 客户端封装
│   ├── retry_helper.dart              # 重试工具
│   └── privacy_manager.dart           # 隐私管理
│
├── event/                             # 事件系统
│   ├── event.dart                     # 事件定义
│   └── event_bus.dart                 # 全局事件总线
│
├── features/                          # 业务功能模块
│   ├── auth/                          # 认证（Microsoft / Authlib / Offline）
│   ├── account/                       # 账户管理
│   ├── instance/                      # 实例管理（导入、导出、检测）
│   ├── version/                       # Minecraft 版本管理
│   ├── download/                      # 多源并发下载引擎
│   ├── game/                          # Java 检测与游戏启动
│   │   ├── java/                      # Java 下载与版本管理
│   │   └── launcher/                  # 游戏启动器
│   ├── mod/                           # 模组管理（冲突检测、依赖解析）
│   ├── modpack/                       # 整合包导入/导出
│   ├── resource_center/               # 资源中心（Modrinth / CurseForge API）
│   ├── backup/                        # 备份与恢复
│   ├── statistics/                    # 游戏时长统计
│   ├── game_hud/                      # 游戏内 FPS/内存悬浮窗
│   ├── diagnostic/                    # 诊断与自动修复
│   ├── extension/                     # 插件/扩展
│   ├── updater/                       # 自动更新
│   ├── i18n/                          # 多语言
│   ├── platform/                      # 平台适配（Windows/macOS/Linux）
│   └── ui/                            # UI 层
│       ├── theme/                     # 主题、颜色、字体、背景管理
│       ├── components/                # BA 风格通用组件
│       ├── dialogs/                   # 弹窗
│       ├── layout/                    # 布局管理
│       └── pages/                     # 页面
│
└── providers/                         # Riverpod 状态提供者
```

### 模块依赖规则

```
shared ← core ← features
```

- **shared**：纯 Dart 模型、常量、工具
- **core**：基础设施（DI、错误、日志、网络、平台）
- **features**：业务模块，禁止相互循环依赖
- 每个模块通过 `index.dart` 统一 barrel export

---

## 📖 功能详解

### 🎨 背景系统

| 背景类型 | 说明 |
|---|---|
| 经典背景 | 蔚蓝档案风格默认背景 |
| 纯色背景 | 自定义纯色填充 |
| 渐变背景 | 多色渐变 |
| 图片背景 | 支持 JPG / PNG |
| 视频背景 | MP4 / AVI / MOV / MKV |
| 模糊背景 | 半透明模糊效果 |

所有背景都支持透明度调节。

#### ⚠️ WebM 支持说明

`video_player` 在 Windows 平台对 WebM 格式支持有限。如需完整 WebM 支持，可将 `video_player` 替换为 [`media_kit`](https://github.com/media-kit/media-kit)。代码中已有切换注释。

### 👤 账户系统

- ✅ 离线账户（本地生成 UUID）
- ✅ 微软正版账户（OAuth 设备代码流 + Token 自动刷新）
- ✅ Authlib 外置登录
- ✅ 多账户切换、皮肤管理集成

**Token 刷新策略**：

| 时机 | 策略 |
|---|---|
| 启动时 | 过期 < 1 小时则刷新 |
| 启动游戏前 | 过期 < 10 分钟强制刷新 |
| API 401 响应 | 先刷新，失败则要求重新登录 |

### 🎭 皮肤管理

- 3D 实时预览
- 经典 / 苗条模型切换
- 自定义皮肤上传
- 披风显示与自定义上传

### 🧩 模组管理

- 启用 / 禁用模组
- 模组排序
- 冲突检测（OptiFine vs Sodium 等已知冲突）
- 多选批量操作
- 依赖解析

### 📦 整合包

- 支持 Modrinth / CurseForge 整合包导入
- 整合包导出（包含配置、模组、版本信息）
- 自动解析依赖关系

### 🌐 Terracotta 联机

- 内置 Terracotta 联机服务管理
- 局域网联机与好友联机

### 🔍 诊断与修复

- Java 环境检测与自动修复
- 网络连通性诊断
- 文件系统权限检查
- 日志分析与崩溃分析
- 一键修复常见问题

### 🎵 NBS 音乐播放

内置 NBS（Note Block Studio）格式音乐播放器，可在启动器内播放背景音乐。

### 💾 备份系统

- 手动备份
- 自动定时备份
- 标签化管理
- 一键恢复

### 📊 游戏统计

- 单次 / 总游戏时长
- 按日 / 周 / 月可视化统计（fl_chart）
- 按实例分别统计

---

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行指定测试
flutter test test/account_manager_test.dart

# 生成覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

测试覆盖核心服务（AuthManager、DownloadEngine、InstanceManager、VersionManager 等）和关键 UI 路径。

---

## 🤝 贡献指南

欢迎贡献代码、报告 Bug 或提出新功能建议！🎉

### 开发流程

1. **Fork** 本仓库
2. 创建功能分支
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. 提交更改
   ```bash
   git commit -m 'feat: Add some AmazingFeature'
   ```
4. 推送到分支
   ```bash
   git push origin feature/AmazingFeature
   ```
5. 打开 **Pull Request**

### 提交规范

推荐使用 [Conventional Commits](https://www.conventionalcommits.org/)：

| 类型 | 说明 |
|---|---|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `style` | 代码格式（无逻辑变更） |
| `refactor` | 重构 |
| `test` | 测试 |
| `chore` | 构建 / 工具链 |

### 代码规范

提交前请确保：

```bash
# 1. 格式化代码
dart format .

# 2. 静态分析
flutter analyze

# 3. 运行测试
flutter test
```

- 遵循 [Effective Dart](https://dart.dev/effective-dart) 风格指南
- 为核心逻辑添加中文注释
- 新功能同步补充测试用例
- PR 中说明变更原因与测试方式

### 🐛 报告问题

发现 Bug？[提交 Issue](../../issues) 并附上：

- 操作系统与版本
- Flutter / Dart 版本
- 复现步骤
- 预期行为 vs 实际行为
- 关键日志（诊断页可一键导出）

---

## 📜 许可证

本项目基于 **GNU General Public License v3.0 (GPLv3)** 开源 — 详见 [LICENSE](LICENSE) 文件。

```
Copyright (C) 2025 BAMCLaunch Project

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

---

## 🙏 致谢

### 项目灵感

- 🎮 [Minecraft](https://www.minecraft.net/) — Mojang Studios
- 🎨 [蔚蓝档案 (Blue Archive)](https://bluearchive.nexon.com/) — UI 设计灵感来源

### 镜像与 API

- 🚀 [BMCLAPI](https://bmclapi.bangbang93.com/) — 国内下载镜像加速
- 📚 [Modrinth API](https://docs.modrinth.com/) — 开源模组平台
- 📚 [CurseForge API](https://docs.curseforge.com/) — 模组资源平台
- 🔐 [Mojang / Xbox Live API](https://wiki.vg/Microsoft_Authentication_Scheme) — 正版认证

### 参考项目

感谢以下启动器项目的开源贡献，为本项目提供了重要参考：

- [HMCL](https://github.com/huanghongxun/HMCL) — 跨平台 Java Minecraft 启动器
- [PCL2](https://github.com/Hex-Dragon/PCL2) — Windows 平台启动器
- [BakaXL](https://github.com/BakaXL-Launcher/BakaXL) — 轻量级启动器
- [SJMCL](https://github.com/UNIkeEN/SJMCL) — 上海交通大学 Minecraft 启动器

### 社区与依赖

- 💙 [Flutter](https://flutter.dev) 与 [Dart](https://dart.dev) 团队
- 📦 所有开源依赖的作者们
- 🎵 [media_kit](https://github.com/media-kit/media-kit) — 视频播放备选方案

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！**

Made with ❤️ by BAMCLaunch Contributors

</div>
