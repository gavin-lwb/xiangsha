# M0 内容生产蓝图（v1.0 · 274 张卡）

> **来源**：拆分自 `DEVELOPMENT.md` v1.4 拍板 + ROADMAP §17.1 M0 里程碑
> **创建**：2026-10-06 by OpenClaw Team Leader
> **目的**：为「274 张卡 + 中英双语 + emoji + 字段」生产提供可执行物料
> **关联决策**：D002 元数据 / D026 时段 / D027-D076 字段 / D139-D141 占位方案

---

## 1. 总览

| 模块 | 卡数 | 中英双语 | v1 占位 | v1.1 真实图 | 字段模板 |
|---|---|---|---|---|---|
| **A 吃啥** | **80** | ✅ | 色块 + 大 emoji + 菜名（D140） | 实拍 + AI 生图（D141） | `Card` + `EatCardMetadata` |
| **B 玩啥 · 点子库** | **80** | ✅ | 色块 + 大 emoji + 活动名 | 同上 | `Card` + `PlayCardMetadata` |
| **C 做啥** | **60** | ✅ | 色块 + 大 emoji + 任务名 | 同上 | `Card` + `UserTaskRecord`（v1.1+） |
| **D 拍啥 · 姿势** | **54** | ✅ | 色块 + 大 emoji + 姿势名 | 同上 | `Card` |
| **合计** | **274** | — | — | — | — |

> **单人估时**：274 张 × 25 分钟/张 ≈ 114 小时 ≈ 3 周（8h/天）。多人协作可压到 1.5-2 周。
> **关键风险**：**没 M0，M1-M3 跑完也是空壳可抽**（ROADMAP §17.1）。

---

## 2. 卡池分组（每模块 6-10 个池）

### A 吃啥（80 张）

| 池 | 卡数 | 示例 |
|---|---|---|
| 🍜 中式正餐 | 16 | 麻婆豆腐 / 红烧肉 / 宫保鸡丁 / 糖醋里脊 |
| 🍱 日韩料理 | 12 | 寿司 / 拉面 / 韩式炸鸡 / 鳗鱼饭 |
| 🍕 西式快餐 | 12 | 披萨 / 汉堡 / 意面 / 牛排 |
| 🥗 轻食沙拉 | 10 | 凯撒沙拉 / 藜麦碗 / 鸡胸沙拉 |
| 🍲 汤品暖食 | 8 | 罗宋汤 / 酸辣汤 / 玉米浓汤 |
| 🍰 甜品下午茶 | 10 | 提拉米苏 / 芝士蛋糕 / 冰淇淋 |
| 🥡 中式小吃 | 8 | 生煎包 / 锅贴 / 麻辣烫 |
| 🏠 在家做（v1.1） | 4 | 番茄炒蛋 / 蛋炒饭 / 凉拌黄瓜 / 自制奶茶 |

### B 玩啥 · 点子库（80 张 · 与吃啥完全不重叠 D057-D063）

| 池 | 卡数 | 示例 |
|---|---|---|
| 🎮 室内·单人 | 16 | 玩一把独立游戏 / 追一集番 / 写日记 / 拼乐高 |
| 🎲 室内·多人 | 16 | 桌游夜 / KTV / 打牌 / 剧本杀 |
| 🌳 室外·单人 | 12 | 公园散步 / 骑行 / 摄影采风 / 钓鱼 |
| 👥 室外·多人 | 12 | 露营 / 飞盘 / 球局 / 烧烤 |
| 🎨 创作类 | 12 | 画画 / 写小说 / 拍短视频 / 做手帐 |
| 📚 学习类 | 12 | 读本书 / 学一门语言 / 看纪录片 / 练乐器 |

### C 做啥（60 张）

| 池 | 卡数 | 示例 |
|---|---|---|
| 🧹 家务整理 | 16 | 打扫房间 / 整理衣柜 / 洗碗 / 倒垃圾 |
| 💪 运动健身 | 12 | 跑步 30 分钟 / 做瑜伽 / 深蹲 100 个 / 拉伸 |
| 📝 自我提升 | 12 | 写周报 / 学新技能 / 复盘今日 / 列明日清单 |
| 🤝 社交联络 | 10 | 给朋友打电话 / 回一条消息 / 约下周饭 |
| 🎁 关怀他人 | 10 | 给家人买小礼物 / 帮同事带咖啡 / 写信给爸妈 |

