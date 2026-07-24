# 0006: GameDirectory / DownloadTask 重命名决策（修订）

## 状态

已接受（修订 ADR-003）

## 上下文

原 ADR-003 计划用 typedef 过渡合并 `GameDirectory` 与 `DownloadTask`。实际分析发现：

### GameDirectory 字段对比

| 字段 | config_models.dart | instance/models.dart |
|------|-------------------|---------------------|
| `dir` / `path` | ✅ `String dir` | ✅ `String path` |
| `name` | ✅ | ✅ |
| `id` | ❌ | ✅ |
| `createdAt` | ❌ | ✅ `DateTime` |
| `updatedAt` | ❌ | ✅ `DateTime` |

两者字段**完全不兼容**，无法用 typedef 过渡。

### DownloadTask 字段对比

| 字段 | download/download_task.dart | shared/models/download_task.dart |
|------|----------------------------|----------------------------------|
| 继承关系 | `Task<String>` | 独立类 |
| `url` | ✅ | ❌ |
| `savePath` | ✅ | ❌ |
| `hash` | ✅ | ❌ |
| `id` | ❌ | ✅ |
| `request` | ❌ | ✅ `DownloadRequest` |
| `status` | ❌ | ✅ `DownloadStatus` |
| `progress` | ❌ | ✅ `DownloadProgress?` |
| `createdAt/startedAt/completedAt` | ❌ | ✅ |

两者字段**完全不兼容**，无法用 typedef 过渡。

## 决策

**不强行合并**，改用**领域命名澄清**：

### GameDirectory 重命名

- `config/config_models.dart` 的 `GameDirectory` → 保留为权威（轻量配置条目）
- `instance/models.dart` 的 `GameDirectory` → 重命名为 `InstanceDirectory`（运行时元数据）

理由：两者语义不同，合并会丢失信息。

### DownloadTask 重命名

- `download/download_task.dart` 的 `DownloadTask` → 保留为权威（`Task<String>` 子类，含 url/savePath）
- `shared/models/download_task.dart` 的 `DownloadTask` → 重命名为 `TrackedDownloadTask`（含进度跟踪的下载任务）

理由：两者职责不同，shared 版本是"下载任务跟踪视图"。

### 实施时机

本阶段（阶段 1）不做改动，避免跨模块大改动。阶段 3.1（shared/models 重组）时统一处理：
1. 先重命名两个重复类，消除歧义
2. 再按 ARCHITECTURE.md §4.1 把权威模型迁入 shared/models/
3. 用 typedef 在旧位置保留过渡（1 个版本）

## 替代方案

- **保留 typedef 过渡**：可消除编译期歧义，但字段不同会导致实例化失败
- **合并为单一类**：会丢失 `id` / `createdAt` 等元数据
- **保留现状**：用户仍会看到两个同名类，造成困惑

## 影响

### 正面
- 消除字段不兼容导致的潜在 bug
- 明确两个类的语义边界
- 避免破坏现有调用代码（重命名而不是合并）

### 负面
- 阶段 1 不解决字段差异问题
- 阶段 3.1 需要更仔细的命名工作

## 参考

- `lib/src/config/config_models.dart` - `GameDirectory`（配置条目，权威）
- `lib/src/instance/models.dart` - `GameDirectory`（实例元数据，待重命名）
- `lib/src/download/download_task.dart` - `DownloadTask`（`Task<String>` 子类，权威）
- `lib/src/shared/models/download_task.dart` - `DownloadTask`（跟踪视图，待重命名）
- `docs/adr/0003-shared-models-reorganization.md` - 原计划（已修订）