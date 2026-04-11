# BAMCLauncher 自动化测试脚本（Windows版本）
# 用于本地开发和CI/CD环境

Write-Host "=== BAMCLauncher 自动化测试脚本 ==="
Write-Host "当前目录: $(Get-Location)"
Write-Host "Flutter版本: $(flutter --version)"

# 错误处理
$ErrorActionPreference = "Stop"

try {
    # 安装依赖
    Write-Host "正在安装依赖..." -ForegroundColor Yellow
    flutter pub get
    
    # 代码分析
    Write-Host "正在运行代码分析..." -ForegroundColor Yellow
    flutter analyze
    
    # 运行单元测试
    Write-Host "正在运行单元测试..." -ForegroundColor Yellow
    flutter test test/core/
    
    # 运行集成测试
    Write-Host "正在运行集成测试..." -ForegroundColor Yellow
    flutter test test/comprehensive_integration_test.dart
    
    # 运行跨平台测试
    Write-Host "正在运行跨平台测试..." -ForegroundColor Yellow
    flutter test test/enhanced_cross_platform_test.dart
    
    # 运行压力测试
    Write-Host "正在运行压力测试..." -ForegroundColor Yellow
    flutter test test/stress_test.dart
    
    # 代码格式化检查
    Write-Host "正在检查代码格式化..." -ForegroundColor Yellow
    dart format --set-exit-if-changed .
    
    Write-Host "所有测试通过！" -ForegroundColor Green
    Write-Host "=== 测试完成 ==="
    
} catch {
    Write-Host "错误: $_" -ForegroundColor Red
    exit 1
}