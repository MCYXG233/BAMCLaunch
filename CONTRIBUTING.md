# BAMCLauncher 开发文档与贡献指南

## 一、项目概述

BAMCLauncher是一个基于Flutter开发的跨平台Minecraft启动器，采用分层架构和模块化设计，实现了高内聚低耦合的系统架构。

### 核心特性

- **跨平台支持**：Windows、macOS、Linux全平台覆盖
- **模块化设计**：所有功能模块通过统一接口抽象，完全解耦
- **全栈自研**：核心能力完全自研，确保代码可控性和鲁棒性
- **高扩展性**：新增功能仅需实现对应接口，无需修改上层代码

## 二、开发环境搭建

### 前置要求

- Flutter 3.22+（稳定版）
- Dart SDK 3.0+
- Git
- 各平台开发工具：
  - Windows：Visual Studio 2022（含Desktop development with C++）
  - macOS：Xcode 14+
  - Linux：CMake、Ninja、GCC/Clang

### 安装步骤

1. **克隆仓库**

```bash
git clone https://github.com/yourusername/BAMCLauncher.git
cd BAMCLauncher
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行项目**

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

4. **构建项目**

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 三、代码规范

### 命名规范

- **类名**：采用大驼峰命名法（PascalCase）
- **函数名**：采用小驼峰命名法（camelCase）
- **变量名**：采用小驼峰命名法（camelCase）
- **常量名**：全大写，下划线分隔（UPPER_CASE_WITH_UNDERSCORES）
- **文件名**：小写，下划线分隔（snake_case.dart）

### 代码风格

- 使用4个空格缩进
- 每行代码不超过100个字符
- 优先使用`const`构造函数
- 避免使用全局变量
- 使用类型注解

### 注释规范

- 公共API必须有文档注释（///）
- 复杂逻辑必须有行内注释（//）
- 类和函数必须包含参数说明和返回值说明

## 四、架构设计

### 分层架构

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

### 模块结构

```
lib/
├── core/                 # 核心业务逻辑
│   ├── auth/            # 账户认证模块
│   ├── config/          # 配置管理模块
│   ├── content/         # 内容管理模块
│   ├── download/        # 下载引擎模块
│   ├── game/            # 游戏启动模块
│   ├── platform/        # 平台适配模块
│   ├── version/         # 版本管理模块
│   └── logger/          # 日志模块
├── ui/                  # 用户界面
│   ├── components/      # UI组件
│   ├── pages/          # 页面
│   └── theme/          # 主题配置
└── main.dart           # 应用入口
```

## 五、开发流程

### 分支管理

- **main**：主分支，稳定版本
- **develop**：开发分支，集成最新功能
- **feature/**：功能分支，开发新特性
- **fix/**：修复分支，修复bug
- **release/**：发布分支，准备发布

### Git工作流程

1. **创建分支**

```bash
# 从develop分支创建新分支
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

2. **开发代码**

- 编写功能代码
- 编写单元测试
- 确保代码通过lint检查

3. **提交代码**

```bash
git add .
git commit -m "feat: 描述你的功能"
# 或
git commit -m "fix: 描述你的修复"
```

4. **推送分支**

```bash
git push origin feature/your-feature-name
```

5. **创建Pull Request**

- 在GitHub上创建Pull Request
- 描述功能/修复内容
- 等待代码审核

## 六、测试指南

### 单元测试

所有核心模块必须有单元测试，测试文件放在`test/core/`目录下。

```bash
# 运行所有单元测试
flutter test test/core/

# 运行特定模块的测试
flutter test test/core/auth/
```

### 集成测试

集成测试验证多个模块的协同工作，测试文件放在`test/`目录下。

```bash
# 运行集成测试
flutter test test/comprehensive_integration_test.dart
```

### 跨平台测试

确保在所有平台上正常运行。

```bash
# 运行跨平台测试
flutter test test/enhanced_cross_platform_test.dart
```

### 性能测试

验证应用性能表现。

```bash
# 运行性能测试
flutter test test/stress_test.dart
```

## 七、贡献指南

### 提交Bug报告

1. 在GitHub Issues中创建新issue
2. 提供详细的问题描述
3. 提供复现步骤
4. 附上相关日志和截图

### 功能请求

1. 在GitHub Issues中创建新issue
2. 描述功能需求和使用场景
3. 说明为什么需要这个功能

### 代码贡献

1. Fork项目仓库
2. 创建功能分支
3. 实现功能并编写测试
4. 提交Pull Request
5. 等待代码审核

### 文档贡献

- 更新API文档
- 完善用户手册
- 编写教程和示例

## 八、代码审核标准

### 功能完整性

- 功能实现完整
- 边界情况处理正确
- 错误处理完善

### 代码质量

- 符合代码规范
- 注释完整
- 性能优化
- 内存管理正确

### 测试覆盖

- 单元测试覆盖率高
- 集成测试验证
- 跨平台兼容性测试

### 安全考虑

- 敏感信息加密
- 输入验证
- 权限控制

## 九、发布流程

### 版本号规则

采用语义化版本号：`MAJOR.MINOR.PATCH`

- **MAJOR**：不兼容的API变更
- **MINOR**：向后兼容的功能新增
- **PATCH**：向后兼容的问题修复

### 发布步骤

1. 更新版本号（pubspec.yaml）
2. 更新CHANGELOG.md
3. 运行测试确保所有测试通过
4. 创建Git标签
5. 推送标签触发CI/CD
6. 发布GitHub Release

## 十、技术支持

### 开发环境问题

- Flutter官方文档：https://docs.flutter.dev/
- Dart官方文档：https://dart.dev/

### 项目相关问题

- GitHub Issues：提交问题和功能请求
- Discord社区：实时讨论和帮助

## 十一、许可证

BAMCLauncher采用GPLv3许可证，详细信息请查看LICENSE文件。

---

**感谢您的贡献！** 🚀
