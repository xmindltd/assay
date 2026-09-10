# 看板约定 `org.xmind.assay-profile` v0.2

让一个通用的分析插件能接任意多个数据看板，靠的是这份约定。它刻意很小。

关键词按 RFC 2119：MUST / SHOULD / MAY。`profileVersion.major = 0` 表示未冻结，允许破坏性变更。

## 只固定四样

| 固定（改了就是新 major） | 自述（看板说了算，插件永不更新） |
| --- | --- |
| 工具名 `describe_dashboard` | 所有其它工具的名字 |
| 返回信封的键名 | 信封里 `data` 的形状 |
| 错误码闭集 + `remedy` 枚举 | 错误文案 |
| 数值原子的形状 | 有哪些指标、叫什么、怎么算 |

**刻意不固定**指标名。一旦把 `revenue.net` 这类名字写进约定，口径完全不同的第二个看板就塞不进来。约定管形状，不管内容。

## 1. `describe_dashboard`

- 名字 MUST 逐字如此；MUST 出现在 `tools/list`；**MUST NOT 受任何配置开关控制**。
- 入参全部可选。`annotations` MUST 为 `{ readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false }`。
- description 第一行 MUST 逐字为：`本服务是一个符合看板约定的数据看板。回答任何数据问题前先调它。`
  第二行 MUST 为 `[<board.displayName>]`。（延迟加载工具的客户端里，这是模型能搜到的唯一发现钩子。）
- 返回 MUST 走 `structuredContent`，`content[0].text` 是同一对象的 JSON 投影。有的客户端见到 `structuredContent` 就丢弃 `content`，所以两者必须是同一份数据。

```jsonc
{
  "profile": "org.xmind.assay-profile",
  "profileVersion": { "major": 0, "minor": 2 },

  "board": {                              // MUST，且与每个数据工具返回的 board 逐字相同
    "id": "example-board",                // ^[a-z][a-z0-9-]{2,15}$，组织内唯一
    "displayName": "Example Board",
    "env": "prod",                        // prod | staging | dev
    "timezone": "UTC+08:00",              // 语义：服务端切自然日用的聚合时区，不是地理时区
    "timezonePolicy": "fixed_offset",     // fixed_offset | iana | per_user
    "currency": "CNY",                    // 语义：报告币种；无金额能力时 null
    "locale": "zh-CN"
  },

  "freshness": { "completeThrough": "2026-09-01", "note": "…", "isAggregate": true },  // 最保守的那条线

  "capabilities": [                       // MUST（可为空数组）
    {
      "capability": "metrics.summary",    // 词表见 §2；私有能力用 x- 前缀
      "tool": "get_kpi_summary",          // 本服务器上的真实工具名
      "params": { "required": ["dimension"], "optional": [] },
      "probeArgs": { "dimension": "yesterday" },   // 让一致性检查器调得动它；start/end 由检查器自己补
      "summary": "一次拿到收入、订单、新增、活跃、转化率的汇总",
      "when": "问「上周收入多少」这类汇总时优先用它",
      "freshness": { "completeThrough": "2026-09-07", "note": null }   // MUST 在能力级
    }
  ],

  "playbooks": [ { "topic": "metrics", "version": 1, "summary": "指标口径陷阱" } ],   // 可空

  "connect": {                            // 人用的接入信息
    "url": "https://example.com/connect",
    "mcpUrl": "https://example.com/api/mcp",
    "minClientVersions": { "codex": "0.149.0" }
  },

  "relatedBoards": [                      // 兄弟看板：只给入口页，不给端点
    { "id": "example-staging", "displayName": "Example (staging)", "connectUrl": "https://example.com/connect" }
  ],

  "repos": {
    "issueTargetId": "server",            // 分不清是哪一端时的缺省目标仓；null = 没有缺省仓（分不清哪一端时不开 issue，走 escalation.contact）
    "guidance": "…",                      // 部署方写给消费者的溯源与跟进指引，消费者 SHOULD 遵循
    "items": [
      { "id": "ios", "role": "ios",       // role：ios | android | server | instrumentation | infra | other
        "visibility": "private", "purpose": "iOS 客户端：埋点在这里上报",
        "webUrl": "https://example.com/org/ios",
        "codeSearchUrl": "https://example.com/org/ios/search?q={q}&type=code",    // 溯源；{q} 放 URL 编码后的关键词
        "issueSearchUrl": "https://example.com/search?q=repo%3Aorg%2Fios+{q}",    // 开新 issue 前先查已有 issue / PR
        "newIssueUrl": "https://example.com/org/ios/issues/new",
        "trackingUrl": "https://example.com/org/ios/issues?q=is%3Aissue" },
      { "id": "server", "role": "server", "visibility": "private", "purpose": "服务端：代理端点与归档",
        "webUrl": "https://example.com/org/server", "newIssueUrl": "https://example.com/org/server/issues/new" }
    ]
  },

  "escalation": { "contact": "#data-oncall", "docsUrl": null }
}
```

