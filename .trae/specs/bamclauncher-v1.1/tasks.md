
# BAMCLauncher v1.1 - 任务计划

## [x] 任务 1: 更新许可证为GPLv3
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 创建LICENSE文件，包含GPLv3许可证文本
  - 更新README.md中的许可证信息
  - 在合适的位置添加版权声明
- **Acceptance Criteria Addressed**: AC-9
- **Test Requirements**:
  - `human-judgment` TR-1.1: LICENSE文件存在且内容正确
  - `human-judgment` TR-1.2: README.md许可证信息已更新
- **Notes**: GPLv3许可证文本可从https://www.gnu.org/licenses/gpl-3.0.txt获取

## [x] 任务 2: 增强主题系统 - 明亮模式
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 更新colors.dart，添加明亮模式配色方案
  - 更新app_theme.dart，支持亮色/暗色两种主题
  - 实现主题状态管理和切换逻辑
  - 确保所有组件在两种主题下都能正常显示
- **Acceptance Criteria Addressed**: AC-5, AC-6
- **Test Requirements**:
  - `human-judgment` TR-2.1: 明亮模式配色符合蔚蓝档案风格
  - `programmatic` TR-2.2: 主题切换功能正常
  - `programmatic` TR-2.3: 主题设置正确持久化
- **Notes**: 保持蔚蓝档案的清新风格，配色要协调

## [x] 任务 3: 实现主题切换功能
- **Priority**: P0
- **Depends On**: 任务 2
- **Description**:
  - 在设置页面添加主题选择器
  - 实现跟随系统主题功能
  - 主题切换有平滑过渡动画
  - 添加到配置管理
- **Acceptance Criteria Addressed**: AC-6
- **Test Requirements**:
  - `programmatic` TR-3.1: 三种主题选项都能正常切换
  - `programmatic` TR-3.2: 跟随系统功能正常
  - `human-judgment` TR-3.3: 切换动画流畅

## [x] 任务 4: 扩展设置选项
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 添加窗口大小设置
  - 添加启动动画开关
  - 添加音效开关
  - 添加更多下载设置选项
  - 添加更多游戏设置选项（如全屏、分辨率等）
  - 更新配置键定义
- **Acceptance Criteria Addressed**: AC-7
- **Test Requirements**:
  - **programmatic** TR-4.1: 所有新设置项能正确保存
  - **human-judgment** TR-4.2: 设置页面布局美观
  - **programmatic** TR-4.3: 设置能正确生效

## [x] 任务 5: 增强下载引擎镜像源容错
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 添加多个备用BMCLAPI镜像源
  - 实现镜像源健康检查
  - 实现自动切换失败的镜像源
  - 添加镜像源手动选择功能（可选）
  - 优化错误提示
- **Acceptance Criteria Addressed**: AC-8
- **Test Requirements**:
  - `programmatic` TR-5.1: 镜像源切换逻辑正常
  - `programmatic` TR-5.2: 失败后能自动切换到可用源
  - `human-judgment` TR-5.3: 错误提示清晰友好

## [x] 任务 6: 实现资源中心数据模型和API接口
- **Priority**: P1
- **Depends On**: 任务 5（可选，但建议先做）
- **Description**:
  - 创建模组/资源包数据模型
  - 实现CurseForge API客户端
  - 实现Modrinth API客户端
  - 统一API接口抽象
  - 实现缓存机制
- **Acceptance Criteria Addressed**: AC-1, AC-2
- **Test Requirements**:
  - `programmatic` TR-6.1: 数据模型正确
  - `programmatic` TR-6.2: API调用正常
  - `programmatic` TR-6.3: 双源都能获取数据

## [x] 任务 7: 实现资源中心核心功能
- **Priority**: P1
- **Depends On**: 任务 6
- **Description**:
  - 实现模组搜索和筛选
  - 实现资源包搜索和筛选
  - 实现内容详情展示
  - 实现下载功能集成
  - 实现已安装内容的管理（启用/禁用/删除）
- **Acceptance Criteria Addressed**: AC-1, AC-2
- **Test Requirements**:
  - `programmatic` TR-7.1: 搜索功能正常
  - `programmatic` TR-7.2: 筛选功能正常
  - `programmatic` TR-7.3: 下载能正确集成现有下载引擎

## [x] 任务 8: 实现资源中心UI页面
- **Priority**: P1
- **Depends On**: 任务 7
- **Description**:
  - 创建资源中心主页面
  - 实现模组列表和详情页
  - 实现资源包列表和详情页
  - 实现已安装内容管理页
  - 保持蔚蓝档案UI风格
- **Acceptance Criteria Addressed**: AC-1
- **Test Requirements**:
  - `human-judgment` TR-8.1: UI符合设计规范
  - `programmatic` TR-8.2: 页面导航正常
  - `human-judgment` TR-8.3: 用户体验流畅

## [x] 任务 9: 实现微软OAuth2登录 - 基础框架
- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 实现OAuth2授权码流程（带PKCE）
  - 实现微软登录页面（或嵌入式浏览器）
  - 实现令牌获取和刷新
  - 实现令牌加密存储
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-9.1: OAuth流程能正常启动
  - `programmatic` TR-9.2: 令牌能正确获取和存储
  - `programmatic` TR-9.3: 敏感信息加密存储

## [x] 任务 10: 实现登录UI和账户管理
- **Priority**: P1
- **Depends On**: 任务 9
- **Description**:
  - 创建登录页面和账户选择UI
  - 实现微软登录按钮
  - 实现登录进度显示
  - 实现账户选择（支持多账户）
  - 实现账户信息显示（头像、用户名）
  - 实现登出功能
  - 更新account_manager支持多账户
  - 集成到主界面
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `human-judgment` TR-10.1: 登录UI符合设计规范
  - `human-judgment` TR-10.2: 账户选择界面美观
  - `programmatic` TR-10.3: 多账户功能正常工作

## [x] 任务 11: 实现皮肤/披风管理
- **Priority**: P1
- **Depends On**: 任务 10
- **Description**:
  - 实现皮肤显示
  - 实现皮肤上传和更换
  - 实现披风显示和管理
  - 添加皮肤预览功能
- **Acceptance Criteria Addressed**: AC-4
- **Test Requirements**:
  - `programmatic` TR-11.1: 皮肤能正确显示
  - `programmatic` TR-11.2: 皮肤上传功能正常
  - `human-judgment` TR-11.3: UI体验良好

## [x] 任务 12: 集成资源中心到主界面
- **Priority**: P2
- **Depends On**: 任务 8
- **Description**:
  - 在侧边栏添加资源中心入口
  - 更新主界面导航
  - 确保与现有页面风格一致
- **Acceptance Criteria Addressed**: AC-1
- **Test Requirements**:
  - `programmatic` TR-12.1: 导航入口正常工作
  - `human-judgment` TR-12.2: 整体风格一致

## [ ] 任务 13: 整体测试和优化
- **Priority**: P2
- **Depends On**: 任务 3, 4, 5, 8, 11, 12
- **Description**:
  - 完整功能测试
  - 性能优化
  - Bug修复
  - 最终代码审查
  - 更新文档
- **Acceptance Criteria Addressed**: 所有AC
- **Test Requirements**:
  - `programmatic` TR-13.1: 所有功能正常工作
  - `programmatic` TR-13.2: 无严重Bug
  - `human-judgment` TR-13.3: 用户体验良好

