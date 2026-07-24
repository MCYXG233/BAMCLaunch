## Agent Skills

### 交流语言
- 与用户的所有对话、评论、Issue 回复、PR 描述，**必须使用中文**。
- 执行过程中遇到任何模糊、异常、冲突或需要决策的情况，**必须先暂停并使用中文向用户提问**，禁止自行假设或跳过。

### Issue Tracking
- 仓库：`MCYXG233/BAMCLaunch`
- 工具：`gh` CLI  
  （常用命令：`gh issue list`, `gh issue view`, `gh issue create`, `gh issue comment`）
- 详细流程见 `docs/agents/issue-tracker.md`

### Git 提交与推送规范
- 每次代码修改完成后，**必须使用中文编写 commit message**，清晰说明本次改动的原因和内容。
- 格式建议：`<类型>：<中文简述>`（例如 `修复：登录页按钮点击无响应`）
- 推送前必须执行 `git pull --rebase` 以避免冲突，推送时需确认 `git push` 成功。
- 若推送失败（如冲突、网络问题），**必须立即暂停并使用中文向用户报告**，不得静默重试或跳过。
- 推送后需将 commit link 或 hash 回复给用户，以便追溯。

### Triage & Labeling
- 标准标签：`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`
- Agent 必须按 `docs/agents/triage-labels.md` 中定义的规则使用这些标签  
  （例如：收到新 Issue 先打 `needs-triage`，经分析后转为 `ready-for-agent` 或 `ready-for-human`）
- 禁止随意添加未在文档中列出的标签

### Domain Knowledge
- 项目上下文集中存放在仓库根目录的 `CONTEXT.md` 中
- 架构决策记录在 `docs/adr/` 目录下
- Agent 在执行任何非简单修改前，**必须先查阅** `CONTEXT.md` 及相关 ADR
- 完整说明见 `docs/agents/domain.md`