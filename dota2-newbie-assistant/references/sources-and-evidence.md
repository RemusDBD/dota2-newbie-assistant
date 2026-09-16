# 数据来源与证据规则

## 来源优先级

1. **Valve / Dota 2 官方**：版本号、补丁、英雄和装备改动。https://www.dota2.com/patches/
2. **OpenDota**：公开比赛与录像解析形成的英雄、对位、物品和比赛统计。https://docs.opendota.com/
3. **Liquipedia Dota 2**：版本历史、机制、物品与英雄页面的交叉核对。https://liquipedia.net/dota2/Main_Page

Liquipedia 自动访问必须使用其 API，不能抓取生成后的 HTML；尽可能缓存，并按 CC BY-SA 要求注明来源。条款：https://liquipedia.net/api-terms-of-use

## OpenDota 用法

本 Skill 的缓存脚本使用：

- `/api/heroStats`：英雄总体公开统计快照。
- `/api/constants/heroes`：英雄 ID 与基础常量。
- `/api/constants/items`：物品 ID 与基础常量。
- `/api/constants/hero_abilities`：英雄与技能标识的映射。
- `/api/constants/abilities`：技能名称、说明和部分结构化常量。
- `/api/heroes/{hero_id}/matchups`：指定英雄的总体对位记录。
- `/api/heroes/{hero_id}/itemPopularity`：物品流行度原始计数。

赛后数据复盘使用：

- `/api/matches/{match_id}`：单场比赛的结算字段，以及在已解析时返回的购买、分钟经济/经验、正反补、团战、视野和目标事件。
- `scripts/get-match-review-data.ps1`：按比赛 ID 与英雄名称选择目标玩家，把 OpenDota 返回值压缩成适合复盘的中文英雄/物品、经济时间线和关键事件 JSON。

复盘查询示例：

```powershell
& "scripts\get-match-review-data.ps1" -MatchId 8461956309 -HeroName "主宰"
```

脚本先读取比赛，尚未解析时默认通过 `POST /api/request/{match_id}` 自动提交一次解析并等待，再读取最新比赛数据；具体状态、等待上限和继续任务方式见 [match-review.md](match-review.md)。录像由 OpenDota 解析，本地不下载。解析未完成时如实报告原因；`dataStatus=basic` 时只使用结算数据，只有实际返回时间线字段时才进行对应的精确时间线分析。

这些公共端点不自动等于“当前版本、新手段位、指定位置”。除非查询确实包含这些筛选条件，否则必须写明范围限制。

技能常量可以帮助核对当前缓存中的名称和说明，但不能证明某套加点最优。加点仍要依据本局位置、对线压力、命石/分支和阵容功能判断；精确技能交互应优先用当前版本官方信息交叉核对。

需要只读取一名英雄的技能而不把完整常量文件载入上下文时，运行：

```powershell
& "scripts\get-hero-abilities.ps1" -HeroName luna
```

也可以传入 OpenDota 英雄 ID，例如 `-HeroId 48`。输出中的技能、天赋和命石仍是缓存元数据，不能直接当作推荐加点。

## 可以怎样表述

- 已查询且有范围：`OpenDota 快照（抓取于 2026-08-27）中，A 对 B 共 N 场，A 胜率约 X%。该数据未按本局位置和玩家分段筛选。`
- 只看到购买次数：`该物品在 OpenDota 物品流行度中较常出现，但购买率不能证明它在本局一定更优。`
- 单场复盘事实：`OpenDota 本局解析记录显示，目标英雄在14:08购买了原力法杖。`
- 单场复盘推断：`结合14～20分钟经济停滞与两次低贡献团战，判断这段时间的参团或资源选择可能是主要改进点。`
- 没有查询：`依据：7.41f 版本规则与本局阵容机制判断。`

## 禁止表述

- 没有原始数据时写精确百分比、样本量或“胜率提升”。
- 把全分段总体对位数据说成新手分段数据。
- 把物品购买率写成物品导致胜率提高。
- 用职业比赛的一局出装证明新手应该照抄。
- 声称 Liquipedia 或 OpenDota 推荐了某条由模型自行推导的结论。
- 把最终正补、GPM 或最终装备反推成不存在的10分钟数据和购买时间。
- 没有位置轨迹时断言某名玩家“正在某路刷钱”“没有传送”或“站位错误”。

## 缓存新鲜度

- `references/data/cache-metadata.json` 记录抓取时间。
- 7天以内可称“近期缓存”；超过7天必须标为“缓存可能陈旧”。
- 更新 Dota 版本后，即使缓存不到7天也要重新抓取，并人工复核版本改动。
- 极速语音模式不因缓存过期而等待网络，只降低证据表述强度。
- OpenDota 查询超时或限流时，明确写“实时统计暂不可用”，继续用已标注的版本规则与阵容机制回答，不反复重试。

## 7.41f 官方覆盖层

`data/patchnotes-7.41f-schinese.json` 是Valve原始补丁快照；先读 `patch-7.41f.md` 再给新版建议。`get-hero-abilities.ps1` 的 `officialPatchChanges` 提供对应英雄的官方差异，优先于冲突的第三方技能说明。`constantsPatchVerified=false` 表示第三方常量尚未被整体确认为当前版本；抓取日期只证明下载时间。
