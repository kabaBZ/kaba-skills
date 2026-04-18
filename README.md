# kaba-skills

一个面向 Claude Code 的个人技能集合仓库，当前主要围绕 `raw -> wiki` 的知识整理工作流构建，适合把网页、论文、仓库文档、播客转录、截图文字等原始资料整理为可沉淀到个人知识库中的 Markdown 内容。

## 仓库定位

- 这是一个 **Claude Code skills/plugin collection**，不是常规应用项目。
- 技能入口由 `.claude-plugin/plugin.json` 定义，技能根目录是 `./skills`。
- `.claude-plugin/marketplace.json` 提供插件市场元数据。
- 仓库几乎没有共享运行时代码；每个技能都以 `skills/<skill-name>/SKILL.md` 的形式独立定义。
- 当前技能说明以中文为主，面向中文知识整理场景。

## 当前包含的技能

### `/wiki-workflow`

一个面向多 source 的工作流技能，用于把多个原始信息源串成统一入库流程。

特点：
- 为多个 source 启动多个 subagent 并行 ingest
- 在 ingest 完成后按顺序串行 digest，避免共享写入冲突
- 在 digest 后统一运行 lint 审计
- 把“是否修复 lint 问题”的决定交给用户

### `/raw-ingest`

将原始资料高保真清洗后整理为适合保存到 `raw/` 的 Markdown。

适用输入：
- 网页
- 论文
- 仓库文档
- 播客转录
- 截图文字
- 手动剪藏内容

特点：
- 重点是“保真摄取”，不是泛化总结
- 清洗广告、导航、页眉页脚等噪音，但尽量保留正文信息密度
- 按“内容主题”组织目标路径，而不是按媒体形式分类

### `/wiki-digest`

将 `raw/` 中的原始资料消化为 `wiki/` 中可链接、可复用的原子化知识笔记。

特点：
- 遵循 Atomic Notes 思路拆分知识单元
- 将 `raw/` 视为只读事实来源
- 在 `wiki/` 中创建或更新页面
- 同步更新 `wiki/index.md` 与 `wiki/log.md`

### `/wiki-lint`

对 `wiki/` 做健康检查，发现结构性问题并输出建议清单。

重点检查：
- 页面间明显矛盾
- 明显过时的内容
- 孤立页面
- 被频繁提及但缺少独立页的概念
- 严重缺失 cross-ref 的地方

默认行为是**先报告建议，再等待用户确认**，而不是直接做大规模修改。

## 整体工作流

现在有两种使用方式：

### 手动串行使用

1. `/raw-ingest`：接收并清洗原始资料，沉淀到 `raw/`
2. `/wiki-digest`：把 `raw/` 内容拆成 `wiki/` 中的原子知识页
3. `/wiki-lint`：检查 `wiki/` 的结构质量、矛盾和缺失链接

### 用 `/wiki-workflow` 统一编排

1. 接收一个或多个 source
2. 为每个 source 并行执行 ingest
3. 对成功产出的 `raw/...` 串行执行 digest
4. 对更新后的 `wiki/` 运行 lint 审计
5. 由用户决定是否继续执行 lint 修复

如果你把这个仓库理解成一个系统，它的核心不是“模块调用关系”，而是“技能提示词驱动的知识加工流水线”。

## 仓库结构

```text
.claude-plugin/          Claude 插件与市场元数据
scripts/                 维护脚本
skills/                  技能定义目录
  wiki-workflow/
    SKILL.md
  raw-ingest/
    SKILL.md
  wiki-digest/
    SKILL.md
  wiki-lint/
    SKILL.md
```

## 开发与维护

当前仓库没有现成的：
- build 命令
- lint 命令
- test 命令
- 单测入口

也就是说，这个仓库目前不是通过自动化构建/测试来验证，而是通过检查技能 frontmatter、提示词逻辑以及跨技能约定是否一致来维护。

### 同步并发布某个技能

仓库中现有的维护脚本：

```bash
bash scripts/sync-push.sh <skill-name> "<commit message>"
```

这个脚本会：
- 从本地 `~/.claude/skills/<skill-name>/` 同步内容到仓库镜像中的 `skills/<skill-name>/`
- 自动递增 `.claude-plugin/plugin.json` 和 `.claude-plugin/marketplace.json` 的补丁版本号
- 提交并推送变更

脚本依赖：
- `bash`
- `git`
- `rsync`
- `sed`

并假定以下路径已存在：
- `~/.claude/skills/<skill-name>`
- `~/.claude/kaba-skills-repo`

## 维护时需要注意

- 修改技能时，frontmatter 与正文提示词要保持一致。
- 如果改动了插件元数据版本，需要同时更新：
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
- 跨技能的一致性主要体现在这些共享约定上：
  - `raw/`
  - `wiki/`
  - `wiki/index.md`
  - `wiki/log.md`

## 许可证

MIT
