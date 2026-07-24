# 0003: shared/models 重组策略

## 状态

已接受

## 上下文

ARCHITECTURE.md §4.1 描述了 `shared/models/` 目录用于跨模块共享模型，但实际未启用：

- `shared/models/` 仅有 1 个文件（`download_task.dart`），且与 `download/download_task.dart` 重复
- 多个领域模型重复定义（GameDirectory、DownloadTask、ResourceManager、ModManager）
- 各模块自行定义模型，导致 import 路径混乱

## 决策

### 分两阶段重组

**阶段 1（当前版本）**：合并重复类，用 typedef 过渡
- `GameDirectory`：保留 `config/config_models.dart` 版本，`instance/models.dart` 改 typedef
- `DownloadTask`：保留 `download/download_task.dart` 版本，`shared/models/download_task.dart` 改 typedef

**阶段 2（下一版本）**：完整重组
- `Account` / `GameInstance` / `Mod` / `DownloadTask` / `GameDirectory` 迁入 `shared/models/`
- 各模块原 `models.dart` 改 `export` 过渡
- `shared/constants/` 迁入 `api_endpoints.dart`、`minecraft_versions.dart`
- `shared/utils/` 迁入 `json_utils.dart`

### 命名规范

- 类名：`GameInstance`（非 `Instance`）、`GameDirectory`（非 `Directory`）
- 文件名：`game_instance.dart`、`game_directory.dart`
- 每个文件一个顶级类

## 替代方案

- **立即重组（一步到位）**：直接迁入 `shared/models/`，改动面大但最干净
- **渐进式（仅迁移重复类）**：改动最小但未解决根因
- **暂不动**：保留现状，靠重命名解决重复

## 影响

### 正面
- 消除类重复定义
- 统一 import 路径
- 符合 ARCHITECTURE.md §4.1 设计

### 负面
- 阶段 1 typedef 过渡期有类型别名警告
- 阶段 2 需要更新大量 import

## 参考

- `lib/src/shared/models/` - 共享模型目录
- `lib/src/config/config_models.dart` - GameDirectory 权威定义
- `lib/src/download/download_task.dart` - DownloadTask 权威定义
- `ARCHITECTURE.md §4.1` - 目录结构规范
