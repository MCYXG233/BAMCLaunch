
# BAMCLauncher - Alpha版本任务计划（分解与优先级）

## [x] 任务 1: 初始化Flutter项目与配置依赖
- **Priority**: P0
- **Depends On**: 无
- **Description**: 
  - 使用Flutter 3.22.2创建桌面项目
  - 配置pubspec.yaml，添加所有指定依赖
  - 配置三大平台（Windows/Mac/Linux）的编译环境
  - 设置项目基础目录结构
- **Acceptance Criteria Addressed**: [AC-1]
- **Test Requirements**:
  - `programmatic` TR-1.1: 项目结构正确创建，包含lib/、test/等目录
  - `programmatic` TR-1.2: pubspec.yaml包含所有指定依赖
  - `programmatic` TR-1.3: 运行flutter pub get成功
- **Notes**: 这是整个项目的第一步，必须优先完成

## [x] 任务 2: 实现全局事件总线
- **Priority**: P0
- **Depends On**: [任务 1]
- **Description**: 
  - 实现事件总线核心类，支持事件订阅/发布/取消
  - 支持泛型事件类型，保证类型安全
  - 实现弱引用订阅者，防止内存泄漏
- **Acceptance Criteria Addressed**: [AC-2]
- **Test Requirements**:
  - `programmatic` TR-2.1: 事件能正确发布到所有订阅者
  - `programmatic` TR-2.2: 支持取消订阅，取消后不再接收事件
  - `programmatic` TR-2.3: 支持不同类型的事件分发
- **Notes**: 这是模块间通信的核心基础设施

## [x] 任务 3: 实现任务框架
- **Priority**: P0
- **Depends On**: [任务 2]
- **Description**: 
  - 实现Task基类，支持依赖图、进度报告、取消机制
  - 实现TaskStatus、TaskProgress、TaskContext类
  - 支持链式操作（thenApply、thenCompose）
  - 支持并行和顺序执行任务
  - 使用设计文档中提供的代码示例
- **Acceptance Criteria Addressed**: [AC-3]
- **Test Requirements**:
  - `programmatic` TR-3.1: 任务能按依赖顺序正确执行
  - `programmatic` TR-3.2: 进度能正确报告
  - `programmatic` TR-3.3: 任务能被正确取消
  - `programmatic` TR-3.4: 链式操作功能正常
- **Notes**: 这是所有异步操作（下载、安装、启动）的基础

## [x] 任务 4: 实现平台适配层（IPlatformAdapter）
- **Priority**: P0
- **Depends On**: [任务 3]
- **Description**: 
  - 定义IPlatformAdapter统一接口
  - 实现Windows平台适配（默认路径：%APPDATA%/.bamclauncher）
  - 实现MacOS平台适配（默认路径：~/Library/Application Support/BAMCLauncher）
  - 实现Linux平台适配（默认路径：~/.config/bamclauncher）
  - 支持用户自定义路径
- **Acceptance Criteria Addressed**: [AC-4]
- **Test Requirements**:
  - `programmatic` TR-4.1: 各平台能正确获取默认路径
  - `programmatic` TR-4.2: 支持自定义路径配置
  - `programmatic` TR-4.3: 路径创建和权限检查功能正常
- **Notes**: 所有文件操作都通过平台适配层进行

## [x] 任务 5: 实现配置管理（IConfigManager）
- **Priority**: P0
- **Depends On**: [任务 4]
- **Description**: 
  - 定义IConfigManager统一接口
  - 实现配置持久化（JSON格式）
  - 实现AES-256加密存储敏感信息
  - 实现配置项的读写、监听、默认值
- **Acceptance Criteria Addressed**: [AC-5]
- **Test Requirements**:
  - `programmatic` TR-5.1: 配置能正确读写和持久化
  - `programmatic` TR-5.2: 敏感信息加密存储，不能明文查看
  - `programmatic` TR-5.3: 配置变更能正确通知监听者
- **Notes**: 所有配置项都通过配置管理器管理

## [x] 任务 6: 实现全局异常捕获与日志系统
- **Priority**: P0
- **Depends On**: [任务 5]
- **Description**: 
  - 使用Zone.runZonedGuarded捕获所有Dart层异常
  - 实现分级日志系统（Debug/Info/Warn/Error）
  - 实现日志持久化到文件
  - 实现异常上报和问题定位辅助
- **Acceptance Criteria Addressed**: [AC-6]
- **Test Requirements**:
  - `programmatic` TR-6.1: 同步和异步异常都能被正确捕获
  - `programmatic` TR-6.2: 日志能正确分级输出和持久化
  - `programmatic` TR-6.3: 异常不会导致程序闪退
- **Notes**: 这是保证程序稳定性的关键

## [x] 任务 7: 实现核心UI组件库（1/2）
- **Priority**: P0
- **Depends On**: [任务 6]
- **Description**: 
  - 实现主题系统（配色、字体、样式）
  - 实现自定义标题栏（适配三大平台窗口控制）
  - 实现立体按钮（主按钮/次要按钮/危险按钮）
  - 实现立体输入框、开关、滑块
- **Acceptance Criteria Addressed**: [AC-7]
- **Test Requirements**:
  - `human-judgment` TR-7.1: 所有组件视觉符合蔚蓝档案1.63新版UI规范
  - `human-judgment` TR-7.2: 组件交互流畅，有适当的动效
- **Notes**: 严格遵循设计文档中的UI规范

## [x] 任务 8: 实现核心UI组件库（2/2）
- **Priority**: P0
- **Depends On**: [任务 7]
- **Description**: 
  - 实现毛玻璃弹窗、右键菜单
  - 实现MC经验条风格进度条
  - 实现卡片式列表项
  - 实现左侧固定侧边栏导航
