# BAMCLauncher 部署和打包指南

## 一、开发环境设置

### 1. 系统要求

- **Windows**：Windows 10/11 64位
- **macOS**：macOS 10.15+（Catalina或更高版本）
- **Linux**：Ubuntu 18.04+、Debian 10+、Fedora 32+、Arch Linux等

### 2. Flutter环境安装

```bash
# 安装Flutter（建议使用Flutter 3.22+）
git clone https://github.com/flutter/flutter.git
cd flutter
git checkout 3.22.0  # 或其他稳定版本

# 添加到PATH
export PATH="$PATH:`pwd`/bin"

# 验证安装
flutter doctor
```

### 3. 开发工具

- **编辑器**：Visual Studio Code 或 Android Studio
- **插件**：Flutter插件、Dart插件
- **构建工具**：
  - Windows：Visual Studio 2022（带桌面开发工作负载）
  - macOS：Xcode 13+
  - Linux：CMake、Ninja、GCC/G++

## 二、项目配置

### 1. 依赖安装

```bash
# 安装项目依赖
flutter pub get

# 更新依赖
flutter pub upgrade
```

### 2. 构建配置

#### pubspec.yaml 配置

```yaml
name: bamclauncher
version: 1.0.0+1
description: BAMCLauncher - A cross-platform Minecraft launcher

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  window_manager: ^0.3.0
  crypto: ^3.0.3
  archive: ^3.4.10
  sqflite_common_ffi: ^2.3.3+1
  xml: ^6.5.0
  ffi: ^2.1.0
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
```

### 3. 代码生成

```bash
# 生成JSON序列化代码
flutter pub run build_runner build

# 监听模式（开发时使用）
flutter pub run build_runner watch
```

## 三、Windows平台构建

### 1. 开发构建

```bash
# 调试模式
flutter run -d windows

# 发布模式
flutter run -d windows --release
```

### 2. 构建安装包

#### 方法一：使用flutter_distributor（推荐）

```bash
# 安装flutter_distributor
dart pub global activate flutter_distributor

# 构建msi安装包
flutter_distributor package --platform windows --targets msi

# 构建zip便携版
flutter_distributor package --platform windows --targets zip
```

#### 方法二：手动构建

```bash
# 构建release版本
flutter build windows --release

# 构建结果位置：build/windows/x64/runner/Release/

# 创建安装包（需要Inno Setup）
# 参考配置文件：windows/installer.iss
```

### 3. Inno Setup配置示例

```ini
[Setup]
AppName=BAMCLauncher
AppVersion=1.0.0
AppPublisher=BAMCLauncher Team
AppPublisherURL=https://bamclauncher.com
DefaultDirName={autopf}\BAMCLauncher
DefaultGroupName=BAMCLauncher
OutputDir=output
OutputBaseFilename=BAMCLauncher-Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\BAMCLauncher"; Filename: "{app}\BAMCLauncher.exe"
Name: "{commondesktop}\BAMCLauncher"; Filename: "{app}\BAMCLauncher.exe"

[Run]
Filename: "{app}\BAMCLauncher.exe"; Description: "Launch BAMCLauncher"; Flags: nowait postinstall skipifsilent
```

## 四、macOS平台构建

### 1. 开发构建

```bash
# 调试模式
flutter run -d macos

# 发布模式
flutter run -d macos --release
```

### 2. 构建dmg安装包

#### 方法一：使用flutter_distributor

```bash
flutter_distributor package --platform macos --targets dmg
```

#### 方法二：手动构建

```bash
# 构建release版本
flutter build macos --release

# 构建结果位置：build/macos/Build/Products/Release/BAMCLauncher.app

# 创建dmg（需要create-dmg工具）
brew install create-dmg
create-dmg \
  --volname "BAMCLauncher" \
  --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
  --background "macos/background.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "BAMCLauncher.app" 200 190 \
  --hide-extension "BAMCLauncher.app" \
  --app-drop-link 600 185 \
  "output/BAMCLauncher.dmg" \
  "build/macos/Build/Products/Release/"
```

