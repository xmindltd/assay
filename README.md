# 介绍

这是一个通用的数据埋点看板 MCP 约定插件外壳(assay)， 插件外壳只是协议，具体的提供哪些数据，如何使用这些数据，如何确认客户端埋点由 MCP 服务器来决定。
仅仅安装此插件不会提供任何的数据查询能力。看板约定（assay profile）参阅 `PROFILE.md`。

所以同一个插件可以接任意多个实现了约定的看板，插件本身几乎不需要更新。

## 使用方式

1. 安装此插件，参考后续的「Claude 桌面端」、「Claude Code」或「Codex」章节
2. 添加 dashboard 服务器的 MCP/自定义连接器并且完成鉴权

然后就可以直接正常使用或者通过指令强制触发了

### Claude 桌面端
打开 Claude 桌面端 -> 设置 → 插件 → Add Marketplace → Add from a repository → 填 `xmindltd/assay` → 安装

### Claude Code CLI

在终端里：

```bash
claude plugin marketplace add xmindltd/assay
claude plugin install assay@boards
```

装完**退出重开**会话

### Codex（≥ 0.149）

```bash
codex plugin marketplace add https://github.com/xmindltd/assay.git
codex plugin add assay@boards
```

装完开一个新 thread。

## 给要实现一个新看板的人

读 `PROFILE.md`。最小工作量是三件事：一个 `describe_dashboard` 工具、每个取数工具的返回带 `board` 与 `asOf`、
鉴权失败走 HTTP 401/403。手册（`playbook` 能力）、关联仓库、兄弟看板都是可选的。