### D 拍啥 · 姿势（54 张）

| 池 | 卡数 | 示例 |
|---|---|---|
| 🧍 单人·日常 | 14 | 抱臂 / 摸下巴 / 微笑 / 侧脸 |
| 👫 情侣 | 14 | 牵手 / 拥抱 / 额头吻 / 公主抱 |
| 👨‍👩‍👧 朋友 | 12 | 比心 / 勾肩 / 干杯 / 贴贴 |
| 👨‍👩‍👧‍👦 家庭 | 8 | 全家福 / 抱娃 / 亲子照 |
| 🐱 萌宠 | 6 | 抱猫 / 遛狗 / 跟猫自拍 |

---

## 3. 字段模板（v1 占位）

### 3.1 通用 Card 字段（SPEC §10.1）

```swift
Card(
    title: "麻婆豆腐",                 // 中文标题（必填）
    scene: eatScene,                    // DecisionScene 引用
    pool: chineseMainPool,              // CardPool 引用
    emoji: "🌶️",                        // v1 占位大 emoji（D140）
    category: "main",                   // 分类
    brand: nil,                         // 品牌（吃啥独立字段）
    allergens: ["花生", "大豆"],         // 过敏原列表
    difficulty: 2,                      // 1-5
    timeMinutes: 25,                    // 预计耗时
    weight: 1.0,                        // 基础权重
    metadata: nil,                      // 扩展元数据
    isUserCreated: false,
    scenario: .takeout,                 // 用餐场景
    availableTimes: [.lunch, .dinner],  // 适用时段
    seasonWeights: nil,                 // 季节软调权（可选）
    cuisine: .sichuan,                  // 菜系（可选）
    priceRange: .medium,                // 价格档（可选）
    recipe: nil,                        // 菜谱（仅在家做卡）
    serves: 2,                          // 适合几人份
    costLevel: nil                      // 费用档（玩啥必填）
)
```

### 3.2 吃啥专属（EatCardMetadata）

```swift
EatCardMetadata(
    spicyLevel: 3,                      // 辣度 0-5
    isVegetarian: false,
    prepTips: "点餐时备注少辣",          // 准备提示
    pairing: "米饭 + 例汤"               // 搭配建议
)
```

### 3.3 玩啥专属（PlayCardMetadata）

```swift
PlayCardMetadata(
    location: .indoor,                  // 室内/室外
    socialMode: .solo,                  // 单人/多人
    durationMinutes: 60,                // 预计时长
    equipment: ["桌游", "扑克"],         // 装备清单
    weatherDependent: false
)
```

---

## 4. Emoji 库（v1 占位 · D140）

### 4.1 吃啥（按 category）

```
主粮: 🍚 🍜 🍝 🥖 🥐
菜: 🥗 🥘 🍲 🍛 🌶️
汤: 🍲 🥣 🫕
甜品: 🍰 🎂 🍨 🍮 🍫
小吃: 🥟 🥡 🍢
西餐: 🍕 🍔 🌮 🌯 🥙
日韩: 🍣 🍱 🍙 🍘
饮料: ☕ 🍵 🧋 🥤 🍺
```

### 4.2 玩啥（按 socialMode + location）

```
室内·单人: 🎮 📚 🎨 🎵 🧩
室内·多人: 🎲 🎤 🎭 🎴
室外·单人: 🚴 🏃 📸 🎣
室外·多人: 🏕️ 🥏 ⚽ 🍖
创作: ✏️ 📷 🎬 📒
学习: 📖 🌍 🎓 🎼
```

### 4.3 做啥（按 effortLevel）

```
轻松: 🧹 📞 💌
中等: 🏃 ✍️ 📚
高强度: 💪 🔥 🎯
```

### 4.4 拍啥（按人数）

```
单人: 🧍 🤳
情侣: 💑 👫
朋友: 👯 🤝
家庭: 👨‍👩‍👧 🏠
萌宠: 🐱 🐶
```

---

## 5. 中英双语示例（5 个完整范例）