### 3. 签名和公证

```bash
# 签名应用
codesign --deep --force --verbose --sign "Developer ID Application: Your Name (TEAMID)" "BAMCLauncher.app"

# 验证签名
codesign --verify --deep --strict --verbose=2 "BAMCLauncher.app"

# 公证（需要Apple开发者账户）
xcrun notarytool submit "BAMCLauncher.dmg" --keychain-profile "AC_PASSWORD" --wait
```

## 五、Linux平台构建

### 1. 开发构建

```bash
# 调试模式
flutter run -d linux

# 发布模式
flutter run -d linux --release
```

### 2. 构建AppImage

```bash
# 构建release版本
flutter build linux --release

# 构建结果位置：build/linux/x64/release/bundle/

# 使用appimagetool创建AppImage
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# 创建AppDir
mkdir -p BAMCLauncher.AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* BAMCLauncher.AppDir/usr/bin/

# 创建desktop文件
cat > BAMCLauncher.AppDir/BAMCLauncher.desktop << EOF
[Desktop Entry]
Name=BAMCLauncher
Exec=BAMCLauncher
Icon=BAMCLauncher
Type=Application
Categories=Game;
EOF

# 创建图标软链接
ln -s usr/bin/data/flutter_assets/icons/app_icon_128.png BAMCLauncher.AppDir/BAMCLauncher.png

# 构建AppImage
./appimagetool-x86_64.AppImage BAMCLauncher.AppDir BAMCLauncher-x86_64.AppImage
```

### 3. 构建deb包

```bash
# 安装必要工具
sudo apt install dpkg-dev fakeroot

# 创建deb包结构
mkdir -p bamclauncher_1.0.0_amd64/DEBIAN
mkdir -p bamclauncher_1.0.0_amd64/usr/bin
mkdir -p bamclauncher_1.0.0_amd64/usr/share/applications
mkdir -p bamclauncher_1.0.0_amd64/usr/share/pixmaps

# 复制文件
cp -r build/linux/x64/release/bundle/* bamclauncher_1.0.0_amd64/usr/bin/
cp linux/runner/resources/app_icon.png bamclauncher_1.0.0_amd64/usr/share/pixmaps/bamclauncher.png

# 创建control文件
cat > bamclauncher_1.0.0_amd64/DEBIAN/control << EOF
Package: bamclauncher
Version: 1.0.0
Architecture: amd64
Maintainer: BAMCLauncher Team <team@bamclauncher.com>
Description: BAMCLauncher - A cross-platform Minecraft launcher
Homepage: https://bamclauncher.com
Depends: libgtk-3-0, libglib2.0-0, libgl1-mesa-glx
EOF

# 创建desktop文件
cat > bamclauncher_1.0.0_amd64/usr/share/applications/bamclauncher.desktop << EOF
[Desktop Entry]
Name=BAMCLauncher
Exec=/usr/bin/BAMCLauncher
Icon=bamclauncher
Type=Application
Categories=Game;
EOF

# 构建deb包
fakeroot dpkg-deb --build bamclauncher_1.0.0_amd64
```

### 4. 构建rpm包

