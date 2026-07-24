# 0005: 引入 Riverpod 状态管理

## 状态

已接受

## 上下文

ARCHITECTURE.md §9.1 承诺使用 Riverpod 状态管理，但实际未引入：

- `pubspec.yaml` 仅有 `provider: ^6.1.2`，没有 `flutter_riverpod`
- 全代码无 `ConsumerStatefulWidget` / `ConsumerWidget`（0 处）
- 主页 `ba_main_page.dart` 一个 State 持有 7 个 `setState` 缓存变量
- 其他页面同样依赖 `setState` 局部缓存

## 决策

引入 `flutter_riverpod`，提前到阶段 2 开头落地（在结构修复之后、UI 拆分之前）。

### 引入时机

- 阶段 1 结构修复完成后立即引入
- 在 UI 拆分（阶段 4.2）前完成迁移
- 避免 setState → Provider 重复迁移

### 迁移策略

1. 加依赖：`flutter_riverpod: ^2.5.1`
2. `main.dart` 包裹 `ProviderScope`
3. 新建 `lib/src/di/providers.dart` 定义核心 Provider：
   - `themeManagerProvider`（ChangeNotifierProvider）
   - `accountProvider`（FutureProvider）
   - `instanceListProvider`（FutureProvider）
   - `downloadQueueProvider`（StateNotifierProvider）
4. 迁移 `ba_main_page.dart` 为 `ConsumerStatefulWidget`
5. 新代码强制 `ConsumerWidget`（写入 CLAUDE.md 规则）

### Provider 选择指南

| 状态类型 | 示例 | Provider |
|---------|------|----------|
| 可变集合 | 下载队列 | StateNotifierProvider |
| 异步数据 | 版本列表 | FutureProvider |
| 流 | 进度事件 | StreamProvider |
| 服务依赖 | AuthManager | Provider |
| 派生状态 | 过滤后实例 | Provider (derived) |

## 替代方案

- **保持 Provider + setState**：改动最小但 setState 泛滥问题不解决
- **混合方案（先不动）**：只用已有 ViewModel 拆分巨型 State，状态管理方向延后

## 影响

### 正面
- 编译时类型安全
- 无需 BuildContext 依赖
- 细粒度状态订阅，减少不必要重建
- 与 ARCHITECTURE.md §9.1 对齐

### 负面
- 学习曲线（团队需理解 Riverpod 概念）
- 迁移成本（现有 Provider 代码需更新）
- 新增依赖（`flutter_riverpod`）

## 参考

- `pubspec.yaml` - 依赖配置
- `lib/src/di/providers.dart` - Provider 定义（待创建）
- `lib/src/ui/pages/ba_main_page.dart` - 首页迁移目标
- `ARCHITECTURE.md §9` - 状态管理规范
