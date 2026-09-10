---
name: connect
description: >
  Connect, reconnect or troubleshoot a dashboard MCP server so its tools show up for the assay
  plugin. Use when the tool list has no describe_dashboard tool, the user says the dashboard or
  its tools disappeared, asks how to connect a dashboard or where its MCP address comes from,
  got a 401 / needs to re-authorize, or is setting up a new machine. Read-only: it diagnoses, then
  walks the user through the connectors UI or prints the mcp add / login commands for them to run.
  Not for questions about the numbers on a dashboard that is already visible — that is assay:ask.
  连接或修复数据看板（只做只读诊断，步骤和命令交给用户自己做）：
  用户说「看不到看板」「工具不见了」「怎么连看板」「MCP 地址哪里拿」「授权过期了」「401」「换了台电脑」时使用；
  看板连着、只是数字有疑问，走 assay:ask。
---

# 连接数据看板

## 原则：MCP 配置只做只读诊断，写操作由用户自己跑

连接这一步你可以执行的命令只有 `claude --version`、`codex --version`、`claude mcp list`、`codex mcp list`。
`mcp add`、`plugin install`、`mcp login` **一律由用户在自己的终端里粘贴执行** —— 理由：
新加的 server 当前会话看不到，用户随后会以为没成功；Codex 的授权命令会阻塞等浏览器，
跑在你这里用户看不到那条链接。把要执行的命令原样打印给他，说明「退出会话、在终端里跑、再重开」。

## 1. 分诊

先看工具表里有没有以 `describe_dashboard` 结尾的工具，再问用户是「从没连过」还是「之前能用」。

| 状态 | 处方 |
| --- | --- |
| 从没连过 | 走第 2 节 |
| 之前能用、工具不见了 | 授权过期。看板的工具会**整个消失**而不是报错。连接器路径：回到连接器里重新连一次；命令行路径：`claude mcp list` / `codex mcp list` 看到条目还在但未连接 → 重新授权（Codex 是 `codex mcp login board-<看板id>`），**不要重新注册** |
| 换了台电脑 | 完整重做第 2 节。旧机器的授权仍然有效，目前无法自助吊销，会随令牌上限自然过期 |

## 2. 连接（给用户的步骤，不替他执行）

**不开终端的路径（推荐给产品经理）：** 打开看板网页 → 找「在 AI 里用」或连接说明 → 复制 MCP 地址 →
Claude 设置 → 连接器 → 添加自定义连接器 → 粘贴 → 用公司邮箱登录 → 授权。

**命令行路径（工程）：**
- Claude Code：`claude mcp add --transport http board-<看板id> <MCP 地址>`，然后重开会话，`/mcp` 里完成授权。
- Codex：先跑版本门（第 3 节），再 `codex mcp add board-<看板id> --url <MCP 地址> --oauth-client-registration dcr`，
  然后 `codex mcp login board-<看板id>`，新开 thread。

MCP 地址只从看板网页或 `describe_dashboard` 返回的 `connect.mcpUrl` 来，本 skill 不含任何地址。

## 3. Codex 的版本门（写操作之前必须过）

`codex --version` **在 PATH 上解析到的那个**必须 ≥ 0.149。
- 低于 0.149：旧版本的配置格式没有 HTTP 看板这一项。危险不在旧版照抄命令（那会安全失败），
  而在**机器上同时装了新旧两个版本**：新版写进去的看板条目会让 PATH 上的旧版读不了整份配置，
  他所有 MCP 服务一起消失。处方是升级并确保 PATH 指向新版；**不要**教用户用绝对路径绕过旧版本。
- 装了插件或加了 server 之后都要重开会话（Codex 是新 thread）。Claude Code 没有重载命令，只能退出重开。

## 4. 常见坑

- 加完 server 当前会话看不到，是正常的：重开会话。
- `already exists`：条目已在，不要再加；若未连接就走重新授权。
- 401 / unauthenticated：重新授权，不是没数据。

## 5. 连上之后：认一下关联仓

重开会话、看板工具出现后（此时由 assay:ask 接手），第一次调 `describe_dashboard` 时除了 `capabilities`，
也看一眼 `repos` 和 `repos.guidance`：那是这个看板关联的代码仓，每条的 `role` / `purpose` 说明它管哪一端，
`guidance` 是部署方写的溯源指引。以后排除口径问题后数字仍不对劲，assay:ask 第 5 节会按 `guidance` 去这些仓溯源、
先查已有 PR / issue、没有再开并跟进到解决，不停在报告上（权限与确认规则以 assay:ask 第 5 节为准）。本 skill 只提醒你 `repos` 存在，不做任何写操作。
`repos` 缺失或 `repos.items` 为空 → 这个看板不支持溯源，问题走 `escalation.contact`；`issueTargetId` 为 `null` 只表示没有缺省的开 issue 目标仓。