```bash
# 安装必要工具
sudo dnf install rpm-build

# 创建rpm构建目录
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# 创建spec文件
cat > ~/rpmbuild/SPECS/bamclauncher.spec << EOF
Name:           bamclauncher
Version:        1.0.0
Release:        1%{?dist}
Summary:        BAMCLauncher - A cross-platform Minecraft launcher

License:        GPLv3
URL:            https://bamclauncher.com
Source0:        bamclauncher-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  cmake
BuildRequires:  make

Requires:       gtk3
Requires:       glib2
Requires:       mesa-libGL

%description
BAMCLauncher is a cross-platform Minecraft launcher built with Flutter.

%prep
%setup -q

%build
# No build needed for pre-built binaries

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

cp -r * %{buildroot}/usr/bin/
cp app_icon.png %{buildroot}/usr/share/pixmaps/bamclauncher.png

cat > %{buildroot}/usr/share/applications/bamclauncher.desktop << DESKTOP
[Desktop Entry]
Name=BAMCLauncher
Exec=/usr/bin/BAMCLauncher
Icon=bamclauncher
Type=Application
Categories=Game;
DESKTOP

%files
/usr/bin/*
/usr/share/applications/bamclauncher.desktop
/usr/share/pixmaps/bamclauncher.png

%changelog
* $(date +"%a %b %d %Y") BAMCLauncher Team <team@bamclauncher.com> - 1.0.0-1
- Initial release
EOF

# 创建源码包
cd build/linux/x64/release/bundle/
tar czvf ~/rpmbuild/SOURCES/bamclauncher-1.0.0.tar.gz *

# 构建rpm包
rpmbuild -ba ~/rpmbuild/SPECS/bamclauncher.spec
```

## 六、自动化构建配置