**`freshness` MUST 在能力级。** 不同数据线的封口时间不同（订单可能实时，埋点可能 7 天内还会变），一个全局值会让每条回答首行的「数据截至」都写错。顶层的那份是最保守的线，标 `isAggregate: true`。

`repos` 的语义：`role` 让消费者按证据指向的那一端选仓，分不清用 `issueTargetId`；`issueSearchUrl` 用于开新 issue 前先查已有的；`guidance` 是部署方的指引，消费者 SHOULD 遵循；`repos` 缺失或 `items` 为空 = 不支持溯源，问题走 `escalation.contact`。

`connect` / `relatedBoards` / `repos` **MUST NOT 进入 `capabilities`** —— 那个词表的语义是「有工具可调」，这些是「有地方可以去看」。

## 2. 能力词表

`metrics.summary` · `metrics.timeseries` · `metrics.breakdown` · `funnel` · `events.catalog` · `experiments` · `playbook` · `dictionary`

可加不可改。私有能力用 `x-` 前缀。消费者遇到 `x-` 能力 MUST NOT 调用，但当用户问到它覆盖的指标时 MUST 告诉用户该看板有这项专有能力。

消费者 MUST NOT 调用未在 `capabilities` 里声明的工具，`describe_dashboard` 本身除外。

## 3. 数据工具的返回信封

```jsonc
{
  "board": { "id": "example-board", "displayName": "Example Board" },   // MUST
  "asOf": "2026-09-08T11:20:00+08:00",                                  // MUST：数据被算出来的时刻
  "window": { "start": "…", "end": "…", "timezone": "UTC+08:00", "basis": "event_time" },   // SHOULD
  "completeness": { "completeThrough": "…", "partial": true, "reason": "…" },              // SHOULD
  "suppression": { "applied": true, "rule": "k-anonymity", "k": 10, "bucket": "__suppressed__" },  // 做了抑制时 MUST
  "truncation": { "applied": false, "limit": null },                    // SHOULD
  "notes": [],
  "data": { }                                                           // 形状自由
}
```

**数值原子**（比率和金额 MUST 用这个形状）：

```jsonc
{ "value": null, "unit": "ratio", "nullReason": "no_denominator", "numerator": 0, "denominator": 0 }
```

`nullReason` ∈ `no_denominator | suppressed | not_available | out_of_window`。**`null` 与 `0` 必须分得开**：把「这段没有样本」读成「转化率为零」是方向性错误。

金额 MUST 带 `currency`；做过折算的 MUST 带 `fx: { converted, rateBasis: "txn_date"|"period_end"|"fixed", source }`。

## 4. 错误

| code | 含义 | remedy |
| --- | --- | --- |
| `unauthenticated` | 令牌缺失/过期 | `reauthenticate` |
| `forbidden` | 身份不被接受 | `contact_owner` |
| `invalid_argument` | 参数错 | `fix_arguments` |
| `out_of_range` | 超出上限 | `narrow_window` |
| `unavailable` | 上游超时/凭据过期 | `retry_later` |
| `quota_exceeded` | 触发配额 | `wait` |

工具内错误用 `isError: true` + `structuredContent.error = { code, remedy, message }`。

**鉴权失败 MUST 走 HTTP 401/403 + 人话 body，MUST NOT 降级成工具结果。** 401 被模型解释成「数据为空」会给出方向相反的结论。鉴权协议本身不是 MUST：OAuth 2.1 + 动态注册是 SHOULD。

## 5. 一致性

`assay-conformance`（待写）三档退出码：`0` 全绿 · `1` 有 MUST 失败 · `2` 只有 SHOULD 告警。
两条编写守则：禁止 `assert(cond || isError)`；`invalid_argument` 记 SKIP 且非零退出（那是检查器自己的参数错了）。

## 6. 版本

`profileVersion.major` 变化 = 破坏性变更；消费者遇到更高的 major MUST 停用规则并提示更新。
v0 期间破坏性变更需提前通告并双供。**两个独立看板跑通后冻 1.0。**
