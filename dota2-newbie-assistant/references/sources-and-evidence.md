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
- `/api/heroes/{hero_id}/matchups`：指定英雄的总体对位记录。
- `/api/heroes/{hero_id}/itemPopularity`：物品流行度原始计数。

这些公共端点不自动等于“当前版本、新手段位、指定位置”。除非查询确实包含这些筛选条件，否则必须写明范围限制。

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
