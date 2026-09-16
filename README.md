# Dota 2 新手助手

中文 Dota 2 新手指导与 OpenDota 赛后复盘 Skill，适合 Codex、ChatGPT Project 和 ChatGPT Live 语音使用。

由 **TimZhang踢木桩** 创建，以降低新手的决策负担为目标：开局迅速拿到能执行的加点、出装、对线、功能品和视野建议；赛后基于可获得的 OpenDota 数据复盘经济、出装、目标与关键节点。

## 能做什么

- 根据中文语音、文字或选人截图生成新局攻略。
- 支持“我的英雄 + 位置 + 本路对手”的极速开局建议。
- 提供技能加点、核心/分支出装、关键技能规避、真假眼/粉/雾建议，以及前中后期行动重点。
- 通过比赛 ID + 英雄名称读取 OpenDota，区分数据事实和复盘判断，分析出装、经济、团战和目标事件。
- 完整文字复盘分成三个可独立复制的板块，每块不超过900字符，方便拆成三条B站等社媒回复。
- Codex 本地复盘会自动检查解析状态，未解析时提交 OpenDota 录像解析并等待完成后再分析，无需手动点击；超时或失败会说明原因。ChatGPT / Live 自动提交需要可执行 POST 的 HTTP 工具。
- 支持 ChatGPT Live 的完全语音流程：口述阵容，或逐位口述比赛 ID 并复读确认。
- 内置新手运营框架：围绕兵线、资源、装备窗口、地图压力与团战转化来做决策，而非背固定套路。

## 快速开始

### 在 Codex 中使用

将 [dota2-newbie-assistant](dota2-newbie-assistant) 安装为本地 Skill 后，直接说：

```text
我露娜一号位，对线雷泽和撼地者，Dota 速报。
```

或：

```text
复盘 8967143809，我是夜魇方尸王。
```

### 在 ChatGPT Project / Live 中使用

下载并上传最新的单文件知识包：

- [ChatGPT-Dota2-Newbie-Assistant-v0.9.2.md](dota2-newbie-assistant/dist/ChatGPT-Dota2-Newbie-Assistant-v0.9.2.md)
- [ChatGPT-Dota2-Newbie-Assistant-v0.9.2.zip](dota2-newbie-assistant/dist/ChatGPT-Dota2-Newbie-Assistant-v0.9.2.zip)

之后可完全口述阵容、位置、同路英雄和比赛 ID。Live 默认先给可立即执行的核心结论；说“详细说”再展开指定部分。

## 目录

- [Skill 规则](dota2-newbie-assistant/SKILL.md)
- [运营与出装底层框架](dota2-newbie-assistant/references/fundamentals-operations.md)
- [版本变更](dota2-newbie-assistant/CHANGELOG.md)
- [构建 ChatGPT 单文件包](dota2-newbie-assistant/scripts/build-chatgpt-package.ps1)

## 数据与版本边界

当前支持：**助手 v0.9.2｜Dota 7.41f**（2026-09-16 核验）。[7.41f 玩家解读与口播稿](docs/7.41f-player-guide.md)。


- 新局建议优先采用当前 Skill 中标记的 Dota 2 补丁；具体英雄、命石、装备和地图交互会随游戏更新改变。
- 赛后复盘只基于 OpenDota 实际返回字段。数据不完整时会降级为基础结算复盘，不编造购买时间、团战过程或站位。
- 不提供自动操作、客户端控制、绕过反作弊、代打、博彩预测或逐帧视频复盘。

## 致谢与版权说明

项目中的“新手运营与出装底层框架”吸收并重新组织了久远 Vortex 的公开基础教学资料所带来的方法论启发。这里仅保留独立撰写的概括、判断框架和实践规则，不包含原始 PDF、原文转录、原始图片或版本化的固定点位内容。

英雄、物品和比赛数据的相关权利分别归 Valve 与 OpenDota 及其数据来源所有；本项目与它们无官方关联。

## 许可证

本项目以 [MIT License](LICENSE) 开源。
