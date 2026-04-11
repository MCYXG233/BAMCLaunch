# BAMCLauncher 打包测试脚本
# 用于验证打包配置是否正确

Write-Host "=== BAMCLauncher 打包配置测试 ===" -ForegroundColor Cyan

# 检查必要文件是否存在
$filesToCheck = @(
    "distribute.yaml",
    "pubspec.yaml",
    "scripts/linux/bamclauncher.desktop",
    ".github/workflows/build-and-package.yml"
)

foreach ($file in $filesToCheck) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
    }
}

# 检查 flutter_distributor 是否安装
try {
    $distributorVersion = dart pub global run flutter_distributor --version
    Write-Host "✓ flutter_distributor 已安装: $distributorVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ flutter_distributor 未安装，请运行: dart pub global activate flutter_distributor" -ForegroundColor Red
}

# 检查环境变量文件
if (Test-Path ".env") {
    Write-Host "✓ .env 文件存在" -ForegroundColor Green
} else {
    Write-Host "⚠ .env 文件不存在，将使用默认配置" -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Write-Host "  请从 .env.example 创建 .env 文件" -ForegroundColor Yellow
    }
}

Write-Host "`n=== 打包命令示例 ===" -ForegroundColor Cyan
Write-Host "Windows MSI: flutter_distributor package --platform windows --targets msi" -ForegroundColor White
Write-Host "Windows ZIP: flutter_distributor package --platform windows --targets zip" -ForegroundColor White
Write-Host "macOS DMG: flutter_distributor package --platform macos --targets dmg" -ForegroundColor White
Write-Host "Linux DEB: flutter_distributor package --platform linux --targets deb" -ForegroundColor White
Write-Host "Linux RPM: flutter_distributor package --platform linux --targets rpm" -ForegroundColor White
Write-Host "Linux AppImage: flutter_distributor package --platform linux --targets appimage" -ForegroundColor White

Write-Host "`n=== 配置完成 ===" -ForegroundColor Green
