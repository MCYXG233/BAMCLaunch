# Minecraft × 蔚蓝档案 清新桌面风 UI 设计 - 实现计划

## [x] Task 1: 优化配色系统和主题
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 完善现有配色方案，确保符合Minecraft × 蔚蓝档案风格
  - 优化中性色系统，杜绝纯黑纯白，降低视觉疲劳
  - 调整强调色饱和度，适配清新风格
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `human-judgment` TR-1.1: 配色方案符合Minecraft × 蔚蓝档案风格
  - `human-judgment` TR-1.2: 视觉效果清新舒适，无视觉疲劳
- **Notes**: 参考现有colors.dart文件进行优化

## [x] Task 2: 实现左侧固定侧边栏
- **Priority**: P0
- **Depends On**: Task 1
- **Description**: 
  - 实现左侧固定宽度侧边栏
  - 设计核心功能入口（主页、版本管理、模组管理、整合包、服务器、账户、设置）
  - 实现选中态的方块化高亮与渐变效果
  - 添加悬浮微动效
- **Acceptance Criteria Addressed**: AC-1, AC-5
- **Test Requirements**:
  - `human-judgment` TR-2.1: 侧边栏布局正确，固定宽度
  - `human-judgment` TR-2.2: 选中态效果明显，悬浮有动效
  - `human-judgment` TR-2.3: 支持桌面端原生交互
- **Notes**: 参考现有sidebar.dart文件进行优化

## [x] Task 3: 开发全自定义标题栏
- **Priority**: P0
- **Depends On**: Task 1
- **Description**: 
  - 实现全自定义标题栏
  - 适配不同平台习惯（Mac红绿灯在左，Win窗口控制在右）
  - 按钮采用像素风图标
  - 添加悬浮渐变效果
- **Acceptance Criteria Addressed**: AC-2, AC-5
- **Test Requirements**:
  - `human-judgment` TR-3.1: 标题栏在不同平台显示正确
  - `human-judgment` TR-3.2: 按钮图标为像素风格
  - `human-judgment` TR-3.3: 悬浮时有渐变效果
- **Notes**: 参考现有custom_title_bar.dart文件进行优化

## [x] Task 4: 优化主内容区布局
- **Priority**: P0
- **Depends On**: Task 1, Task 2
- **Description**: 
  - 实现面包屑导航 + 标签页切换 + 卡片式布局
  - 确保内容区留白充足
  - 卡片圆角8px，边缘加入1px像素线条点缀
- **Acceptance Criteria Addressed**: AC-1, AC-3
- **Test Requirements**:
  - `human-judgment` TR-4.1: 布局结构清晰，符合桌面端操作习惯
  - `human-judgment` TR-4.2: 卡片设计符合Minecraft × 蔚蓝档案风格
  - `human-judgment` TR-4.3: 留白充足，视觉舒适
- **Notes**: 参考现有main_layout.dart文件进行优化

## [x] Task 5: 优化按钮组件
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 实现方块化圆角按钮
  - 主按钮采用主色渐变
  - 悬浮时有轻微放大与亮度提升
  - 点击有按压反馈
  - 图标采用线性+像素点缀的自研图标
- **Acceptance Criteria Addressed**: AC-3, AC-5
- **Test Requirements**:
  - `human-judgment` TR-5.1: 按钮外观符合Minecraft × 蔚蓝档案风格
  - `human-judgment` TR-5.2: 交互反馈流畅自然
  - `human-judgment` TR-5.3: 图标风格统一
- **Notes**: 参考现有bamc_button.dart文件进行优化

## [x] Task 6: 优化输入框组件
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 实现圆角矩形描边输入框
  - 聚焦时有主色柔和发光效果
  - 前缀图标为像素风
- **Acceptance Criteria Addressed**: AC-3, AC-5
- **Test Requirements**:
  - `human-judgment` TR-6.1: 输入框外观符合风格要求
  - `human-judgment` TR-6.2: 聚焦效果明显且美观
  - `human-judgment` TR-6.3: 图标风格统一
- **Notes**: 参考现有bamc_input.dart文件进行优化

## [x] Task 7: 优化列表组件
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 实现卡片式列表项
  - 悬浮有背景色变化
  - 选中有主色边框
  - 全量支持右键菜单
  - 支持键盘方向键导航
- **Acceptance Criteria Addressed**: AC-3, AC-5
- **Test Requirements**:
  - `human-judgment` TR-7.1: 列表项外观符合风格要求
  - `human-judgment` TR-7.2: 交互反馈流畅自然
  - `human-judgment` TR-7.3: 支持右键菜单和键盘导航
- **Notes**: 参考现有bamc_list.dart文件进行优化

## [x] Task 8: 优化进度条组件
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 融合MC经验条的方块化填充设计
  - 整体为圆角清新风格
  - 支持像素化进度动画
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `human-judgment` TR-8.1: 进度条外观符合Minecraft × 蔚蓝档案风格
  - `human-judgment` TR-8.2: 动画效果流畅自然
- **Notes**: 参考现有bamc_progress_bar.dart文件进行优化

## [x] Task 9: 优化弹窗组件
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 实现毛玻璃背景居中弹窗
  - 标题栏带像素风关闭按钮
  - 内容区留白充足
- **Acceptance Criteria Addressed**: AC-3, AC-5
- **Test Requirements**:
  - `human-judgment` TR-9.1: 弹窗外观符合风格要求
  - `human-judgment` TR-9.2: 交互流畅自然
- **Notes**: 参考现有dialogs目录下的文件进行优化

## [x] Task 10: 优化动效设计
- **Priority**: P1
- **Depends On**: All previous tasks
- **Description**: 
  - 实现页面切换淡入淡出+轻微位移
  - 卡片悬浮有轻微上浮与阴影加深
  - 添加启动时的像素加载动画
  - 实现下载完成的方块弹出动效
  - 按钮点击的像素颗粒反馈
- **Acceptance Criteria Addressed**: AC-4
- **Test Requirements**:
  - `human-judgment` TR-10.1: 动效流畅，符合60fps标准
  - `human-judgment` TR-10.2: 动效风格统一，符合Minecraft × 蔚蓝档案风格
- **Notes**: 参考现有effects.dart文件进行优化