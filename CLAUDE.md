# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库定位

- 这是一个 Claude Code 技能/插件集合仓库，不是常规应用或库项目。
- 技能入口由 `.claude-plugin/plugin.json` 定义，其中 `skills: "./skills"` 指向技能根目录。
- `.claude-plugin/marketplace.json` 是面向插件市场的包装元数据；其版本号需要与 `.claude-plugin/plugin.json` 保持同步。
- 每个技能都以 `skills/<skill-name>/SKILL.md` 的形式独立存在。仓库几乎没有共享运行时代码，技能行为主要由 frontmatter（如 `name`、`description`、`argument-hint`、`allowed-tools`）和后续 Markdown 提示词共同决定。
- 当前技能内容以中文为主；除非用户明确要求，否则应保持中文说明与术语体系一致。

## 常用命令

截至 2026-04-18，这个仓库中不存在常规的构建、Lint、测试入口：

- 没有 `package.json`
- 没有 `pyproject.toml`
- 没有 `Cargo.toml`
- 没有 `go.mod`
- 没有 `Makefile`

因此本仓库当前没有可验证的 build / lint / test 命令，也没有“运行单个测试”的现成方式。

已存在、且与日常维护直接相关的命令是：

```bash
bash scripts/sync-push.sh <skill-name> "<commit message>"
```

这个脚本会：

- 将本地 `~/.claude/skills/<skill-name>/` 同步到仓库镜像中的 `skills/<skill-name>/`
- 自动递增 `.claude-plugin/plugin.json` 与 `.claude-plugin/marketplace.json` 的补丁版本号
- 提交并推送变更

脚本依赖以下外部路径已存在：

- `~/.claude/skills/<skill-name>`
- `~/.claude/kaba-skills-repo`

## 高层结构与工作流

这个仓库的核心不是“代码模块调用关系”，而是“技能提示词驱动的知识处理流水线”。当前已经形成一个由 4 个技能组成的体系：

1. `skills/wiki-workflow/SKILL.md`
   - 顶层工作流编排技能
   - 接收一个或多个 source
   - 使用多个 subagent 并行执行 ingest
   - 对成功产出的 `raw/...` 串行执行 digest
   - 统一运行 lint 审计，并把是否修复交给用户决定

2. `skills/raw-ingest/SKILL.md`
   - 负责接收网页、论文、仓库文档、播客转录、截图文字等原始资料
   - 目标是高保真清洗后落到 `raw/`
   - 分类原则按“内容主题”而不是“媒体形式”组织
   - 在工作流模式下，一次只处理一个 source，并返回结构化 ingest 结果

3. `skills/wiki-digest/SKILL.md`
   - 将 `raw/` 中的原始资料进一步拆解为 `wiki/` 中可复用、可链接的原子知识笔记
   - 明确要求更新 `wiki/index.md` 与 `wiki/log.md`
   - 将 `raw/` 视为只读事实来源，实际写操作应限制在 `wiki/`
   - 在工作流模式下应只处理显式传入的单个 `raw/...` 路径

4. `skills/wiki-lint/SKILL.md`
   - 对 `wiki/` 做健康检查，查找矛盾、过时内容、孤立页面与缺失 cross-ref
   - 分为 audit mode 和 repair mode
   - 默认先输出建议清单，再在用户确认后做较大范围修改

理解这个仓库时，最重要的“大图景”是：

- 仓库的主要产物是技能定义，不是可执行程序
- 修改 `SKILL.md` 就是在直接修改技能行为
- 大多数变更应局限在单个技能内，除非你在调整技能之间共享的工作流约定
- 跨技能一致性主要体现在共享目录与流程契约上：`raw/`、`wiki/`、`wiki/index.md`、`wiki/log.md`
- 多 source 处理时，推荐优先走 `wiki-workflow`；并行只发生在 ingest，digest 必须保持串行

## 编辑时应关注的约束

- 修改技能时，frontmatter 与正文提示词必须保持一致；例如技能名、允许工具、输入提示发生变化时，frontmatter 也要同步更新。
- 因为没有自动化测试，校验方式主要是文本级校验：确认 frontmatter 结构有效、目录命名一致、不同技能对同一工作流的承诺不冲突。
- 如果改动涉及插件元数据版本，需同时更新 `.claude-plugin/plugin.json` 和 `.claude-plugin/marketplace.json`。

## README 对齐

`README.md` 现在已经同步记录了 4 个技能的定位、整体工作流与维护方式。修改技能职责或工作流关系时，应同步检查 `README.md` 与本文件是否仍然一致。