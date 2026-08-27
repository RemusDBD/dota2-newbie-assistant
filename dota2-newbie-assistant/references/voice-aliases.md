# 中文语音简称与纠错

先利用 Dota 语境纠正常见转写，再用一句“按 X 识别”回显。不要因为近音就修改用户明确拼出的英文英雄名。

## 常见简称

- 敌法、AM → 敌法师（Anti-Mage）
- 斧王、辅王 → 斧王（Axe）
- 冰魂 → 远古冰魄（Ancient Apparition）
- 火猫 → 灰烬之灵（Ember Spirit）
- 电魂 → 剃刀（Razor）
- 蓝猫 → 风暴之灵（Storm Spirit）
- 紫猫 → 虚无之灵（Void Spirit）
- 土猫 → 大地之灵（Earth Spirit）
- 水人 → 变体精灵（Morphling）
- 小黑 → 卓尔游侠（Drow Ranger）
- 白虎、米拉娜 → 米拉娜（Mirana）
- 火女、莉娜 → 莉娜（Lina）
- 冰女 → 水晶室女（Crystal Maiden）
- 骨法 → 帕格纳（Pugna）
- 骨弓、小骷髅 → 克林克兹（Clinkz）
- 蚂蚁 → 编织者（Weaver）
- 猴子 → 幻影长矛手（Phantom Lancer）
- 猴王、大圣 → 齐天大圣（Monkey King）
- 小鱼 → 斯拉克（Slark）
- 大鱼 → 斯拉达（Slardar）
- 人马 → 半人马战行者（Centaur Warrunner）
- 炼金 → 炼金术士（Alchemist）
- 全能 → 全能骑士（Omniknight）
- 船长 → 昆卡（Kunkka）
- 末日 → 末日使者（Doom）
- 火枪 → 狙击手（Sniper）
- 飞机 → 矮人直升机（Gyrocopter）
- 拍拍 → 熊战士（Ursa）
- 虚空 → 虚空假面（Faceless Void）；若同时出现“紫猫”则不要混淆
- 小小 → 小小（Tiny）
- 老鹿 → 拉席克（Leshrac）
- 老奶奶 → 电炎绝手（Snapfire）
- 尸王 → 不朽尸王（Undying）
- 大树 → 树精卫士（Treant Protector）
- 小鹿 → 魅惑魔女（Enchantress）
- 萨尔 → 干扰者（Disruptor）
- 小Y → 暗影萨满（Shadow Shaman）
- 毒狗 → 暗影恶魔（Shadow Demon）
- 毒龙 → 冥界亚龙（Viper）
- 剧毒 → 剧毒术士（Venomancer）
- 沉默 → 沉默术士（Silencer）
- 光法 → 光之守卫（Keeper of the Light）
- 赏金 → 赏金猎人（Bounty Hunter）
- 隐刺 → 力丸（Riki）
- 女王 → 痛苦女王（Queen of Pain）
- 影刺、PA → 幻影刺客（Phantom Assassin）
- TB → 恐怖利刃（Terrorblade）
- TA、圣堂 → 圣堂刺客（Templar Assassin）
- CK → 混沌骑士（Chaos Knight）
- DK → 龙骑士（Dragon Knight）
- DP → 死亡先知（Death Prophet）
- SK → 沙王（Sand King）；若语境明显指 Skeleton King，按冥魂大帝
- 大牛 → 上古巨神（Elder Titan）
- 白牛 → 裂魂人（Spirit Breaker）
- 黑鸟、OD → 殁境神蚀者（Outworld Destroyer）
- 猛犸 → 马格纳斯（Magnus）
- 蝙蝠 → 蝙蝠骑士（Batrider）
- 滚滚 → 石鳞剑士（Pangolier）
- 松鼠 → 森海飞霞（Hoodwink）
- 玛西 → 玛西（Marci）

## 歧义处理

- “虚空”默认虚空假面；“紫猫”才是虚无之灵。
- “猴子”默认幻影长矛手；“猴王/大圣”是齐天大圣。
- “毒”不能单独确定英雄，需要结合“龙、狗、剧毒”等后续词。
- “小鹿”和“老鹿”绝不能互换。
- 英雄不存在或两个候选同样合理时，只问一句：`你说的是 A 还是 B？`
