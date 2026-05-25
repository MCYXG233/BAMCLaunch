
# BAMCLauncher - Alpha版本产品需求文档

## Overview
- **Summary**: BAMCLauncher是一个跨平台Minecraft启动器，采用分层架构和接口抽象设计，完全对齐2026年日服蔚蓝档案1.63版本立体悬浮设计语言，融合Minecraft像素元素，打造高可扩展性的全栈自研启动器。
- **Purpose**: 从零构建完整可运行的Alpha版本，实现离线账户、原版MC版本下载安装、基础游戏启动等核心功能，同时建立完整的模块化架构和UI组件库。
- **Target Users**: Minecraft玩家，特别是喜欢蔚蓝档案风格UI的用户，需要跨平台、高性能、高可扩展性的启动器。

## Goals
- 搭建完整的分层架构与统一接口体系
- 完成三大平台（Windows/Mac/Linux）基础适配层
- 实现核心基础设施：全局事件总线、任务框架、配置管理、异常处理
- 构建基于蔚蓝档案1.63新版UI的自研组件库
- 实现Alpha版本核心功能：离线账户管理、版本管理、下载引擎、游戏启动
- 保证代码质量、性能和鲁棒性

## Non-Goals (Out of Scope)
- 微软正版OAuth2登录（Alpha阶段不包含）
- Authlib-Injector第三方登录（Alpha阶段不包含）
- 模组加载器安装（Alpha阶段不包含）
- 模组/资源包管理（Alpha阶段不包含）
- 整合包管理（Alpha阶段不包含）
- 服务器联机功能（Alpha阶段不包含）
- 自动更新系统（Alpha阶段不包含）

## Background & Context
- 项目基于设计文档《BAMCLauncher 蔚蓝档案新版UI设计方案》完全实现
- 采用Flutter 3.22.2稳定版 + Dart 3.4.3技术栈
- 核心逻辑零第三方依赖，仅使用必要的底层库（crypto、archive、sqflite_common_ffi、xml等）
- 严格遵循Minecraft EULA，不内置任何MC核心文件

## Functional Requirements
- **FR-1**: 实现全局事件总线，支持模块间解耦通信
- **FR-2**: 实现任务框架，支持任务依赖图、进度报告、取消机制
- **FR-3**: 实现IPlatformAdapter接口，完成Win/Mac/Linux基础路径和系统能力适配
- **FR-4**: 实现IConfigManager接口，支持配置持久化和敏感信息AES-256加密
- **FR-5**: 实现全局异常捕获系统，使用Zone.runZonedGuarded处理所有异常
- **FR-6**: 实现基于蔚蓝档案1.63新版UI的核心组件库（按钮、输入框、进度条、侧边栏等）
- **FR-7**: 实现账户系统：离线账户的添加、切换、删除、持久化
- **FR-8**: 实现下载引擎：多线程分块下载、断点续传、哈希校验、BMCLAPI镜像源适配
- **FR-9**: 实现版本管理：原版MC版本列表获取、下载、安装、版本隔离
- **FR-10**: 实现Java管理：系统Java自动检测、版本兼容性判断
- **FR-11**: 实现游戏启动：启动参数构建、进程启动、日志输出、进程监控
- **FR-12**: 实现核心页面：启动加载页、主界面、版本管理页、账户管理页、设置页

## Non-Functional Requirements
- **NFR-1**: 所有耗时操作必须放入独立Isolate执行，保证UI全程60fps流畅
- **NFR-2**: 所有类、方法、变量必须有清晰的中文注释
- **NFR-3**: 代码必须通过dart format格式化，遵循Dart官方编码规范
- **NFR-4**: 所有错误必须有明确的用户提示和日志记录，禁止静默失败
- **NFR-5**: UI设计必须1:1还原蔚蓝档案1.63版本的立体悬浮风格

## Constraints
- **Technical**: Flutter 3.22.2 + Dart 3.4.3，仅允许使用指定依赖包
- **Business**: 严格遵循Minecraft EULA，不内置MC核心文件
- **Dependencies**: window_manager: ^0.4.2、crypto、archive、sqflite_common_ffi、xml、path_provider、http

## Assumptions
- 用户已安装Flutter 3.22.2和Dart 3.4.3开发环境
- 三大平台编译环境已正确配置
- 网络连接正常，可访问BMCLAPI等镜像源
- 用户操作系统满足Minecraft运行要求

## Acceptance Criteria

### AC-1: 项目初始化成功
- **Given**: 已配置Flutter 3.22.2开发环境
- **When**: 运行flutter create初始化项目并配置依赖
- **Then**: 项目结构正确创建，pubspec.yaml包含所有指定依赖
- **Verification**: `programmatic`

### AC-2: 全局事件总线功能正常
- **Given**: 事件总线已初始化
- **When**: 多个模块订阅并发送事件
- **Then**: 事件能正确传递到所有订阅者，支持取消订阅
- **Verification**: `programmatic`

### AC-3: 任务框架功能正常
- **Given**: 任务框架已实现
- **When**: 执行有依赖关系的任务链
- **Then**: 任务按依赖顺序执行，支持进度报告和取消操作
- **Verification**: `programmatic`

### AC-4: 平台适配层功能正常
- **Given**: IPlatformAdapter已实现
- **When**: 在不同平台上运行
- **Then**: 能正确获取各平台的默认路径，支持路径自定义
- **Verification**: `programmatic`

### AC-5: 配置管理功能正常
- **Given**: IConfigManager已实现
- **When**: 读写配置项和敏感信息
- **Then**: 配置能正确持久化，敏感信息采用AES-256加密存储
- **Verification**: `programmatic`

### AC-6: 全局异常捕获正常
- **Given**: 异常捕获系统已启用
- **When**: 发生同步或异步异常
- **Then**: 异常能被正确捕获，记录到日志，不会导致程序闪退
- **Verification**: `programmatic`

### AC-7: UI组件库实现完整
- **Given**: 所有核心UI组件已实现
- **When**: 在应用中使用这些组件
- **Then**: 组件外观和交互符合蔚蓝档案1.63新版UI设计规范
- **Verification**: `human-judgment`

### AC-8: 账户系统功能正常
- **Given**: 账户管理界面已打开
- **When**: 添加、切换、删除离线账户
- **Then**: 操作成功，账户信息正确持久化
- **Verification**: `programmatic`

### AC-9: 下载引擎功能正常
- **Given**: 需要下载游戏文件
- **When**: 使用下载引擎下载文件
- **Then**: 支持多线程分块下载、断点续传、哈希校验
- **Verification**: `programmatic`

### AC-10: 版本管理功能正常
- **Given**: 版本管理页面已打开
- **When**: 获取版本列表、下载、安装版本
- **Then**: 能正确显示可下载版本，下载安装流程正常
- **Verification**: `programmatic`

### AC-11: Java管理功能正常
- **Given**: 系统已安装Java
- **When**: 检测Java环境
- **Then**: 能正确识别Java版本，判断兼容性
- **Verification**: `programmatic`

### AC-12: 游戏启动功能正常
- **Given**: 已安装MC版本和配置好Java
- **When**: 点击启动游戏
- **Then**: 游戏能正常启动，日志实时输出，进程正常监控
- **Verification**: `programmatic`

### AC-13: 所有核心页面实现完整
- **Given**: 应用已启动
- **When**: 导航到各个页面
- **Then**: 所有页面UI符合设计规范，功能正常
- **Verification**: `human-judgment`

## Open Questions
- 无（设计文档已明确所有技术规范）
