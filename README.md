# BAMCLauncher

## 项目简介

BAMCLauncher 是一款**跨平台全栈自研**的 Minecraft 启动器，采用分层架构设计，融合了 Minecraft 的方块元素与蔚蓝档案的清新风格，为玩家提供流畅、稳定、功能丰富的游戏启动体验。

## 快速开始

### 系统要求
- **Windows**: Windows 10/11
- **macOS**: macOS 10.15+
- **Linux**: 主流发行版 (Ubuntu 20.04+, Fedora 34+, Arch Linux)

### 安装方法
1. 从 [GitHub Releases](https://github.com/MCYXG233/BAMC_Launcher/releases) 下载对应平台的安装包
2. 运行安装程序并按照提示完成安装
3. 启动 BAMCLauncher 开始使用

### 开发环境搭建
```bash
# 克隆仓库
git clone https://github.com/MCYXG233/BAMC_Launcher.git
cd BAMC_Launcher

# 安装依赖
flutter pub get

# 开发模式运行
flutter run -d windows  # 或 macos, linux

# 构建发布版本
flutter build windows
flutter build macos
flutter build linux
```

## 核心特性

### 🔧 全平台支持
- Windows、macOS、Linux 三大桌面平台全覆盖
- 统一的用户体验和功能实现

### 🎯 模块化架构
- 分层架构 + 接口抽象 + 插件化模块设计
- 高内聚低耦合，易于扩展和维护

### 🚀 全栈自研
- 核心能力完全自主研发，保证代码可控性与稳定性
- 避免过度依赖第三方库，提高系统可靠性

### 🎨 清新桌面风
- 融合 Minecraft 与蔚蓝档案的设计语言
- 纯桌面端原生交互逻辑，摒弃移动端交互

### 📋 功能全面
- **账户系统**: 微软正版登录、离线账户、第三方登录
- **版本管理**: MC全版本下载、模组加载器自动安装
- **内容管理**: 模组/资源包/光影一键搜索下载
- **整合包管理**: 全格式整合包支持
- **服务器与联机**: 服务器列表管理、一键加入
- **工具集**: 崩溃分析器、游戏日志查看器、存档管理
- **个性化**: 主题自定义、UI布局调整、多语言国际化

## 技术架构

### 整体分层架构

```
┌─────────────────────────────────────────────────┐
│  UI层（自研BAMC UI Kit）                        │
├─────────────────────────────────────────────────┤
│  业务层（模块化功能单元）                        │
├─────────────────────────────────────────────────┤
│  核心适配层（统一接口抽象）                      │
├─────────────────────────────────────────────────┤
│  原生桥接层（平台专属实现）                      │
└─────────────────────────────────────────────────┘
```

### 核心模块

| 模块 | 职责 | 接口 | 适配范围 |
| --- | --- | --- | --- |
| 平台适配 | 跨平台文件路径、系统调用、进程管理 | `IPlatformAdapter` | Win/Mac/Linux 全平台 |
| 账户认证 | 微软正版OAuth2、离线账户、第三方登录 | `IAuthenticator` | 所有登录方式统一入口 |
| 版本管理 | MC全版本检索、模组加载器安装、版本隔离 | `IVersionManager` | 正式版/快照版/远古版 |
| 下载引擎 | 多线程分块下载、断点续传、镜像源切换 | `IDownloadEngine` | 官方/BMCLAPI/MCBBS等 |
| 游戏启动 | Java环境检测/安装、JVM参数优化、进程监控 | `IGameLauncher` | 全平台启动流程统一 |
| 内容管理 | 模组/资源包/光影搜索、安装、升级 | `IContentManager` | CurseForge/Modrinth双源 |
| 整合包管理 | 全格式整合包导入导出、自动安装 | `IModpackManager` | 兼容全格式整合包 |
| 服务器管理 | 服务器列表管理、一键加入、模组同步 | `IServerManager` | 全平台联机能力统一 |
| 配置管理 | 全局配置、用户数据持久化、加密存储 | `IConfigManager` | 全平台配置路径统一 |
| 日志系统 | 分级日志、全局异常捕获、崩溃上报 | `ILogger` | 全平台日志规范统一 |

### 技术栈

- **基础框架**: Flutter 3.22+, Dart 3.0+
- **桌面工具**: `window_manager`, `flutter_distributor`
- **底层依赖**: `crypto`, `archive`, `sqflite_common_ffi`, `xml`
- **核心自研**: 统一接口适配层、微软OAuth2登录、多线程下载引擎、游戏启动核心

## UI设计

### 设计风格
- **配色系统**: 蔚蓝档案清新蓝 `#64B5F6` + MC草方块绿 `#7CB342`
- **布局结构**: 左侧固定侧边栏 + 右侧主内容区
- **组件库**: 自研BAMC UI Kit，桌面端原生交互
- **动效设计**: 柔和流畅，融合MC像素元素点缀

### 界面特点
- 全自定义标题栏，适配不同平台习惯
- 卡片式布局，充足留白，视觉清爽
- 支持右键菜单、键盘快捷键等桌面端交互
- 响应式设计，适配不同屏幕尺寸

## 跨平台适配

### 路径规范
- **Windows**: `%APPDATA%/.bamclauncher`
- **macOS**: `~/Library/Application Support/BAMCLauncher`
- **Linux**: `~/.config/bamclauncher` (遵循XDG规范)

### 系统能力
| 能力 | Windows | macOS | Linux |
| --- | --- | --- | --- |
| 窗口管理 | 自定义标题栏、托盘图标、开机自启 | 自定义标题栏、状态栏图标、开机自启 | 自定义标题栏、托盘图标 |
| 进程管理 | 进程优先级设置、进程守护、崩溃捕获 | 权限申请、进程监控、沙盒适配 | 执行权限自动配置、32位兼容 |
| 文件关联 | .bamc整合包文件关联、右键菜单 | 文件关联、访达扩展 | 桌面文件创建、mime类型关联 |

### 打包分发
- **Windows**: msi安装包 + 便携版zip
- **macOS**: dmg安装包，支持Intel/Apple Silicon
- **Linux**: deb/rpm/AppImage/flatpak

## 合规性

1. **Minecraft EULA**: 严格遵守，不分发MC核心文件
2. **微软OAuth2**: 严格遵循微软Azure API使用规范
3. **开源协议**: GPLv3
4. **第三方资源**: 所有资源均使用开源可商用资源

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. **Fork** 本仓库
2. **创建特性分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **打开 Pull Request**

## 许可证

本项目采用 [GPLv3](LICENSE) 许可证。

## 联系方式

- **GitHub**: [MCYXG233/BAMC_Launcher](https://github.com/MCYXG233/BAMC_Launcher)
- **邮箱**: mcxyg233@example.com

---

**BAMCLauncher - 为 Minecraft 玩家打造的专业启动器** 🎮