# assay

给 Claude Code / Codex 的数据看板分析插件。它只含**规则**：先认清问的是哪个看板、先取口径再取数、
`null` 不是 0、401 不是没数据、绝不跨看板做算术、排除口径问题后数字仍不对就去关联仓溯源并跟进到解决（先查已有 PR / issue 再开；有仓库权限、你也点头才替你开，没有权限就把链接和正文给你）。

它**不含**任何看板地址、指标口径、工具清单 —— 这些由每个看板自己的 `describe_dashboard` 工具在鉴权后给出。
任何实现了看板约定（见仓库根的 `PROFILE.md`）的 MCP 服务器都能用同一个插件。

安装与连接看板的步骤见仓库根的 `README.md`。

## 文件

```
.claude-plugin/plugin.json          Claude 的插件说明书
.codex-plugin/plugin.json           Codex 的说明书（内容几乎一样）
skills/ask/SKILL.md                 assay:ask：分析规则（核心），向看板提问、按看板口径作答；问数据时自动触发
skills/connect/SKILL.md             assay:connect：连接看板；连不上 / 授权过期 / 换电脑时怎么办
skills/list/SKILL.md                assay:list：列出连上的看板（只读）
scripts/check-plugin-is-generic.sh  守卫：插件里不得出现地址、指标名、阈值
```
