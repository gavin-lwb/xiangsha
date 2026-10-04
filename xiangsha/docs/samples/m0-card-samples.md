# M0 卡片样例（v1 启动前确认用）

> **生成日期**：2026-10-04
> **用途**：用户 review 每种卡片类型是否合理，OK 后批量生产
> **生成策略**：每种类型 1 个样例（不批量）
> **关联决策**：D031 / D041 / D058 / D059 / D060 / D061 / D064 / D067 / D070 / D077 / D081 / D082 / D087 / D088 / D095 / D103 / D136
> **下一步**：用户 review 全部样例 → 确认 / 修改 → AI 批量生成 274 张

---

## 目录

1. [模块 A · 吃啥（6 张）](#1-模块-a--吃啥6-张)
2. [模块 B · 玩啥 · 点子库（4 张）](#2-模块-b--玩啥--点子库4-张)
3. [模块 C · 做啥（3 个）](#3-模块-c--做啥3-个)
4. [模块 D · 拍啥 · 姿势卡（7 张）](#4-模块-d--拍啥--姿势卡7-张)
5. [启动引导 3 屏文案](#5-启动引导-3-屏文案)
6. [小狐狸人设卡 · 8 场景示例](#6-小狐狸人设卡--8-场景示例)
7. [分享卡片 5 种模板](#7-分享卡片-5-种模板)
8. [隐私政策 Markdown（中英）](#8-隐私政策-markdown中英)
9. [过敏原 8 类标签](#9-过敏原-8-类标签)
10. [设置 4 类分组](#10-设置-4-类分组)

---

## 1. 模块 A · 吃啥（6 张）

> **关联决策**：D031（80-120 张）、D041-D048（在家做）、D049-D056（成熟度）
> **字段规范**：见 PRD §6.1.4 + SPEC §10.1

### A1. 在家做（带完整菜谱）

```json
{
  "id": "eat-home-001",
  "title": "番茄牛腩饭",
  "titleEn": "Tomato Beef Brisket Rice",
  "subtitle": "川菜 · 25min · 1-2 人份",
  "emoji": "🍅",
  "category": "staple",
  "scenario": "homecook",
  "serves": 2,
  "allergens": [],
  "difficulty": 2,
  "timeMinutes": 25,
  "mainIngredient": "牛腩",
  "style": "chuan",
  "mood": "comfort",
  "tags": ["下饭", "酸甜", "秋冬", "新手"],
  "recipe": {
    "ingredients": [
      {"name": "牛腩", "amount": "300g"},
      {"name": "番茄", "amount": "2 个"},
      {"name": "洋葱", "amount": "半个"},
      {"name": "米", "amount": "1 杯"},
      {"name": "姜蒜", "amount": "适量"}
    ],
    "steps": [
      "牛腩切块焯水去血沫",
      "番茄去皮切块，洋葱切丁",
      "热锅下油爆香姜蒜，下牛腩翻炒",
      "加番茄和洋葱，炖 20 分钟",
      "配米饭出锅"
    ]
  }
}
```

### A2. 早餐（外卖）

```json
{
  "id": "eat-breakfast-001",
  "title": "皮蛋瘦肉粥",
  "titleEn": "Century Egg & Pork Congee",
  "subtitle": "粤式 · 10min · 1 人份",
  "emoji": "🥣",
  "category": "staple",
  "scenario": "takeout",
  "brand": "海底捞",
  "serves": 1,
  "allergens": ["蛋"],
  "mainIngredient": "米",
  "style": "yue",
  "mood": "comfort",
  "tags": ["早餐", "暖胃", "外卖"],
  "priceRange": "budget"
}
```

### A3. 午餐（外卖）

```json
{
  "id": "eat-lunch-001",
  "title": "黄焖鸡米饭",
  "titleEn": "Braised Chicken Rice",
  "subtitle": "鲁菜 · 15min · 1 人份",
  "emoji": "🍗",
  "category": "staple",
  "scenario": "takeout",
  "brand": "杨铭宇",
  "serves": 1,
  "allergens": [],
  "mainIngredient": "鸡肉",
  "style": "lu",
  "mood": "comfort",
  "tags": ["外卖", "下饭", "经典"],
  "priceRange": "budget"
}
```

### A4. 下午茶

```json
{
  "id": "eat-tea-001",
  "title": "提拉米苏",
  "titleEn": "Tiramisu",
  "subtitle": "意式甜点 · 1 人份",
  "emoji": "🍰",
  "category": "snack",
  "scenario": "takeout",
  "brand": "85°C",
  "serves": 1,
  "allergens": ["蛋", "奶", "麦"],
  "mainIngredient": "奶酪",
  "style": "western",
  "mood": "treat",
  "tags": ["甜点", "下午茶", "治愈"],
  "priceRange": "mid"
}
```

### A5. 晚餐

```json
{
  "id": "eat-dinner-001",
  "title": "麻辣香锅",
  "titleEn": "Spicy Stir-fry Pot",
  "subtitle": "川菜 · 自选配菜",
  "emoji": "🌶️",
  "category": "dish",
  "scenario": "eatIn",
  "brand": "麻辣诱惑",
  "serves": 1,
  "allergens": ["大豆", "芝麻"],
  "mainIngredient": "混合",
  "style": "chuan",
  "mood": "spicy",
  "tags": ["晚餐", "聚餐", "重口"],
  "priceRange": "mid"
}
```

### A6. 夜宵

```json
{
  "id": "eat-latenight-001",
  "title": "麻辣烫",
  "titleEn": "Malatang",
  "subtitle": "川式 · 自选配菜",
  "emoji": "🍲",
  "category": "dish",
  "scenario": "takeout",
  "brand": "杨国福",
  "serves": 1,
  "allergens": ["大豆"],
  "mainIngredient": "混合",
  "style": "chuan",
  "mood": "spicy",
  "tags": ["夜宵", "外卖", "治愈"],
  "priceRange": "budget"
}
```

---

## 2. 模块 B · 玩啥 · 点子库（4 张）

> **关联决策**：D058（30-50 张）、D059（4 卡池）、D060（耗时字段）、D061（费用字段）

### B1. 室内

```json
{
  "id": "play-indoor-001",
  "title": "整理衣柜",
  "titleEn": "Tidy Your Wardrobe",
  "subtitle": "整理出 3 件不穿的衣服",
  "emoji": "👔",
  "category": "indoor",
  "timeMinutes": 30,
  "costLevel": "free",
  "tags": ["整理", "治愈", "断舍离"]
}
```

### B2. 室外

```json
{
  "id": "play-outdoor-001",
  "title": "公园散步",
  "titleEn": "Park Walk",
  "subtitle": "走 30 分钟，看看花草",
  "emoji": "🌳",
  "category": "outdoor",
  "timeMinutes": 30,
  "costLevel": "free",
  "tags": ["运动", "治愈", "一个人"]
}
```

### B3. 单人

```json
{
  "id": "play-solo-001",
  "title": "冥想 10 分钟",
  "titleEn": "10-min Meditation",
  "subtitle": "闭眼专注呼吸",
  "emoji": "🧘",
  "category": "solo",
  "timeMinutes": 10,
  "costLevel": "free",
  "tags": ["放松", "治愈", "一个人"]
}
```

### B4. 多人

```json
{
  "id": "play-group-001",
  "title": "桌游夜",
  "titleEn": "Board Game Night",
  "subtitle": "约 3-5 个朋友玩一局",
  "emoji": "🎲",
  "category": "group",
  "timeMinutes": 120,
  "costLevel": "low",
  "tags": ["社交", "聚会", "室内"]
}
```

---

## 3. 模块 C · 做啥（3 个）

> **关联决策**：D064（关键词模板）、D067（80+ 微任务）、D070（10-15 急救）

### C1. 大目标拆解模板 · 关键词：写

```yaml
keyword: "写"
applyTo: "写周报 / 写总结 / 写文档"
template:
  - "打开文档 / 笔记工具"
  - "列 3-5 个要点大纲"
  - "每个要点写 3-5 句"
  - "通读检查错别字，提交"
```

### C2. 5min 微任务 · 整理类

```json
{
  "id": "microtask-001",
  "title": "清空桌面",
  "emoji": "🧹",
  "category": "organize",
  "estimatedMinutes": 5,
  "description": "把所有东西归位，桌面恢复空荡"
}
```

### C3. 拖延急救 · 呼吸类

```json
{
  "id": "rescue-001",
  "title": "深呼吸 5 次",
  "emoji": "🌬️",
  "category": "breath",
  "description": "鼻子吸气 4 秒，嘴巴呼气 6 秒"
}
```

---

## 4. 模块 D · 拍啥 · 姿势卡（7 张）

> **关联决策**：D077（emoji + SF Symbols）、D081（视觉规范）、D082（底部气泡引导）

### D1. 单人

```json
{
  "id": "photo-solo-001",
  "title": "靠墙侧光",
  "titleEn": "Side Light by Wall",
  "emoji": "🧍",
  "sfSymbol": "person.fill",
  "category": "solo",
  "guidance": "📐 侧身 45°，让窗户光从侧面打过来",
  "tags": ["人像", "光线", "单人"]
}
```

### D2. 情侣

```json
{
  "id": "photo-couple-001",
  "title": "牵手对望",
  "titleEn": "Hand-holding Gaze",
  "emoji": "💑",
  "sfSymbol": "heart.fill",
  "category": "couple",
  "guidance": "🤝 双手十指相扣，对视微笑",
  "tags": ["情侣", "温馨", "近景"]
}
```

### D3. 朋友

```json
{
  "id": "photo-friend-001",
  "title": "比心合影",
  "titleEn": "Heart Hands Group",
  "emoji": "👯",
  "sfSymbol": "person.2.fill",
  "category": "friend",
  "guidance": "🤟 所有人用手比心，看向镜头",
  "tags": ["朋友", "合影", "活泼"]
}
```

### D4. 探店

```json
{
  "id": "photo-shop-001",
  "title": "咖啡杯特写",
  "titleEn": "Coffee Cup Close-up",
  "emoji": "🏪",
  "sfSymbol": "cup.and.saucer.fill",
  "category": "shop",
  "guidance": "☕ 45° 俯拍，背景虚化",
  "tags": ["探店", "美食", "特写"]
}
```

### D5. 旅游

```json
{
  "id": "photo-travel-001",
  "title": "背影看景",
  "titleEn": "Back-view Landscape",
  "emoji": "✈️",
  "sfSymbol": "binoculars.fill",
  "category": "travel",
  "guidance": "🌄 站在高处，背对镜头看远方",
  "tags": ["旅游", "背影", "风景"]
}
```

### D6. ins

```json
{
  "id": "photo-ins-001",
  "title": "镜子自拍",
  "titleEn": "Mirror Selfie",
  "emoji": "📸",
  "sfSymbol": "camera.mirror.fill",
  "category": "ins",
  "guidance": "🪞 对着镜子，手机挡住半脸",
  "tags": ["ins", "镜子", "自拍"]
}
```

### D7. 搞笑

```json
{
  "id": "photo-fun-001",
  "title": "错位摄影",
  "titleEn": "Forced Perspective",
  "emoji": "🤪",
  "sfSymbol": "face.smiling.inverse",
  "category": "fun",
  "guidance": "🤏 调整位置，让远景像手里拿着",
  "tags": ["搞笑", "创意", "错位"]
}
```

---

## 5. 启动引导 3 屏文案（D087）

```
┌─────────────────────────────────┐
│                                 │
│         🦊 拿不定主意？          │
│                                 │
│   拿不定主意时，给你一个有趣     │
│       的解决方案                  │
│                                 │
│              [→]                │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│                                 │
│     4 个小帮手，让你动起来       │
│                                 │
│   🍚 吃啥    🎮 玩啥            │
│   ✅ 做啥    📸 拍啥            │
│                                 │
│              [→]                │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│                                 │
│       不焦虑，不催促             │
│                                 │
│   拿不定主意就摇一签，           │
│   让小狐狸帮你想 🦊              │
│                                 │
│          [开始使用]              │
└─────────────────────────────────┘
```

---

## 6. 小狐狸人设卡 · 8 场景示例（D136）

| 场景 | 文案 |
|---|---|
| 抽签进行中 | 🦊 帮你想一下~ |
| 抽签完成 | 🦊 好眼光！就它啦~ |
| 拒绝 1 次 | 🦊 好吧，再看看~ |
| 拒绝 5 次 | 🦊 你是不是都不喜欢？要不自己加几个？ |
| 兜底 L1（候选为 0） | 🦊 歇够了？加点新内容吧 |
| 不决策模式 | 🦊 要不今天就不决定了？ |
| 完成庆祝 | 🦊👏 你居然真的做了！ |
| 急救动作完成 | 🦊 嗯，舒服点了对吧？ |

---

## 7. 分享卡片 5 种模板（D038）

```
治愈系：   今天就让小狐狸替你想啦~ 🦊
幽默系：   🦊 帮我做了个决定，今晚就吃这个
简洁系：   今晚：🍅 番茄牛腩饭
反鸡汤系： 不知道吃啥？反正不焦虑
留空：     （用户自填）
```

---

## 8. 隐私政策 Markdown（中英）

### 中文版

```markdown
# 想啥 App 隐私政策

最后更新：2026-XX-XX

我们承诺：想啥 App **不收集任何用户数据**。

## 1. 数据收集
本应用不收集您的任何个人信息、设备信息、行为数据。

## 2. 数据存储
- 所有数据（卡池、历史记录、收藏、自定义内容）存储在您的设备本地
- v1.1+ 可选开启 iCloud 同步，数据通过 CloudKit Private Database 加密传输
- Apple 无法读取您的同步数据

## 3. 第三方共享
我们不向任何第三方共享、售卖您的数据。

## 4. 联系方式
- 反馈邮箱：feedback@想啥.app
- 隐私问题：privacy@想啥.app

## 5. 政策变更
如有重大变更，我们会通过 App 内通知告知您。
```

### English Version

```markdown
# Pick Now Privacy Policy

Last Updated: 2026-XX-XX

We promise: Pick Now App **does NOT collect any user data**.

## 1. Data Collection
This app does not collect any personal information, device info, or behavior data.

## 2. Data Storage
- All data (card pools, history, favorites, custom content) is stored locally on your device
- v1.1+ may offer optional iCloud sync via CloudKit Private Database (encrypted)
- Apple cannot read your synced data

## 3. Third-party Sharing
We do not share or sell your data to any third party.

## 4. Contact
- Feedback: feedback@想啥.app
- Privacy issues: privacy@想啥.app

## 5. Policy Changes
Material changes will be communicated via in-app notification.
```

---

## 9. 过敏原 8 类标签（D088）

```
🥜 花生    🌰 坚果    🦐 海鲜    🥚 蛋
🥛 奶      🌾 麦      🫘 大豆    🪻 芝麻
─────────────────────────
✅ 无（默认）
```

---

## 10. 设置 4 类分组（D090-D094）

| 分组 | 选项 |
|---|---|
| **外观** | 主题（系统/浅色/深色）、主色（米咖/抹茶/海雾）、强调色（暖橘/暖金/玫瑰） |
| **反馈** | 震动反馈、音效、启动引导显示、减少动效 |
| **数据** | 统计查看、导出、导入、清空历史 |
| **关于** | 版本号、致谢、隐私政策、反馈邮件、重看引导、调试入口 |

---

## Review Checklist（用户确认）

> **每项 ✅/❌ 后，AI 批量生成 274 张卡**

### 模块 A · 吃啥

- [ ] **A1 字段够用？** 是否需要 `spiceLevel`（辣度）/`calories`（卡路里）/`kitchenTools`（厨具）？
- [ ] **A2-A6 字段差异合理？** 早餐/下午茶/夜宵是不是字段该统一？
- [ ] **A1 菜谱 `recipe.ingredients` / `recipe.steps` 字段规范？**
- [ ] **`priceRange`（budget/mid/premium）字段保留？**
- [ ] **`scenario`（takeout/eatIn/homecook）三态够用？**

### 模块 B · 玩啥

- [ ] **B1-B4 字段够用？** 是否需要 `companions`（同行人数）/`mood`/`season`？
- [ ] **`category`（indoor/outdoor/solo/group）四分类合理？**
- [ ] **`timeMinutes`（15/30/60/120）枚举 vs 自由数值？**
- [ ] **`costLevel`（free/low/high）三档够用？**

### 模块 C · 做啥

- [ ] **C1 关键词模板格式 OK？** markdown / yaml / json？
- [ ] **C2 微任务 `description` 必要吗？** 还是只要 `title` + `emoji`？
- [ ] **C3 急救动作字段够简洁？**

### 模块 D · 拍啥

- [ ] **D 姿势卡 `guidance` 字段风格统一？** 需要更精炼吗？
- [ ] **7 个分类合理？** 是否需要加「美食」「宠物」？
- [ ] **`sfSymbol` 字段保留？** 还是只用 emoji？

### 文案类

- [ ] **启动引导 3 屏文案** OK？
- [ ] **小狐狸人设卡 8 场景** OK？还需要哪些场景？
- [ ] **分享卡片 5 种模板** OK？还要加什么模板？
- [ ] **隐私政策 Markdown** 完整？还要加什么？
- [ ] **设置 4 类分组** OK？

---

## 用户 review 后

| 选项 | 我的下一步动作 |
|---|---|
| **全 OK** | 启动 AI 批量生成（用方案 D：AI 草稿 + 人工校审） |
| **部分 OK** | 按你列的修改项改完 → 再批量 |
| **大部分不行** | 重新设计字段 → 重写样例 → 再 review |

---

> **创建日期**：2026-10-04
> **作者**：小白
> **状态**：⏳ 等用户 review
