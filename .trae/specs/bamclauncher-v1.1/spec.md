
# BAMCLauncher v1.1 - 产品需求文档

## Overview
- **Summary**: BAMCLauncher v1.1在v1.0基础上新增资源中心（模组/资源包下载）、微软正版登录、完整主题系统、更多设置选项，并修复网络错误和更新许可证为GPL3。
- **Purpose**: 增强用户体验，提供完整的MC社区内容访问能力，支持正版登录，完善个性化设置，确保代码开源合规。
- **Target Users**: Minecraft玩家，特别是喜欢蔚蓝档案风格UI的用户，需要模组管理和正版登录功能的用户。

## Goals
- 实现资源中心，支持CurseForge和Modrinth双源模组/资源包搜索与下载
- 实现微软OAuth2正版登录流程（Xbox/Minecraft）
- 实现完整主题系统：明亮模式、暗黑模式、跟随系统
- 大幅扩展设置选项，满足用户个性化需求
- 更新许可证为GPLv3
- 修复网络错误和镜像源问题
- 增强下载引擎的镜像源容错能力

## Non-Goals (Out of Scope)
- 模组加载器自动安装（v1.0已规划但暂未实现，v1.2考虑）
- 整合包管理（后续版本）
- 服务器联机（后续版本）
- 自动更新系统（后续版本）

## Background & Context
- 项目基于v1.0完整架构，采用分层设计和事件驱动模式
- 技术栈保持不变：Flutter 3.22.2 + Dart 3.4.3
- 严格遵循GPLv3许可证要求
- 现有蔚蓝档案风格UI组件库已完善，可直接复用
- BMCLAPI镜像源出现连接问题，需要增强容错机制

## Functional Requirements
- **FR-1**: 实现资源中心模块，支持CurseForge和Modrinth API
- **FR-2**: 实现模组浏览、搜索、筛选、下载功能
- **FR-3**: 实现资源包浏览、搜索、筛选、下载功能
- **FR-4**: 实现已安装模组/资源包的管理（启用/禁用/删除）
- **FR-5**: 实现微软OAuth2完整登录流程（授权码 + PKCE）
- **FR-6**: 实现Xbox Live认证、Minecraft配置文件获取
- **FR-7**: 实现正版账户的皮肤/披风管理
- **FR-8**: 实现明亮模式主题配色
- **FR-9**: 实现主题切换功能（明亮/暗黑/跟随系统）
- **FR-10**: 扩展设置选项：窗口大小、启动动画、音效等
- **FR-11**: 实现多镜像源自动切换和容错
- **FR-12**: 更新许可证为GPLv3

## Non-Functional Requirements
- **NFR-1**: 所有敏感信息（微软令牌）加密存储
- **NFR-2**: 模组搜索响应时间&lt;2秒
- **NFR-3**: 主题切换流畅无闪烁
- **NFR-4**: 登录流程符合OAuth2安全规范
- **NFR-5**: 镜像源切换自动、快速

## Constraints
- **Technical**: 复用现有架构，不引入新的大型第三方库
- **Business**: 严格遵守Minecraft EULA和CurseForge/Modrinth API使用规范
- **Dependencies**: http, crypto, archive（已存在）

## Assumptions
- 用户网络环境可访问微软认证服务
- CurseForge/Modrinth API稳定可用
- 用户了解正版登录需要微软账户

## Acceptance Criteria

### AC-1: 资源中心功能完整
- **Given**: 用户打开资源中心页面
- **When**: 选择模组或资源包标签，进行搜索和筛选
- **Then**: 可正确浏览、搜索、下载模组/资源包，并在本地管理
- **Verification**: `programmatic` + `human-judgment`

### AC-2: CurseForge/Modrinth双源支持
- **Given**: 用户在资源中心选择不同来源
- **When**: 搜索和下载内容
- **Then**: 两个来源都能正常工作，用户可自由切换
- **Verification**: `programmatic`

### AC-3: 微软正版登录完整流程
- **Given**: 用户选择添加正版账户
- **When**: 完成OAuth2授权流程
- **Then**: 成功登录，获取Minecraft配置文件，可用于启动游戏
- **Verification**: `programmatic`

### AC-4: 正版账户皮肤/披风管理
- **Given**: 用户登录正版账户
- **When**: 查看和管理皮肤/披风
- **Then**: 可正确显示、上传、更换皮肤和披风
- **Verification**: `programmatic` + `human-judgment`

### AC-5: 明亮模式主题实现
- **Given**: 主题系统已实现
- **When**: 用户切换到明亮模式
- **Then**: UI配色正确切换到明亮风格，蔚蓝档案设计元素保持
- **Verification**: `human-judgment`

### AC-6: 主题切换功能正常
- **Given**: 用户在设置中选择主题选项
- **When**: 切换主题（明亮/暗黑/跟随系统）
- **Then**: 主题即时切换，设置持久化保存
- **Verification**: `programmatic`

### AC-7: 设置选项扩展完成
- **Given**: 用户打开设置页面
- **When**: 浏览和修改设置选项
- **Then**: 可看到并使用新的设置项，设置正确保存
- **Verification**: `programmatic` + `human-judgment`

### AC-8: 多镜像源容错机制
- **Given**: 下载引擎正在工作
- **When**: 当前镜像源连接失败
- **Then**: 自动切换到备用镜像源，下载继续
- **Verification**: `programmatic`

### AC-9: 许可证更新为GPLv3
- **Given**: 项目代码已更新
- **When**: 查看许可证文件和相关声明
- **Then**: 正确显示GPLv3许可证信息
- **Verification**: `human-judgment`

## Open Questions
- [ ] CurseForge API密钥是否需要申请（官方API需要）
