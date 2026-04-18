---
name: wiki-workflow
description: 接收一个或多个原始信息源，使用多个 subagent 并行 ingest，随后将全部 raw 路径一次性传给 wiki-digest 入库并执行 lint，再由用户决定是否修复。
argument-hint: <一个或多个资料来源>
allowed-tools: [Agent, AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash]
---

# 工作流编排

用于把一个或多个原始信息源串成完整知识入库流程：先并行 ingest，再将成功产出的全部 raw 路径一次性传给 `wiki-digest` 做一次 digest，最后做 lint 审计，顺序不可更改，执行 ingest 和 digest 时各自的质量和要求不变，并把“是否修复 lint 问题”的决定交给用户。

你是一个**薄编排层**，不应重写 `raw-ingest`、`wiki-digest`、`wiki-lint` 的内部规则，而应复用它们已有的职责边界：

- `raw-ingest` 负责把单个 source 高保真整理到 `raw/`
- `wiki-digest` 负责把指定 `raw/` 资料沉淀到 `wiki/`
- `wiki-lint` 负责检查 `wiki/` 并先输出建议

## 核心原则

- 多 source 时，只对 ingest 阶段并行化。
- ingest 完成后，将成功产出的全部 `raw/...` 路径一次性传给 `wiki-digest` 执行一次 digest，而不是逐个串行调用。
- lint 默认只做审计，不直接修复。
- 只有在用户明确确认后，才进入 lint 修复阶段。
- 如果某些 source ingest 失败，先汇总成功项与失败项，再决定是否继续处理成功项。

## 输入处理

当用户调用 `/wiki-workflow` 时：

1. 识别输入中包含的一个或多个 source。
2. 每个 source 可以是：链接、摘录、文件路径、截图文字、手动说明。
3. 如果用户给的是混合输入，按 source 粒度拆分。
4. 如果 source 边界不清晰，先澄清，再执行。

## 执行流程

### 阶段 1：并行 ingest

1. 为每个 source 启动一个 subagent。
2. 每个 subagent 只处理一个 source，并遵循 `raw-ingest` 的约束：
   - 高保真摄取
   - 清洗噪音但不过度改写
   - 直接写入 `raw/`
   - 返回结构化结果
3. 要求每个 subagent 至少返回：
   - source 标识
   - 写入的 `raw/...` 路径
   - 标题 / 来源信息
   - 是否抓取完整
   - 缺失说明（若有）

### 阶段 2：汇总 ingest 结果

1. 汇总所有 source 的 ingest 结果。
2. 如果存在失败项：
   - 明确列出失败 source 与原因
   - 明确列出成功 source 与对应 `raw/...` 路径
   - 询问用户是只继续成功项，还是先停下
3. 如果全部成功，则继续进入 digest。

### 阶段 3：一次性 digest

1. 将成功产出的全部 `raw/...` 路径一次性传给 `wiki-digest`，执行一次 digest。
2. 调用时应显式传入这些 raw 路径，不要依赖“最近文件”推断。
3. digest 输出应汇总返回：
   - 新建或更新了哪些 `wiki/...` 页面
   - 是否更新了 `wiki/index.md`
   - 是否更新了 `wiki/log.md`
4. 这次 digest 完成后，再进入 lint。

### 阶段 4：lint 审计

1. 对本次变更后的 `wiki/` 运行一次 lint 审计。
2. 优先输出结构化问题清单，而不是直接修复。
3. 将 lint 结果整理成清晰摘要：
   - 发现了哪些问题
   - 涉及哪些页面
   - 建议的修复动作是什么

### 阶段 5：用户决定是否修复

在 lint 审计后，必须显式询问用户下一步：

- 仅查看报告，不修复
- 修复推荐项
- 指定修复部分问题

只有在用户明确确认后，才允许继续执行修复。

## 输出要求

- 默认输出中文。
- 每个阶段都给出清晰的阶段性结果。
- 多 source 场景下，结果应按 source 逐项汇总。
- 不要把 ingest、digest、lint 的规则重新发明一遍；应复用既有技能契约。
- 若用户未确认，不要执行 lint 修复。

## 推荐交互形式

推荐按如下节奏组织输出：

1. source 列表确认
2. ingest 结果汇总
3. 批量 digest 结果汇总
4. lint 审计摘要
5. 询问是否修复

如果用户已经明确说“lint 后自动修复”，也要先把发现的问题摘要展示给用户，再执行修复。