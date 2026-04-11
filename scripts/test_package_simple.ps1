echo "=== BAMCLauncher 打包配置测试 ==="

# 检查必要文件是否存在
if (Test-Path "distribute.yaml") {
    echo "✓ distribute.yaml 存在"
} else {
    echo "✗ distribute.yaml 不存在"
}

if (Test-Path "pubspec.yaml") {
    echo "✓ pubspec.yaml 存在"
} else {
    echo "✗ pubspec.yaml 不存在"
}

if (Test-Path "scripts/linux/bamclauncher.desktop") {
    echo "✓ scripts/linux/bamclauncher.desktop 存在"
} else {
    echo "✗ scripts/linux/bamclauncher.desktop 不存在"
}

if (Test-Path ".github/workflows/build-and-package.yml") {
    echo "✓ .github/workflows/build-and-package.yml 存在"
} else {
    echo "✗ .github/workflows/build-and-package.yml 不存在"
}

echo " "
echo "=== 打包命令示例 ==="
echo "Windows MSI: flutter_distributor package --platform windows --targets msi"
echo "Windows ZIP: flutter_distributor package --platform windows --targets zip"
echo "macOS DMG: flutter_distributor package --platform macos --targets dmg"
echo "Linux DEB: flutter_distributor package --platform linux --targets deb"
echo "Linux RPM: flutter_distributor package --platform linux --targets rpm"
echo "Linux AppImage: flutter_distributor package --platform linux --targets appimage"

echo " "
echo "=== 配置完成 ==="
