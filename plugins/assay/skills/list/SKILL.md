---
name: list
description: >
  List the dashboards connected in this session (read-only — fetches no data, changes no config).
  Use when the user asks which dashboards are connected or wants an inventory before asking a question.
  列出当前连上的数据看板（只读，不取数、不改配置）。用户问「连了哪些看板」「有哪些看板」时使用。
---

列出当前会话里所有符合看板约定的数据看板。

做法：找到工具表里每一个名字以 `describe_dashboard` 结尾的工具，各调用一次（参数 `section: "capabilities"`），
然后按下面的表格汇总。不要调用任何取数工具，不要修改任何配置。

| 看板 | 环境 | 时区 / 币种 | 能力数 | 数据截至（最保守） |
| --- | --- | --- | --- | --- |

一个都找不到时，说明还没连上任何看板：请用户打开看板网页找「在 AI 里用」或连接说明；
如果之前连过、现在不见了，多半是授权过期，去连接器里重新连一次即可。
