#!/bin/bash

# BAMCLauncher 自动化测试脚本
# 用于本地开发和CI/CD环境

echo "=== BAMCLauncher 自动化测试脚本 ==="
echo "当前目录: $(pwd)"
echo "Flutter版本: $(flutter --version)"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 错误处理函数
handle_error() {
    echo -e "${RED}错误: $1${NC}"
    exit 1
}

# 安装依赖
echo -e "${YELLOW}正在安装依赖...${NC}"
flutter pub get || handle_error "依赖安装失败"

# 代码分析
echo -e "${YELLOW}正在运行代码分析...${NC}"
flutter analyze || handle_error "代码分析失败"

# 运行单元测试
echo -e "${YELLOW}正在运行单元测试...${NC}"
flutter test test/core/ || handle_error "单元测试失败"

# 运行集成测试
echo -e "${YELLOW}正在运行集成测试...${NC}"
flutter test test/comprehensive_integration_test.dart || handle_error "集成测试失败"

# 运行跨平台测试
echo -e "${YELLOW}正在运行跨平台测试...${NC}"
flutter test test/enhanced_cross_platform_test.dart || handle_error "跨平台测试失败"

# 运行压力测试
echo -e "${YELLOW}正在运行压力测试...${NC}"
flutter test test/stress_test.dart || handle_error "压力测试失败"

# 代码格式化检查
echo -e "${YELLOW}正在检查代码格式化...${NC}"
dart format --set-exit-if-changed . || handle_error "代码格式化检查失败"

echo -e "${GREEN}所有测试通过！${NC}"
echo "=== 测试完成 ==="