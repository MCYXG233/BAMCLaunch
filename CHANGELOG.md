# BAMCLauncher 发布说明与更新日志

## 版本 1.0.0 (2026-04-10)

### 🌟 主要特性

- ✅ **跨平台支持**：完整支持Windows、macOS、Linux三大桌面平台
- ✅ **多账户管理**：支持微软正版OAuth2登录、离线账户、第三方登录
- ✅ **版本管理**：全版本Minecraft支持，包括正式版、快照版、远古版
- ✅ **模组加载器**：自动安装Forge、Fabric、Quilt、NeoForge、LiteLoader
- ✅ **内容管理**：模组、资源包、光影一键搜索和安装
- ✅ **整合包支持**：兼容CurseForge、Modrinth、MMC、PCL、HMCL全格式
- ✅ **服务器管理**：服务器列表、一键加入、局域网联机功能
- ✅ **自定义界面**：清新方块风格UI，融合Minecraft和蔚蓝档案元素

### 🏗️ 核心架构

- 采用分层架构设计，实现高内聚低耦合
- 统一接口抽象，支持模块化扩展
- 全栈自研核心能力，确保代码可控性
- 完整的错误处理和日志系统

### 🎨 用户界面

- 左侧固定侧边栏 + 右侧主内容区的经典桌面布局
- 自定义标题栏，适配不同平台习惯
- 方块化设计风格，融合Minecraft元素
- 毛玻璃效果、柔和渐变、轻微阴影
- 流畅的动画效果和交互反馈

### 🔧 技术特性

- Flutter 3.22+跨平台框架
- Dart SDK 3.0+空安全支持
- 多线程分块下载引擎，支持断点续传
- 多镜像源自动切换和容错机制
- AES-256加密存储敏感信息
- 全局异常捕获和容错系统

### 📦 打包发布

- Windows：MSI安装包 + 便携版ZIP
- macOS：DMG安装包，支持Intel和Apple Silicon
- Linux：Deb、RPM、AppImage多格式支持
- 自动签名和公证（macOS）
- 自动构建和发布流水线

## 开发版本 (Unreleased)

### 🚀 新功能

- [ ] 插件系统支持
- [ ] 社区功能集成
- [ ] 联机大厅功能
- [ ] 多语言国际化支持
- [ ] 主题自定义功能

### 🔧 改进

- [ ] 性能优化
- [ ] 内存管理优化
- [ ] 下载速度优化
- [ ] UI响应速度优化

### 🐛 修复

- [ ] 已知bug修复
- [ ] 跨平台兼容性问题修复

---

## 版本号说明

采用语义化版本号：`MAJOR.MINOR.PATCH`

- **MAJOR**：不兼容的API变更
- **MINOR**：向后兼容的功能新增
- **PATCH**：向后兼容的问题修复

## 更新频率

- 小版本更新（MINOR/PATCH）：每月一次
- 大版本更新（MAJOR）：每季度或半年一次
- 紧急修复：随时发布

## 兼容性说明

- **最低系统要求**：
  - Windows：Windows 10 64位及以上
  - macOS：macOS 10.15 Catalina及以上
  - Linux：Ubuntu 20.04、Debian 11、Fedora 34及以上

- **推荐系统配置**：
  - CPU：Intel i5/Ryzen 5及以上
  - 内存：8GB及以上
  - 存储空间：至少10GB可用空间
  - 显卡：支持OpenGL 4.4及以上

## 迁移指南

### 从旧版本升级

1. 备份当前配置和游戏文件
2. 下载并安装最新版本
3. 启动器会自动检测并迁移配置
4. 如有问题，可手动导入备份的配置文件

### 数据备份

- 配置文件位置：
  - Windows：`%APPDATA%/.bamclauncher`
  - macOS：`~/Library/Application Support/BAMCLauncher`
  - Linux：`~/.config/bamclauncher`

- 推荐定期备份以下文件：
  - `config.json` - 主配置文件
  - `accounts.json` - 账户信息（已加密）
  - `servers.json` - 服务器列表
  - `versions/` - 版本配置目录

## 反馈与支持

如果您在使用过程中遇到问题或有建议，请通过以下方式反馈：

- **GitHub Issues**：https://github.com/yourusername/BAMCLauncher/issues
- **Discord社区**：邀请链接
- **邮件支持**：support@bamclauncher.com

---

**感谢您使用BAMCLauncher！** 🎮✨
