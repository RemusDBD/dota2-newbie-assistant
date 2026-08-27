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
- 没有查询：`依据：7.41e 版本规则与本局阵容机制判断。`

## 禁止表述

- 没有原始数据时写精确百分比、样本量或“胜率提升”。
- 把全分段总体对位数据说成新手分段数据。
- 把物品购买率写成物品导致胜率提高。
- 用职业比赛的一局出装证明新手应该照抄。
- 声称 Liquipedia 或 OpenDota 推荐了某条由模型自行推导的结论。

## 缓存新鲜度

- `references/data/cache-metadata.json` 记录抓取时间。
- 7天以内可称“近期缓存”；超过7天必须标为“缓存可能陈旧”。
- 更新 Dota 版本后，即使缓存不到7天也要重新抓取，并人工复核版本改动。
- 极速语音模式不因缓存过期而等待网络，只降低证据表述强度。
- OpenDota 查询超时或限流时，明确写“实时统计暂不可用”，继续用已标注的版本规则与阵容机制回答，不反复重试。