- **Acceptance Criteria Addressed**: [AC-7]
- **Test Requirements**:
  - `human-judgment` TR-8.1: 所有组件视觉符合蔚蓝档案1.63新版UI规范
  - `human-judgment` TR-8.2: 组件交互流畅，有适当的动效
- **Notes**: 完成UI组件库后才能开始页面开发

## [x] 任务 9: 实现账户系统
- **Priority**: P1
- **Depends On**: [任务 8]
- **Description**: 
  - 定义账户数据模型
  - 实现离线账户的添加、编辑、删除
  - 实现账户切换和持久化
  - 实现账户管理界面
- **Acceptance Criteria Addressed**: [AC-8]
- **Test Requirements**:
  - **programmatic** TR-9.1: 账户信息能正确持久化
  - **programmatic** TR-9.2: 账户添加、删除、切换功能正常
  - **human-judgment** TR-9.3: 账户管理界面UI符合规范
- **Notes**: Alpha版本仅支持离线账户

## [x] 任务 10: 实现下载引擎
- **Priority**: P1
- **Depends On**: [任务 9]
- **Description**: 
  - 定义IDownloadEngine和IDownloadSource接口
  - 实现多线程分块下载
  - 实现断点续传
  - 实现哈希校验（SHA-1/SHA-256/MD5）
  - 实现BMCLAPI镜像源适配
  - 实现失败重试机制
- **Acceptance Criteria Addressed**: [AC-9]
- **Test Requirements**:
  - `programmatic` TR-10.1: 多线程分块下载功能正常
  - `programmatic` TR-10.2: 断点续传功能正常
  - `programmatic` TR-10.3: 文件哈希校验功能正常
  - `programmatic` TR-10.4: BMCLAPI镜像源能正常使用
- **Notes**: 所有耗时操作放入独立Isolate

## [x] 任务 11: 实现版本管理
- **Priority**: P1
- **Depends On**: [任务 10]
- **Description**: 
  - 实现原版MC版本列表获取（通过BMCLAPI）
  - 实现版本下载和安装
  - 实现版本隔离
  - 实现版本管理界面
- **Acceptance Criteria Addressed**: [AC-10]
- **Test Requirements**:
  - `programmatic` TR-11.1: 版本列表能正确获取和显示
  - `programmatic` TR-11.2: 版本下载和安装流程正常
  - `programmatic` TR-11.3: 版本隔离功能正常
  - `human-judgment` TR-11.4: 版本管理界面UI符合规范
- **Notes**: Alpha版本仅支持原版MC

## [x] 任务 12: 实现Java管理
- **Priority**: P1
- **Depends On**: [任务 11]
- **Description**: 
  - 实现系统Java自动检测（各平台不同路径）
  - 实现Java版本兼容性判断
  - 实现Java路径配置界面
- **Acceptance Criteria Addressed**: [AC-11]
- **Test Requirements**:
  - `programmatic` TR-12.1: 系统Java能被正确检测
  - `programmatic` TR-12.2: Java版本兼容性判断正确
  - `human-judgment` TR-12.3: Java配置界面UI符合规范
- **Notes**: 不同平台检测路径不同

## [x] 任务 13: 实现游戏启动模块
- **Priority**: P1
- **Depends On**: [任务 12]
- **Description**: 
  - 实现启动参数构建
  - 实现游戏进程启动
  - 实现日志实时输出
  - 实现进程监控
- **Acceptance Criteria Addressed**: [AC-12]
- **Test Requirements**:
  - `programmatic` TR-13.1: 启动参数能正确构建
  - `programmatic` TR-13.2: 游戏进程能正常启动和关闭
  - `programmatic` TR-13.3: 日志能实时输出
  - `programmatic` TR-13.4: 进程监控功能正常
- **Notes**: 这是核心功能之一

## [x] 任务 14: 实现核心页面（1/2）
- **Priority**: P1
- **Depends On**: [任务 13]
- **Description**: 
  - 实现启动加载页（夏莱logo+像素加载动画）
  - 实现主界面（侧边栏+启动卡片+最近记录）
- **Acceptance Criteria Addressed**: [AC-13]
- **Test Requirements**:
  - `human-judgment` TR-14.1: 启动加载页UI符合规范
  - `human-judgment` TR-14.2: 主界面UI符合规范
  - `programmatic` TR-14.3: 页面导航功能正常
- **Notes**: 先实现启动页和主界面

## [x] 任务 15: 实现核心页面 (2/2)
- **Priority**: P1
- **Depends On**: [任务 14]
- **Description**: 
  - 实现版本管理页
  - 实现账户管理页
  - 实现设置页（通用设置+下载设置+游戏设置）
- **Acceptance Criteria Addressed**: [AC-13]
- **Test Requirements**:
  - **human-judgment** TR-15.1: 所有页面UI符合规范
  - **programmatic** TR-15.2: 页面功能正常
- **Notes**: 完成所有核心页面

## [x] 任务 16: 整体测试与优化
- **Priority**: P2
- **Depends On**: [任务 15]
- **Description**: 
  - 全流程测试（启动-登录-下载-安装-启动游戏）
  - 性能优化（保证UI 60fps）
  - 代码格式化和质量检查
  - 编写README文档
- **Acceptance Criteria Addressed**: [所有AC]
- **Test Requirements**:
  - `programmatic` TR-16.1: 全流程测试通过
  - `programmatic` TR-16.2: 代码通过dart format格式化
  - `human-judgment` TR-16.3: README文档完整清晰
- **Notes**: 最终交付前的准备工作