### 示例 1：麻婆豆腐 / Mapo Tofu

```yaml
zh-CN:
  title: "麻婆豆腐"
  emoji: "🌶️"
  category: "main"
  brand: null
  allergens: ["花生", "大豆"]
  difficulty: 2
  timeMinutes: 25
  scenario: "takeout"
  availableTimes: ["lunch", "dinner"]
  cuisine: "sichuan"
  priceRange: "medium"
  serves: 2
  spicyLevel: 4
  isVegetarian: false
  prepTips: "备注少辣"
  pairing: "米饭 + 例汤"

en-US:
  title: "Mapo Tofu"
  emoji: "🌶️"
  category: "main"
  brand: null
  allergens: ["peanut", "soy"]
  difficulty: 2
  timeMinutes: 25
  scenario: "takeout"
  availableTimes: ["lunch", "dinner"]
  cuisine: "sichuan"
  priceRange: "medium"
  serves: 2
  spicyLevel: 4
  isVegetarian: false
  prepTips: "Ask for less spicy"
  pairing: "Rice + soup"
```

### 示例 2-5：[制作中 · 占位]

> 完整 274 张卡的 JSON 模板将导出到 `Resources/SeedData/{zh-CN,en-US}.json`，
> 由 `SeedService` 在 App 首次启动时导入（参见 `Services/SeedService.swift`）。

---

## 6. 工作流（单人 vs 多分身协作）

### 6.1 单人模式（3 周）

```
D1-D2:   批量产出 80 张「吃啥」卡（按 8 个池子分组，每池 10 张）
D3-D4:   批量产出 80 张「玩啥」卡
D5-D6:   批量产出 60 张「做啥」卡
D7-D8:   批量产出 54 张「拍啥」卡
D9-D11:  翻译校对（中英双语，每张 2 遍校对）
D12-D14: 录入 SeedData.json + SeedService 导入测试
D15:     App 内烟测（每模块抽 10 张看显示）
D16-D21: 修字段 bug + emoji 校准
```

### 6.2 多分身协作（1.5-2 周）

```
分工（基于 MEMORY IDENTITY.md 已有分身）:
- 🦊 小白（Lead）：吃啥 40 张 + 全局校对 + 录入脚本
- 🟢 jinhua（进化大使）：玩啥 80 张 + 字段模板自动化
- 🔵 maben（神笔马良）：做啥 60 张（写作型任务最匹配）
- 🟡 tieniu（社交铁牛）：拍啥 54 张（社交类最匹配）

协作工具：
- shared: Resources/SeedData/cards-draft.xlsx（飞书文档）
- review: 每个分身完工后 @小白 校对
- merge: 小白统一编译为 .json + 录入 SeedService
```

### 6.3 质量门禁

每张卡必须满足：

- [ ] title 中英双语都填
- [ ] emoji 已选（v1 占位 ≥ 1 个）
- [ ] category 落入对应池子
- [ ] allergens 列表完整（即使是空也要显式 `[]`）
- [ ] difficulty 1-5 之间
- [ ] availableTimes 至少 1 个时段
- [ ] priceRange / costLevel 至少填一项
- [ ] 字段不超 SPEC §10.1 范围

---

## 7. 录入与导出

### 7.1 SeedData 目录结构

```
Resources/SeedData/
├── zh-CN.json          # 中文版（默认）
├── en-US.json          # 英文版
└── README.md           # 维护说明
```

### 7.2 SeedService 接入点

参见 `App/Core/Services/SeedService.swift`（已存在）。
首次启动时检测 SwiftData 为空 → 批量 `modelContext.insert(card)` → save。

---

## 8. 关联文档

- `docs/00-PRD.md` §6 模块 PRD（D001-D141）
- `docs/01-SPEC.md` §10 数据架构 + §A.3 软调权
- `docs/03-ROADMAP.md` §17.1 M0 里程碑 + G.1.1 P0-1
- `App/Core/Models/Card.swift`（字段定义）
- `App/Core/Models/EatCardMetadata.swift`（吃啥专属）
- `App/Core/Models/PlayCardMetadata.swift`（玩啥专属）

---

**状态**：✅ 蓝图完成，等待用户拍板**是否启动 M0** + **单人 / 多分身**选择。
