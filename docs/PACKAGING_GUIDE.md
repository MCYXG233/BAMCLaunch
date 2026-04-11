# BAMCLauncher 打包和分发指南

## 概述

本指南介绍如何使用 flutter_distributor 配置和执行全平台打包，包括 Windows、macOS 和 Linux。

## 环境要求

### 通用要求
- Flutter 3.22+
- Dart SDK 3.0+
- flutter_distributor 0.3.0+

### Windows 要求
- Visual Studio 2022（带 Windows 桌面开发工作负载）
- WiX Toolset v3.11+（用于生成 MSI 安装包）
- 代码签名证书（可选但推荐）

### macOS 要求
- macOS 11+
- Xcode 13+
- 苹果开发者账号（用于签名和公证）
- 代码签名证书

### Linux 要求
- Ubuntu 20.04+ 或其他支持的发行版
- dpkg-dev（用于生成 deb 包）
- rpmbuild（用于生成 rpm 包）
- AppImageKit（用于生成 AppImage）

## 安装依赖

```bash
# 安装 flutter_distributor
dart pub global activate flutter_distributor

# 安装必要的系统依赖（Ubuntu/Debian）
sudo apt-get update
sudo apt-get install -y dpkg-dev rpm libarchive-tools

# 安装 AppImageKit（可选，用于生成 AppImage）
sudo apt-get install -y appimagetool
```

## 配置环境变量

创建 `.env` 文件并配置以下环境变量：

```bash
# Windows 签名配置
WINDOWS_CERTIFICATE_FILE=/path/to/certificate.pfx
WINDOWS_CERTIFICATE_PASSWORD=your_certificate_password

# macOS 签名和公证配置
MACOS_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
APPLE_ID=your_apple_id@example.com
APPLE_ID_PASSWORD=your_app_specific_password
APPLE_TEAM_ID=your_team_id
```

## 打包命令

### Windows 打包

```bash
# 生成 MSI 安装包
flutter_distributor package --platform windows --targets msi

# 生成 ZIP 便携版
flutter_distributor package --platform windows --targets zip
```

### macOS 打包

```bash
# 生成 DMG 安装包（带签名和公证）
flutter_distributor package --platform macos --targets dmg
```

### Linux 打包

```bash
# 生成 deb 包
flutter_distributor package --platform linux --targets deb

# 生成 rpm 包
flutter_distributor package --platform linux --targets rpm

# 生成 AppImage
flutter_distributor package --platform linux --targets appimage

# 生成所有 Linux 包
flutter_distributor package --platform linux --targets deb,rpm,appimage
```

### 全平台打包

```bash
# 打包所有平台和格式
flutter_distributor package --platform windows,macos,linux --targets msi,zip,dmg,deb,rpm,appimage
```

## 输出位置

打包后的文件将位于 `dist/` 目录下：

- Windows: `dist/windows/`
- macOS: `dist/macos/`
- Linux: `dist/linux/`

## 签名和公证说明

### Windows 签名
- 使用 Authenticode 证书对 MSI 安装包进行签名
- 配置文件中的 `signing` 部分用于指定证书信息
- 建议使用时间戳服务器确保签名长期有效

### macOS 签名和公证
- 使用 Developer ID 证书进行代码签名
- 通过 Apple 的公证服务验证应用
- 需要有效的苹果开发者账号
- 公证过程自动完成，无需手动操作

## 自定义配置

可以通过修改 `distribute.yaml` 文件来自定义打包配置：

- 修改应用名称、版本、描述等信息
- 配置文件关联（.bamc 整合包）
- 自定义安装路径和快捷方式
- 调整签名和公证参数

## CI/CD 集成

可以在 GitHub Actions 或其他 CI/CD 系统中集成打包流程：

```yaml
# GitHub Actions 示例
name: Build and Package

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [windows-latest, macos-latest, ubuntu-latest]
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
      
      - run: flutter pub get
      
      - name: Build and Package
        env:
          WINDOWS_CERTIFICATE_FILE: ${{ secrets.WINDOWS_CERTIFICATE_FILE }}
          WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
          MACOS_SIGNING_IDENTITY: ${{ secrets.MACOS_SIGNING_IDENTITY }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_ID_PASSWORD: ${{ secrets.APPLE_ID_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          dart pub global activate flutter_distributor
          flutter_distributor package --platform ${{ matrix.os == 'windows-latest' && 'windows' || matrix.os == 'macos-latest' && 'macos' || 'linux' }}
```

## 故障排除

### Windows 打包问题
- 确保 WiX Toolset 正确安装并添加到 PATH
- 检查证书文件路径和密码是否正确
- 验证 Visual Studio 工作负载是否完整

### macOS 打包问题
- 确保 Xcode 命令行工具已安装：`xcode-select --install`
- 验证开发者证书是否有效
- 检查 Apple ID 应用专用密码是否正确配置

### Linux 打包问题
- 确保安装了所有必要的依赖包
- 检查 AppImageKit 是否正确安装
- 验证桌面文件路径是否正确

## 版本控制

每次发布新版本时，需要更新以下文件：

1. `pubspec.yaml` 中的版本号
2. `distribute.yaml` 中的版本配置
3. 所有平台的构建配置文件

## 分发渠道

打包完成后，可以通过以下渠道分发：

- GitHub Releases
- 官方网站下载页面
- 第三方软件分发平台
- 包管理器（如 Snapcraft、Flathub）

## 安全注意事项

- 始终对发布的安装包进行代码签名
- macOS 应用必须通过苹果公证
- 保持签名证书的安全存储
- 使用环境变量或密钥管理系统存储敏感信息