### 1. GitHub Actions配置

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter build windows --release
      - name: Build Installer
        run: |
          iscc windows/installer.iss
      - uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: output/BAMCLauncher-Setup.exe

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter build macos --release
      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "BAMCLauncher" \
            --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
            --window-size 800 400 \
            --icon-size 100 \
            --icon "BAMCLauncher.app" 200 190 \
            --app-drop-link 600 185 \
            "BAMCLauncher.dmg" \
            "build/macos/Build/Products/Release/"
      - uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: BAMCLauncher.dmg

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: sudo apt-get update && sudo apt-get install -y cmake ninja-build libgtk-3-dev
      - run: flutter pub get
      - run: flutter build linux --release
      - name: Build AppImage
        run: |
          wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
          chmod +x appimagetool-x86_64.AppImage
          mkdir -p BAMCLauncher.AppDir/usr/bin
          cp -r build/linux/x64/release/bundle/* BAMCLauncher.AppDir/usr/bin/
          ln -s usr/bin/data/flutter_assets/icons/app_icon_128.png BAMCLauncher.AppDir/BAMCLauncher.png
          ./appimagetool-x86_64.AppImage BAMCLauncher.AppDir BAMCLauncher-x86_64.AppImage
      - uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: BAMCLauncher-x86_64.AppImage

  release:
    needs: [build-windows, build-macos, build-linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            windows-build/BAMCLauncher-Setup.exe
            macos-build/BAMCLauncher.dmg
            linux-build/BAMCLauncher-x86_64.AppImage
```

### 2. Docker构建环境

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    cmake \
    ninja-build \
    libgtk-3-dev \
    libglib2.0-dev \
    libgl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
    && cd /opt/flutter \
    && git checkout 3.22.0

ENV PATH="/opt/flutter/bin:${PATH}"

# 验证Flutter安装
RUN flutter doctor -v

WORKDIR /app

# 复制项目文件
COPY . .

# 安装依赖
RUN flutter pub get

# 构建Linux版本
RUN flutter build linux --release

CMD ["bash"]
```

## 七、版本管理

### 1. 版本号规范

遵循语义化版本规范：`MAJOR.MINOR.PATCH`

- **MAJOR**：不兼容的API更改
- **MINOR**：向下兼容的功能新增
- **PATCH**：向下兼容的问题修复

### 2. 更新版本号

```bash
# 更新pubspec.yaml中的版本号
# version: 1.0.0+1

# 更新构建号
flutter build windows --build-number=2

# 提交版本更新
git tag v1.0.1
git push origin v1.0.1
```

### 3. 变更日志

```markdown
# Changelog

## [1.0.1] - 2024-01-15
- Fixed: 修复了微软账户登录失败的问题
- Fixed: 优化了下载引擎性能
- Improved: 更新了界面主题

## [1.0.0] - 2024-01-01
- Initial release
- 支持多账户管理
- 支持全版本游戏下载
- 支持模组加载器自动安装
- 支持模组和资源包管理
- 支持整合包导入导出
```

## 八、发布流程

### 1. 发布前检查清单

- [ ] 所有测试通过
- [ ] 版本号已更新
- [ ] 变更日志已更新
- [ ] 构建配置已验证
- [ ] 签名证书已准备
- [ ] 发布渠道已配置

### 2. 发布渠道

- **GitHub Releases**：提供所有平台的安装包下载
- **官网下载**：提供主要下载入口
- **第三方软件中心**：
  - Windows：Microsoft Store（可选）
  - macOS：Mac App Store（可选）
  - Linux：Flathub、Snap Store（可选）

### 3. 自动更新配置

```yaml
# update.yaml
version: 1.0.1
download_url:
  windows: https://github.com/bamclauncher/bamclauncher/releases/download/v1.0.1/BAMCLauncher-Setup.exe
  macos: https://github.com/bamclauncher/bamclauncher/releases/download/v1.0.1/BAMCLauncher.dmg
  linux: https://github.com/bamclauncher/bamclauncher/releases/download/v1.0.1/BAMCLauncher-x86_64.AppImage
changelog: |
  - Fixed: 修复了微软账户登录失败的问题
  - Improved: 优化了下载引擎性能
```

## 九、常见问题

### 1. Windows构建问题

**Q: 构建时提示缺少MSVC编译器**
**A: 安装Visual Studio 2022并确保安装了"使用C++的桌面开发"工作负载**

**Q: 安装包创建失败**
**A: 确保Inno Setup已正确安装并添加到PATH中**

### 2. macOS构建问题

**Q: 签名失败**
**A: 确保已正确配置Apple开发者证书，或使用`--no-codesign`参数**

**Q: 公证失败**
**A: 检查网络连接，确保Apple Developer账户有效**

### 3. Linux构建问题

**Q: 缺少依赖库**
**A: 安装缺失的依赖：`sudo apt-get install libgtk-3-dev libglib2.0-dev`**

**Q: AppImage无法运行**
**A: 确保已赋予执行权限：`chmod +x BAMCLauncher-x86_64.AppImage`**

### 4. 跨平台构建问题

**Q: Flutter版本兼容性问题**
**A: 使用项目指定的Flutter版本：`flutter version 3.22.0`**

**Q: 依赖版本冲突**
**A: 运行`flutter pub outdated`检查并更新依赖**

## 十、安全和隐私

### 1. 代码签名

- Windows：使用EV代码签名证书
- macOS：使用Apple Developer账户签名和公证
- Linux：使用GPG签名验证

### 2. 隐私保护

- 确保安装包不包含恶意代码
- 遵循各平台的隐私政策要求
- 明确收集的数据类型和用途

### 3. 防篡改措施

- 使用哈希校验确保安装包完整性
- 实现自动更新验证机制
- 定期扫描恶意软件

## 十一、性能优化

### 1. 构建优化

- 使用`--split-debug-info`减小二进制文件大小
- 启用代码压缩和混淆
- 优化资源文件大小

### 2. 启动优化

- 预加载必要资源
- 延迟加载非关键组件
- 优化启动流程

### 3. 运行时优化

- 使用Flutter的性能分析工具
- 优化内存使用
- 减少不必要的重绘

## 十二、维护和支持

### 1. 版本维护

- 定期更新依赖库
- 修复安全漏洞
- 适配新的Flutter版本

### 2. 用户支持

- 建立反馈渠道
- 提供详细的错误报告指南
- 定期发布更新修复问题

### 3. 监控和分析

- 实现应用内错误报告
- 收集使用统计数据
- 监控性能指标

---

**注意**：本指南提供了通用的构建和部署流程。根据项目的具体需求，可能需要调整配置和步骤。建议在实际部署前进行充分的测试，确保构建的应用在各平台上都能正常运行。