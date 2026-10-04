# 「想啥」Product Requirements Document (PRD)

> **代号**：想啥（产品名，主）/ Pick Now（英文副名）/ xiangsha（工程名 · Xcode scheme）
> **平台**：iOS 17+（Xcode / SwiftUI / SwiftData）
> **来源**：拆分自 `DEVELOPMENT.md` v1.3（2026-10-04）
> **范围**：产品愿景 / 用户画像 / 设计原则 / 模块 PRD / 用户旅程 / 上架元数据
**不重复**：技术实现细节见 `01-SPEC.md`，协作规范见 `02-AGENTS.md`，路线图见 `03-ROADMAP.md`

---

## 0. 元信息

| 项 | 内容 |
|---|---|
| 文档版本 | v1.1（评审优化版） |
| 上一版本 | v1（2026-10-03，87 决策） |
| 决策数量 | 103（v1: 87 → 优化后: 103） |
| 评审来源 | 一号评审员（结构/算法）/ 二号评审员（产品/商业）/ 三号评审员（工程/法务） |
| 整合日期 | 2026-10-04 |
| 维护者 | 小白（飞书协作）/ 风小孩（产品决策） |
| 引用关系 | 上游 ← DEVELOPMENT.md v1<br>平级 → 三方评审报告（评审报告/）<br>下游 → AGENTS.md（协作）· SPEC.md（技术）· ROADMAP.md（路线） |

---


---

## 1. 项目愿景与定位

| 项 | 内容 |
|---|---|
| **App 名** | 想啥（主选）/ Pick Now（备选） |
| **一句话** | 拿不定主意时，给你一个有趣的解决方案 |
| **核心定位** | **日间决策引擎**——不是单点工具，是把 4 类决策场景整合成一套连贯体验 |
| **平台** | iOS 17+ 优先（Xcode 原生，SwiftUI / SwiftData） |
| **风格调性** | 治愈温暖（米咖奶油色系 / 圆润卡片 / 柔和插画 / 不焦虑不鸡汤） |
| **品牌 IP** | 小狐狸 🦊 |
| **商业模式** | v1 免费无广告；可选内购（姿势图卡包 / 主题皮肤 / 「小狐狸会员」） |
| **国际化** | 中英双语（String Catalogs：zh-CN + en-US） |

---


---

## 2. 用户画像（5 类）

| 编号 | 画像 | 真实痛点 | 对应模块 |
|---|---|---|---|
| U1 | 吃饭选择困难者 | 外卖/餐厅刷 1 小时还是不知道点啥 | 模块 A |
| U2 | 周末/闲暇迷茫者 | 不知道玩什么、不知道去哪 | 模块 B（玩啥 · 点子库） |
| U3 | 拖延症患者 | 大目标太抽象，开了头就放弃 | 模块 C |
| U4 | 拍照姿势困难者 | 出去玩/约会想发圈但不知道摆啥姿势 | 模块 D |
| U5 | 通用决策困难 | 选 A 还是 B 纠结半天 | 通用抽签引擎 |

> **U2 修订**：v1 模块 B 替换为「玩啥 · 点子库」（详见第 6.2 节），恢复原始 U2「周末迷茫」语义。**与吃啥/做啥/拍啥完全差异化**（不重叠），复用通用抽签引擎。

---


---

## 3. 核心设计原则（带分级）

> **来源**：二号评审员/三号评审员共同指出「反焦虑」「零账号」「1 个结果」三原则同时严格执行会自我消解。本节明确分级。

| 原则 | v1 严格遵守 | v1.1+ 可破例 | 破例前提 |
|---|---|---|---|
| **隐私优先 + 离线优先** | ✅ 严格 | CloudKit 同步（仍零账号） | 用户显式启用；不读取用户内容 |
| **不焦虑、不鸡汤、不催促** | ✅ 严格 | 「被动式系统集成」（Widget / Spotlight / Siri） | 用户显式添加；不弹推送 |
| **不打扰哲学** | ✅ 严格（无推送、无红点） | 锁屏 Widget 显示「今日还剩 X 次」 | 用户主动添加小组件 |
| **帮你决定 > 给你选择**（1 个结果 + 换一签） | ✅ 严格 | 换 5 次后展示 Top 3 横向卡片（兜底） | 不能让用户「无路可走」 |
| **DIY 个性化** | ✅ 严格 | — | — |
| **慢节奏设计**（一天最多抽 3 次） | ✅ 严格（v1 不可调） | 设置可调（v1.1+） | — |
| **小狐狸 IP 人格化**（v1 新增） | ✅ 所有提示文案统一口径 | 视觉成长（戴厨师帽/拿相机，v1.1+） | — |

### 3.1 设计原则冲突解决表

| 冲突场景 | 默认走哪条 | 破例条件 |
|---|---|---|
| 「反焦虑」vs「留存」 | 严格反焦虑 | Widget/Spotlight/Siri 用户主动启用 |
| 「隐私优先」vs「换机备份」 | JSON 导出/导入 | CloudKit 同步（v1.1） |
| 「1 个结果」vs「用户连换 5 次」 | 仍只展示 1 个 | 第 5 次展示 Top 3（兜底，不强迫） |
| 「不打扰」vs「用户忘记 App」 | 不主动提醒 | 决策日记每周回顾（用户打开 App 才看） |

---


---

## 4. 4 Tab 结构（修订）

| Tab | 模块 | v1 状态 | 修订说明 |
|---|---|---|---|
| 1 | 吃啥（模块 A） | ✅ 完整功能 | — |
| 2 | 做啥（模块 C：任务拆解 + 拖延急救） | ✅ 完整功能 | — |
| 3 | 拍啥（模块 D） | ✅ 完整功能（emoji + SF Symbols + 文字引导） | v1.1 加线稿图，v1.2+ 真实图库 |
| 4 | 玩啥（模块 B · **v1 替换**） | 🆕 **v1 替换为「玩啥 · 点子库」** | 30-50 张室内/室外/单人/多人点子卡；复用通用抽签引擎 |

### 4.1 模块 B 替换为「玩啥 · 点子库」的理由

> **三方评审共识**：原 B「玩啥」v1 是 Coming Soon 占位，4 Tab 空 1 个，U2（周末迷茫）核心用户在 v1 完全得不到服务。

**三种方案对比**：

| 方案 | 工作量 | v1 可用性 | 长期差异化 | 选择 |
|---|---|---|---|---|
| ① 保留「玩啥」占位 + 邮箱订阅 | 0.5d | ❌ 空 Tab | 🟡 低 | ❌ 不采纳 |
| ② 替换为「点子库」30-50 张卡片（玩啥）| 2-3d | ✅ 可用 | 🟢 **高**（与吃啥/做啥/拍啥完全不重叠）| ✅ **采纳** |
| ③ 替换为「喝啥」30-50 张卡片 | 3-4d | ✅ 可用 | 🟡 中（与吃啥同质化：都是"喝/吃什么"）| ❌ 不采纳 |

**采纳方案 ②「玩啥 · 点子库」**（用户 2026-10-04 拍板）：差异化最高（吃 + 玩 + 做 + 拍，4 个完全不重叠的决策场景）；30-50 张室内/室外/单人/多人点子卡，复用现有抽签引擎成本最低（2-3 天）；与二号 v2 评审员建议完全一致。

---


---

## 5. 用户旅程地图（新增）

> **来源**：一号评审员 D.2.2 / 二号评审员第三部分第 3 点 / 三号评审员 3.6 节（留存张力）。本节是 PRD 拆分后的产物。

### 5.1 新用户（Day 0-7）

1. App Store 看到「拿不定主意时，给你一个有趣的解决方案」 → 下载
2. 启动引导 3 屏 → 了解 4 模块
3. **强制设置过敏原**（即使「无」也算填，避免法务风险 · D088）
4. 进入「吃啥」Tab → 自动按 11:30 命中午餐 → 抽签
5. 抽中「番茄牛腩饭」 → 看到「⭐ 收藏」「🔄 换一签」「📤 分享」「✅ 做完了」四按钮（D091）
6. **引导式首抽**：抽完后小狐狸气泡「🦊 喜欢吗？不满意点换一签，或长按标记不喜欢」（D092）
7. （关键动作）点 ⭐ 收藏 → 第一次产生 data hook
8. 退出 App → 晚上回来看「历史」Tab → 看到今天抽过什么

### 5.2 活跃用户（Day 8-30）

1. 每天中午自动打开「吃啥」Tab
2. 开始用「⭐ 收藏」「📌 加卡」自定义
3. **第一次收到「推荐组合」Banner**：周末推「露营 + 烧烤 + 户外姿势」一组
4. （关键动作）用「做啥」Tab 完成第一个微任务 → 点「✅ 做完了」+ 全屏庆祝

### 5.3 老用户（Day 30+）

1. 每天都用，不需要教程
2. 用「跨场景联动 Routine」一键三抽（v1.1）
3. **决策反向解释** ❓ 按钮让用户信任算法（v1.1）
4. 开始把「决策日记」分享到小红书（v1.1 → 引流新用户）

---


---

## 6. 模块 PRD

> 本节按 `D-NNN · 标题` 格式统一编号。每个决策按 **触发场景 / 实现要点 / 验收标准** 三段式描述。

### 6.1 模块 A · 吃什么（31 决策 · D026-D056）

#### 6.1.1 卡池结构

```
吃啥
├── 🏠 在家做（独立，覆盖所有时段）
├── ☀️ 早餐（15-20 张）
├── 🍵 下午茶（10-15 张）
├── 🍚 午餐（25-30 张）
├── 🍜 晚餐（25-30 张）
└── 🌙 夜宵（10-15 张）
```

#### 6.1.2 时段逻辑（自动判断 · D033）

| 时间 | 默认卡池 |
|---|---|
| 06-10 | 早餐 |
| 10-14 | 午餐 |
| 14-17 | 下午茶 |
| 17-21 | 晚餐 |
| 21-02 / 02-06 | 夜宵 |

> 跨时段（如 14:00 卡在「午餐 → 下午茶」交界）→ 优先高时段（如 14:00 推下午茶），避免用户切换。

#### 6.1.3 决策清单

### D026 · 按时段分类

- **类型**：卡池结构
- **触发场景**：用户进入「吃啥」Tab
- **实现要点**：6 个时段卡池（早餐/午餐/下午茶/晚餐/夜宵/在家做），按用户本地时区自动选默认池
- **验收标准**：
  - [ ] Given 当前时间 11:30 When 进入「吃啥」Tab Then 默认展示「午餐」卡池
  - [ ] Given 当前时间 04:30 When 进入「吃啥」Tab Then 默认展示「夜宵」卡池

### D027 · 菜系枚举

- **类型**：数据字段
- **触发场景**：管理后台录入卡片时
- **实现要点**：枚举 `Cuisine`：`chuan / yue / huai / min / zhe / xiang / lu / western / japanese / korean / fusion / other`，对应中英文文案
- **验收标准**：
  - [ ] Given 录入新卡 When 选菜系 Then 必须从枚举选，禁止自由文本
  - [ ] Given 中英文切换 When 显示菜系 Then 同步翻译

### D028 · 价格三档

- **类型**：数据字段
- **触发场景**：用户抽签结果页 / 卡片详情
- **实现要点**：枚举 `PriceRange`：`budget (<¥30)` / `mid (¥30-100)` / `premium (>¥100)`，卡片存 priceRange，抽签结果页显示对应 💰 / 💰💰 / 💰💰💰
- **验收标准**：
  - [ ] Given 卡片 priceRange = budget When 显示 Then 展示「💰」
  - [ ] Given 卡片 priceRange = mid When 显示 Then 展示「💰💰」

### D029 · 在家做独立卡池

- **类型**：卡池结构
- **触发场景**：用户选「在家做」时段
- **实现要点**：「在家做」独立于时段卡池，覆盖所有时段，避免「晚上想做饭却只看到夜宵外卖」
- **验收标准**：
  - [ ] Given 用户选「在家做」 When 时段卡池切换 Then 显示「在家做」卡池
  - [ ] Given 用户在任何时段 When 手动切到「在家做」 Then 可正常抽签

### D030 · 外卖用字段

- **类型**：数据字段
- **触发场景**：外卖/堂食 vs 在家做区分
- **实现要点**：`Card.scenario: HomeCook | Takeout | EatIn`，抽签结果页对应「叫外卖」「出门吃」「在家做」三态 UI
- **验收标准**：
  - [ ] Given 卡片 scenario=Takeout When 显示 Then 标签「🥡 叫外卖」
  - [ ] Given 卡片 scenario=HomeCook When 显示 Then 标签「🍳 在家做」+ 「看菜谱」按钮（D041）

### D031 · 80-120 张

- **类型**：内容密度
- **触发场景**：v1 上架前
- **实现要点**：6 卡池合计 80-120 张内置卡（按市场调研均值），冷启动首屏就满，不做「解锁」机制
- **v1 视觉呈现**：见 §9.3 首屏呈现模式（D139 占位方案 / D140 v1.1 真实图）
- **验收标准**：
  - [ ] Given v1 安装包 When 首次启动 Then 立即可见 ≥ 80 张卡
  - [ ] Given 用户搜索某关键词 When 匹配 Then 命中数 ≥ 5

### D032 · 在家做覆盖所有时段

- **类型**：卡池规则
- **触发场景**：用户切到「在家做」时段
- **实现要点**：「在家做」卡池字段加 `availableTimes: [TimeOfDay]`，抽签时按当前时段过滤
- **验收标准**：
  - [ ] Given 早餐时段 + 在家做卡 availableTimes=[breakfast] When 抽签 Then 可命中
  - [ ] Given 早餐时段 + 在家做卡 availableTimes=[dinner] When 抽签 Then 该卡被排除

### D033 · 自动判断时段

- **类型**：UI 交互
- **触发场景**：用户进入 Tab
- **实现要点**：用 `Calendar.current.dateComponents([.hour], from: .now)` 自动选时段，用户可手动覆盖
- **验收标准**：
  - [ ] Given 当前时间 11:30 When 进入 Then 默认选午餐
  - [ ] Given 用户手动切到早餐 When 退出再回来 Then 记住选择（24h 缓存）

### D034 · 长按切换卡池

- **类型**：UI 交互
- **触发场景**：用户在结果页长按时段标签
- **实现要点**：长按时段 chip 0.5s 弹出「切换到 X」菜单
- **验收标准**：
  - [ ] Given 用户长按时段 chip When 触发 Then 弹出半屏 Sheet 列出其他 5 个时段
  - [ ] Given 选新时段 When 确认 Then 立即重新抽签

### D035 · 两按钮区分

- **类型**：UI 交互
- **触发场景**：结果页
- **实现要点**：v1 主按钮「🔄 换一签」+ 次按钮「⭐ 收藏」；v1.1 加第三按钮「✅ 做完了」
- **验收标准**：
  - [ ] Given 结果页 When 显示 Then 主按钮「换一签」视觉权重最高
  - [ ] Given 用户点「换一签」When 触发 Then 立即重新抽签，不弹确认

### D036 · +20% 收藏权重

- **类型**：抽签引擎参数
- **触发场景**：抽签算法软调权
- **实现要点**：`card.isFavorite ? min(1.2, 1.0 + 0.2 / log(favoriteCount + 1)) : 1.0`，防止收藏卡垄断
- **验收标准**：
  - [ ] Given 用户收藏 1 张卡 When 10000 次蒙特卡洛抽样 Then 该卡命中 ~20% 高于无收藏
  - [ ] Given 用户收藏 20 张卡 When 抽样 Then 单卡权重上限不超过 × 1.07

### D037 · 1024×1024 分享卡

- **类型**：导出
- **触发场景**：用户点「📤 分享」
- **实现要点**：`ImageRenderer` + 自定义 `Transferable`，输出 1024×1024 PNG；内容：logo + emoji + 卡名 + 「想啥」水印
- **验收标准**：
  - [ ] Given 用户点分享 When 生成 Then 输出 PNG ≥ 1MB
  - [ ] Given 生成的图 When 转发到微信/小红书 Then 文字清晰可读

### D038 · 预设+留空文案

- **类型**：内容文案
- **触发场景**：分享卡生成时
- **实现要点**：预设 5 套文案（治愈系 / 幽默系 / 简洁系 / 反鸡汤系 / 留空），用户可编辑或留空
- **验收标准**：
  - [ ] Given 默认选「治愈系」 When 生成 Then 文案「今天就让小狐狸替你想啦~ 🦊」
  - [ ] Given 用户选「留空」 When 生成 Then 仅 emoji + 卡名

### D039 · ⭐ 收藏角标

- **类型**：UI 标识
- **触发场景**：卡片被收藏后
- **实现要点**：卡片右上角 12×12pt 黄色星标，点击展开收藏动作（取消收藏 / 加备注）
- **验收标准**：
  - [ ] Given 卡片被收藏 When 显示 Then 右上角有 ⭐ 角标
  - [ ] Given 用户点 ⭐ When 触发 Then 弹出「取消收藏 / 加备注」ActionSheet

### D040 · 半屏 Sheet 切换

- **类型**：UI 交互
- **触发场景**：用户切时段时
- **实现要点**：`.sheet(presentationDetents: [.medium])` 弹出时段切换器，6 个时段 + 「在家做」chip 横向排列
- **验收标准**：
  - [ ] Given 用户点时段 chip When 弹出 Then 高度为屏幕 50%
  - [ ] Given 用户下拉关闭 Then 不触发任何动作（不切换）

#### 6.1.4 在家做场景扩展（D041-D048）

### D041 · 菜谱字段

- **类型**：数据字段
- **触发场景**：卡片详情页（在家做卡）
- **实现要点**：`Card.recipe: Recipe?` 含 `ingredients: [Ingredient]` / `steps: [Step]` / `timeMinutes: Int` / `difficulty: Int (1-5)`
- **验收标准**：
  - [ ] Given 卡片有菜谱 When 点详情 Then 展开 ingredients + steps 列表
  - [ ] Given 卡片无菜谱 When 点详情 Then 不显示「看菜谱」按钮

### D042 · 抽中后「看菜谱」展开

- **类型**：UI 交互
- **触发场景**：抽中在家做卡
- **实现要点**：结果页底部加「🍳 看菜谱」按钮，点击展开为全屏菜谱视图
- **验收标准**：
  - [ ] Given 在家做卡 + 有菜谱 When 抽中 Then 显示「看菜谱」按钮
  - [ ] Given 用户点「看菜谱」 When 触发 Then 全屏展示 ingredients + steps

### D043 · 时间+难度+心情二级筛选

- **类型**：筛选
- **触发场景**：卡池顶部筛选器
- **实现要点**：3 个二级筛选 chip：`timeMinutes ≤ 30` / `difficulty ≤ 3` / `mood ∈ [comfort, healthy, treat]`
- **验收标准**：
  - [ ] Given 用户选「≤30min」 When 应用 Then 卡池过滤为 timeMinutes ≤ 30 的卡
  - [ ] Given 同时选时间和难度 When 应用 Then 走 AND 逻辑

### D044 · 接受卡片自动进入做菜模式（TaskRunnerProtocol）

- **类型**：跨模块联动
- **触发场景**：用户点「✅ 接受」在家做卡
- **实现要点**：
  ```swift
  // 任务执行器协议（模块 A / C 共享）
  protocol TaskRunner: AnyObject, ObservableObject {
      associatedtype Task
      var tasks: [Task] { get }
      var currentIndex: Int { get }
      func start()
      func pause()
      func resume()
      func complete()
      var onComplete: ((Bool) -> Void)? { get set }
  }
  
  // 模块 A 做菜模式实现
  final class RecipeTaskRunner: TaskRunner {
      let tasks: [Recipe.Step]
      // 计时器 + 步骤勾选 + 食材提醒
  }
  
  // 模块 C 通用任务实现
  final class GenericTaskRunner: TaskRunner {
      let tasks: [SubTask]
      // 计时器 + 完成打钩
  }
  ```
  在家做卡接受 → 注入 `RecipeTaskRunner` → 复用 TaskRunnerView 全屏 UI
- **验收标准**：
  - [ ] Given 在家做卡 When 点「接受」 Then 跳转做菜模式全屏视图
  - [ ] Given 做菜模式完成 When 所有 step 完成 Then 全屏庆祝 + 返回历史
  - [ ] Given RecipeTaskRunner 与 GenericTaskRunner When 共享 TaskRunnerView Then UI 一致（计时器/庆祝/历史写入）

### D045 · 「我做过」进收藏

- **类型**：用户操作
- **触发场景**：做菜模式完成
- **实现要点**：完成时弹「⭐ 加收藏」按钮；同时维护 `UserCookedRecord`（想做/已做过两类）
- **验收标准**：
  - [ ] Given 做菜模式完成 When 弹出 Then 「⭐ 加收藏」按钮可点
  - [ ] Given 用户点「加收藏」 When 触发 Then 卡片加入「已做过」收藏夹

### D046 · 进度数字「已解锁 X/80」

- **类型**：成就/进度展示
- **触发场景**：卡池顶部 / 设置页
- **实现要点**：`@AppStorage("cookedCount")` 维护解锁数；显示格式「已解锁 X / 80」
- **验收标准**：
  - [ ] Given 用户做过 5 道菜 When 进入卡池顶部 Then 显示「已解锁 5 / 80」
  - [ ] Given 数字变化 When 自动刷新 Then ≤ 1s 延迟

### D047 · 食材反向查询 v1.1 上

- **类型**：v1.1+ 功能
- **触发场景**：用户在卡池顶部输入食材
- **实现要点**：v1 仅占位按钮（点击提示「v1.1 上线」），v1.1 接入食材标签反向匹配
- **验收标准**：
  - [ ] Given v1 用户点「食材查询」 When 触发 Then 弹 Toast「v1.1 上线，敬请期待」
  - [ ] Given v1.1 上线 When 用户输入「鸡蛋」 Then 返回含鸡蛋的所有菜

### D048 · 季节/时段轻量推荐

- **类型**：软调权
- **触发场景**：抽签算法
- **实现要点**：卡片加 `seasonWeights: [Season: Double]`（春/夏/秋/冬），按当前季节乘数
- **验收标准**：
  - [ ] Given 夏季 + 卡片 seasonWeights.summer = 1.5 When 抽签 Then 该卡权重 × 1.5
  - [ ] Given 冬季 + 卡片 seasonWeights.summer = 1.5 When 抽签 Then 该卡权重 × 0.7

#### 6.1.5 成熟度完善（D049-D056）

### D049 · 类别冷却

- **类型**：抽签引擎硬屏
- **触发场景**：抽签过滤阶段
- **实现要点**：`count24h(category) < 2` → 否则排除；接近上限（=1）时 × 0.7 软化
- **验收标准**：
  - [ ] Given 类别 24h 已抽 2 次 When 再抽 Then 该类别全部候选排除
  - [ ] Given 类别 24h 已抽 1 次 When 再抽 Then 该类别候选权重 × 0.7

### D050 · 餐次平衡

- **类型**：抽签引擎软调权
- **触发场景**：抽签过滤后阶段
- **实现要点**：`mealTimeFactor`：午餐/晚餐按「上一餐 category」调整主食:菜:汤 = 1:1:0.5（详见附录 A.B.2.3）
- **验收标准**：
  - [ ] Given 上一餐=主食 + 当前午餐 When 100 次抽样 Then 主食 ≤ 50 次，菜 ≥ 50 次，汤 ≥ 30 次
  - [ ] Given 早餐时段 When 抽样 Then 不应用 mealTimeFactor（return 1.0）

### D051 · 风格偏好

- **类型**：抽签引擎软调权
- **触发场景**：抽签过滤后阶段
- **实现要点**：`styleFactor`：长期偏好 + 7 天最近未吃过 → × 1.5；最近吃过 → × 0.7
- **验收标准**：
  - [ ] Given 用户偏好粤菜 + 7d 未吃 When 抽样 Then 粤菜候选权重 × 1.5
  - [ ] Given 用户 7d 内吃过川菜 When 抽样 Then 川菜候选权重 × 0.7

### D052 · 品牌冷却

- **类型**：抽签引擎硬屏 + 兜底按钮
- **触发场景**：抽签过滤阶段 + 用户主动破例
- **实现要点**：`count7d(brand) < 1` → 否则排除；UI 加「我就要这个」按钮（× 1.0 重抽 1 张）
- **验收标准**：
  - [ ] Given 品牌 7d 已抽 1 次 When 再抽 Then 该品牌全部候选排除
  - [ ] Given 排除后 + 用户点「我就要这个」 When 触发 Then 强制返回该品牌卡 1 张（warning UI）

### D053 · 过敏硬屏

- **类型**：抽签引擎硬屏
- **触发场景**：抽签过滤阶段（最优先）
- **实现要点**：用户启动时强制填过敏原（即使「无」）；`card.allergens ∩ user.allergens == ∅` → 否则排除
- **验收标准**：
  - [ ] Given 用户有花生过敏 + 候选含花生 When 抽签 Then 花生被硬屏
  - [ ] Given 用户未填过敏原 + 首次启动 When 打开 Then 强制要求填（含「无」选项）
  - [ ] Given 硬屏后候选 = 0 When 抽签 Then 走兜底返回警告级（D006）

### D054 · 主料去重

- **类型**：抽签引擎硬屏
- **触发场景**：抽签过滤阶段
- **实现要点**：`count24h(mainIngredient) == 0` → 否则排除（v1 强制）
- **验收标准**：
  - [ ] Given 主料「鸡蛋」24h 已抽 1 次 When 再抽 Then 含「鸡蛋」候选全部排除
  - [ ] Given 排除后候选 = 0 When 抽签 Then 走兜底 Banner（D007）

### D055 · 人数份

- **类型**：数据字段
- **触发场景**：结果页 / 卡片详情
- **实现要点**：`Card.serves: Int`，默认 1，UI 显示「🍽️ 适合 X 人」
- **验收标准**：
  - [ ] Given 卡片 serves=2 When 显示 Then 「适合 2 人」标签
  - [ ] Given 用户手动改 serves When 保存 Then 更新卡片字段

### D056 · 营养均衡 v1.1 上

- **类型**：v1.1+ 功能
- **触发场景**：v1.1+ 抽签统计
- **实现要点**：v1 占位（设置页显示「v1.1 上线」），v1.1 按周聚合营养（蛋白质/碳水/脂肪）
- **验收标准**：
  - [ ] Given v1 用户看营养统计 When 显示 Then 提示「v1.1 上线」
  - [ ] Given v1.1 上线 When 用户点统计 Then 显示本周营养饼图

---

### 6.2 模块 B · 玩什么（点子库 · v1 替换 · 7 决策 · D057-D063）

> **修订说明（v1.2 → v1.3 用户拍板）**：v1 将「玩啥」占位**改回点子库**（不是「喝啥」）。与吃啥/做啥/拍啥**完全不重叠**，复用通用抽签引擎。

#### 6.2.1 卡池结构

```
玩啥（点子库）
├── 🏠 室内（10-15 张 · 看书/做饭/整理/手工）
├── 🌳 室外（10-15 张 · 散步/骑行/公园/野餐）
├── 🧍 单人（8-12 张 · 看电影/冥想/写作）
└── 👥 多人（8-12 张 · 桌游/球类/聚会/露营）
```

#### 6.2.2 决策清单

### D057 · 模块定位 - 周末点子库（不与吃啥重复）

- **类型**：模块定位
- **触发场景**：v1 上架
- **实现要点**：Tab 名「玩啥」，副标题「室内·室外·单人·多人，不无聊的 30 个点子」
- **核心差异化**（与吃啥不重叠）：
  - 吃啥：解决「吃什么」→ 食物领域
  - 玩啥：解决「玩什么/做什么」→ 活动领域
  - **两模块零字段重叠**（food vs activity 是正交维度）
- **验收标准**：
  - [ ] Given v1 安装 When 进入「玩啥」Tab Then Tab 显示「玩啥」+ 副标题
  - [ ] Given 原 v1「喝啥」 When 替换 Then 旧 Tab 不再出现（历史记录保留）
  - [ ] Given 玩啥与吃啥对比 When 检查字段 Then **无任何重叠字段**（不重复）

### D058 · 30-50 张点子卡

- **类型**：内容密度
- **触发场景**：v1 上架前
- **实现要点**：4 卡池合计 38-58 张内置点子卡（v1.1+ 扩到 80+）
- **v1 视觉呈现**：见 §9.3 首屏呈现模式（D139 占位方案 / D140 v1.1 真实图）
- **验收标准**：
  - [ ] Given v1 安装 When 首次进入「玩啥」 Then 立即可见 ≥ 38 张卡
  - [ ] Given 卡池空 When 抽签 Then 走兜底 Banner

### D059 · 4 类卡池（室内/室外/单人/多人）

- **类型**：卡池结构
- **触发场景**：用户进入 Tab
- **实现要点**：Tab 顶部 4 个卡池 chip，按用户历史偏好自动选默认（首次按本地时段）
  - **🏠 室内**：10-15 张（看书/做饭/整理/手工）
  - **🌳 室外**：10-15 张（散步/骑行/公园/野餐）
  - **🧍 单人**：8-12 张（看电影/冥想/写作）
  - **👥 多人**：8-12 张（桌游/球类/聚会/露营）
- **验收标准**：
  - [ ] Given Tab 顶部 When 显示 Then 4 个 chip 横向排列
  - [ ] Given 用户切卡池 When 触发 Then 卡池过滤 + 重新抽签
  - [ ] Given 首次进入 + 当前时段 14:00 When 触发 Then 默认推「室外」（午后户外倾向）

### D060 · 耗时字段（15/30/60/120 分钟）

- **类型**：数据字段
- **触发场景**：卡片详情 / 筛选
- **实现要点**：`Card.timeMinutes: Int`，枚举 15 / 30 / 60 / 120 分钟，UI 显示「⏰ X 分钟」
- **验收标准**：
  - [ ] Given 卡片 timeMinutes=30 When 显示 Then 「⏰ 30 分钟」
  - [ ] Given 用户筛选「≤30min」 When 应用 Then 卡池过滤为 timeMinutes ≤ 30

### D061 · 费用字段（免费/付费）

- **类型**：数据字段
- **触发场景**：卡片详情 / 筛选
- **实现要点**：`Card.costLevel: Free | Low(<¥50) | High(>¥50)`，对应 UI 💚 / 💛 / ❤️
- **验收标准**：
  - [ ] Given 卡片 costLevel=Free When 显示 Then 「💚 免费」
  - [ ] Given 用户筛选「只看免费」 When 应用 Then 只显示 Free 卡

### D062 · 复用通用抽签引擎

- **类型**：架构
- **触发场景**：抽签时
- **实现要点**：模块 B 走 `RuleBasedEngine.draw(pool:)`，与模块 A 共享 `DrawContext`
- **验收标准**：
  - [ ] Given 任意 Tab When 抽签 Then 都走 `RuleBasedEngine` 单例
  - [ ] Given 引擎升级到 AI 时（v1.1）Then B 不需改业务代码

### D063 · v1.1+ 接入大众点评必玩榜 / 活动行

- **类型**：v1.1+ 扩展
- **触发场景**：v1.1+
- **实现要点**：v1 占位「附近活动 v1.1 上线」，v1.1 接大众点评必玩榜 + 活动行 API
- **验收标准**：
  - [ ] Given v1 用户点「附近活动」 When 触发 Then 弹 Toast「v1.1 上线」
  - [ ] Given v1.1 上线 + 授权位置 When 点 Then 返回附近 3km 内活动列表

---

### 6.3 模块 C · 现在做点啥（13 决策 · D064-D076）

#### 6.3.1 子功能结构：3 个并列

1. **大目标拆解**（关键词模板：写/学/准备/整理/做 兜底，4 步左右）
2. **5min 微任务池**（80+ 个预置，6 大类：整理/养护/身体/社交/休息/微计划）
3. **拖延急救**（10-15 个极简动作：站起来/喝口水/深呼吸）

#### 6.3.2 决策清单

### D064 · 关键词模板

- **类型**：大目标拆解引擎
- **触发场景**：用户输入目标文本
- **实现要点**：正则匹配 `写|学|准备|整理|做` 关键词，对应 5 套模板（写文 / 学习 / 准备 / 整理 / 制作），每套模板含 4-6 步子任务
- **验收标准**：
  - [ ] Given 用户输入「写周报」 When 提交 Then 返回 4 步模板「打开文档 → 列大纲 → 写每点 → 检查提交」
  - [ ] Given 用户输入「学吉他」 When 提交 Then 返回 4 步模板
  - [ ] Given 关键词不命中 When 提交 Then 走兜底模板「拆 3 步 → 先做第一步 → 完成 → 庆祝」

### D065 · 4 步左右

- **类型**：任务粒度
- **触发场景**：模板生成
- **实现要点**：每套模板固定 4 步（v1.1+ 可由用户配置步数）
- **验收标准**：
  - [ ] Given 任意输入 When 模板生成 Then 步数 ∈ [3, 5]

### D066 · 可增删改

- **类型**：用户操作
- **触发场景**：模板步骤展示
- **实现要点**：每步右侧有「⋮」菜单 → 增 / 删 / 改；改保存到 `UserTaskList`
- **验收标准**：
  - [ ] Given 模板步骤 When 显示 Then 每步可增删改
  - [ ] Given 用户改完 When 保存 Then 下次进入相同关键词模板加载用户修改版

### D067 · 80+ 个

- **类型**：内容密度
- **触发场景**：5min 微任务池
- **实现要点**：6 大类合计 ≥ 80 个预置微任务
- **验收标准**：
  - [ ] Given 用户进入微任务 When 展示 Then 总任务数 ≥ 80

### D068 · 可自定义

- **类型**：用户操作
- **触发场景**：微任务池
- **实现要点**：用户可新增自定义任务，存 `UserMicroTask`，与预置任务同池
- **验收标准**：
  - [ ] Given 用户点「➕ 加任务」 When 触发 Then 弹出新增表单
  - [ ] Given 用户保存 When 触发 Then 任务出现在池中，参与下次抽签

### D069 · 独立按钮

- **类型**：UI 交互
- **触发场景**：Tab 主页
- **实现要点**：「大目标」「微任务」「急救」3 个并列按钮（不用 Tab 内再分 Tab）
- **验收标准**：
  - [ ] Given Tab 主页 When 显示 Then 3 个按钮横向排列
  - [ ] Given 用户点「微任务」 When 触发 Then 进入微任务抽签页

### D070 · 极简动作

- **类型**：内容
- **触发场景**：拖延急救
- **实现要点**：10-15 个动作，标题 ≤ 8 字（如「深呼吸」「喝口水」「站起来」「看下窗外」）
- **验收标准**：
  - [ ] Given 急救池 When 显示 Then 所有动作标题 ≤ 8 字
  - [ ] Given 急救池 When 显示 Then 动作数 ∈ [10, 15]

### D071 · 2min 默认时长

- **类型**：任务执行 UI
- **触发场景**：用户接受微任务
- **实现要点**：默认 2min 倒计时；用户可手动调整为 1/3/5/10 min
- **验收标准**：
  - [ ] Given 用户接受微任务 When 进入执行 Then 默认 2:00 倒计时
  - [ ] Given 用户调时长 When 选择 Then 倒计时按新值重置

### D072 · 弹"再来 2min"

- **类型**：UI 交互
- **触发场景**：倒计时归零
- **实现要点**：归零时弹「🦊 再来 2 分钟？」+ 「够了」「继续 2min」两按钮
- **验收标准**：
  - [ ] Given 倒计时归零 When 触发 Then 弹底部 Toast「再来 2 分钟？」
  - [ ] Given 用户点「够了」 When 触发 Then 全屏庆祝 + 写入历史

### D073 · 全屏庆祝+音效

- **类型**：反馈
- **触发场景**：任务完成
- **实现要点**：全屏 emoji 动画（🎉 + 🦊）+ `AudioServicesPlaySystemSound(1322)`；设置可关
- **验收标准**：
  - [ ] Given 任务完成 When 触发 Then 全屏显示庆祝动画 ≥ 1.5s
  - [ ] Given 设置关音效 When 完成 Then 仅视觉，无声音

### D074 · 不惩罚

- **类型**：设计原则
- **触发场景**：用户中途退出
- **实现要点**：用户中途退出任务，不写「失败」记录，仅写「未完成」（不计入成就负面项）
- **验收标准**：
  - [ ] Given 用户中途退出 When 触发 Then 历史记录显示「未完成」（非「失败」）
  - [ ] Given 成就系统 When 计算 Then 不扣分

### D075 · 不计时（急救）

- **类型**：急救子功能
- **触发场景**：用户选急救
- **实现要点**：急救动作不进入计时器，直接显示「🦊 你已经做完了对吧？深呼吸一下感觉如何？」→ 完成按钮
- **验收标准**：
  - [ ] Given 急救动作 When 选中 Then 不显示倒计时
  - [ ] Given 用户点完成 When 触发 Then 写入历史（不计时）

### D076 · 保存所有任务

- **类型**：历史记录
- **触发场景**：任意任务完成
- **实现要点**：所有接受过的任务（含未完成）写入 `UserTaskRecord`，可查看历史
- **验收标准**：
  - [ ] Given 任意任务完成/退出 When 触发 Then 写入 `UserTaskRecord`
  - [ ] Given 用户看历史 Tab Then 显示最近 1000 条

---

### 6.4 模块 D · 拍照姿势（10 决策 · D077-D086）

#### 6.4.1 7 类卡池

🧍 单人 (12-15) / 💑 情侣 (10-12) / 👯 朋友 (10-12) / 🏪 探店 (8-10) / ✈️ 旅游 (10-12) / 📸 ins (8-10) / 🤪 搞笑 (8-10) —— 合计 66-81 张

#### 6.4.2 决策清单

### D077 · emoji + SF Symbols 占位（v2 沉浸式大图 · 天然符合）

- **类型**：内容展示
- **触发场景**：v1 卡片详情
- **实现要点**：每张卡 = 大 emoji（48pt）+ SF Symbol（20pt）+ 标题 + 副标题；v1.1 加线稿图，v1.2+ 真实图库
- **v2 适配**：拍啥模块天然符合 §9.3 首屏沉浸式大图（emoji 本身就是"图标"，占视觉焦点 65%）
- **验收标准**：
  - [ ] Given v1 卡片 When 显示 Then 大 emoji + SF Symbol 占位
  - [ ] Given v1.1 升级 When 显示 Then 优先线稿图，emoji 兜底

### D078 · 7 类

- **类型**：卡池结构
- **触发场景**：Tab 顶部卡池切换
- **实现要点**：7 类卡池横向 chip 排列，单选
- **验收标准**：
  - [ ] Given Tab 顶部 When 显示 Then 7 个 chip 横向排列
  - [ ] Given 用户切卡池 When 触发 Then 卡池过滤 + 重新抽签

### D079 · 拍啥 Tab 多卡池

- **类型**：架构
- **触发场景**：抽签引擎
- **实现要点**：拍啥 Tab 内置 7 个 CardPool 共享一个 Scene
- **验收标准**：
  - [ ] Given 拍啥 Tab When 抽签 Then 在当前选中卡池内抽
  - [ ] Given 切换卡池 When 抽签 Then 在新卡池内抽

### D080 · 60-80 个

- **类型**：内容密度
- **触发场景**：v1 上架前
- **实现要点**：7 卡池合计 ≥ 66 张卡（按各卡池下限）
- **验收标准**：
  - [ ] Given v1 安装 When 进入拍啥 Then 每卡池 ≥ 下限张数

### D081 · 大 emoji + 小 SF Symbol + 标题副标题

- **类型**：UI 规范
- **触发场景**：卡片展示
- **实现要点**：48pt emoji + 20pt SF Symbol 居中 + 24pt 标题 + 16pt 副标题
- **验收标准**：
  - [ ] Given 卡片详情 When 显示 Then 字体规格符合
  - [ ] Given Dynamic Type 调到 XXXL When 显示 Then 字号同比缩放（D108）

### D082 · 底部小气泡 banner

- **类型**：UI 组件
- **触发场景**：用户进 Tab
- **实现要点**：底部 80pt 高度气泡，显示「📐 抬高 15°」等极简引导
- **验收标准**：
  - [ ] Given 用户进 Tab When 显示 Then 底部气泡显示 1 条引导
  - [ ] Given 用户上滑卡片 When 触发 Then 气泡自动消失（D084）

### D083 · 进 Tab 显示

- **类型**：触发时机
- **触发场景**：用户每次进 Tab
- **实现要点**：每次进 Tab 显示 1 条引导（按抽到的卡自动选文案）
- **验收标准**：
  - [ ] Given 用户首次进 Tab When 触发 Then 气泡显示
  - [ ] Given 用户第二次进 Tab When 触发 Then 气泡显示（新引导）

### D084 · 1 条

- **类型**：内容约束
- **触发场景**：气泡展示
- **实现要点**：每次进 Tab 只显示 1 条引导文案，不堆叠
- **验收标准**：
  - [ ] Given 进 Tab When 显示 Then 引导文案 = 1 条
  - [ ] Given 用户上滑后 When 再进 Tab Then 显示新 1 条

### D085 · 长按顶部 emoji 切换

- **类型**：UI 交互
- **触发场景**：用户长按 Tab 顶部 emoji 装饰
- **实现要点**：长按顶部 1s 弹出「换个主题皮肤」菜单（5 套预设）
- **验收标准**：
  - [ ] Given 用户长按顶部 emoji When 触发 Then 弹出主题选择
  - [ ] Given 用户选新主题 When 触发 Then 整个 Tab 切换主题

### D086 · 沿用通用收藏

- **类型**：架构
- **触发场景**：用户点 ⭐
- **实现要点**：复用通用抽签引擎的 `Favorite` 机制，姿势卡 + 吃啥卡同表
- **验收标准**：
  - [ ] Given 用户收藏姿势卡 When 显示 Then 在「我的收藏」Tab 与吃啥收藏同列

---


---

## 7. 通用抽签引擎（25 决策 · D001-D025）

### 7.1 数据模型决策

### D001 · 标题双轨

- **类型**：数据展示
- **触发场景**：抽签结果页
- **实现要点**：`Card.title`（默认）+ `Card.customTitle?`（用户覆盖）
- **验收标准**：
  - [ ] Given 自定义标题非空 When 显示 Then 优先 customTitle
  - [ ] Given 自定义标题为空 When 显示 Then 用 title

### D002 · 元数据存储（字段分层）

- **类型**：架构
- **触发场景**：卡片字段扩展
- **实现要点**：明确字段分层（避免 v1 含糊）：
  | 字段类型 | 字段示例 | 存储位置 |
  |---|---|---|
  | **索引字段**（必查）| id / sceneID / poolID / createdAt | SwiftData 字段（`#Index`） |
  | **频繁查询字段** | category / brand / isHidden / excludeUntil / caffeineLevel | SwiftData 字段（带索引） |
  | **详情显示字段** | subtitle / difficulty / timeMinutes / serves / title / emoji | SwiftData 字段 |
  | **扩展/可选字段**（偶尔读）| style / mood / tags / nutritionFacts / customMetadata | `metadata: Data`（JSON 编码，懒加载） |
  | **大字段**（长文本）| recipe.steps / noteText / longDescription | `@Attribute(.externalStorage)`（SwiftData 自动存外部文件） |
- **验收标准**：
  - [ ] Given 给 Card 加新扩展字段（metadata） When 修改 Then 旧库自动迁移（D011 Schema 版本）
  - [ ] Given metadata 解析 When 失败 Then 返回空字典 + 警告日志（不崩溃）
  - [ ] Given 频繁查询字段（category） When 数据量 > 1000 Then 查询响应 < 50ms（走索引）
  - [ ] Given 大字段（recipe.steps） When 存储 Then 自动放到外部文件（SwiftData 默认）

### D003 · 用户卡池归属

- **类型**：架构
- **触发场景**：用户自定义卡
- **实现要点**：用户加的卡归到对应 Scene 的「我的卡」子卡池，与内置卡混合抽签
- **验收标准**：
  - [ ] Given 用户加 5 张吃啥卡 When 抽签 Then 这 5 张参与候选池
  - [ ] Given 用户删自定义卡 When 触发 Then 候选池立即移除

### D004 · Scene 单独建模

- **类型**：数据建模
- **触发场景**：跨 Tab 数据隔离
- **实现要点**：`Scene` 实体（id / type / title / icon），4 个 Scene（吃啥/玩啥/做啥/拍啥），每个 Scene 含多个 CardPool
- **验收标准**：
  - [ ] Given 4 个 Scene When 启动 Then 都加载到 `ModelContext`
  - [ ] Given 用户删 Scene 下所有卡 When 触发 Then Scene 本身不删

### 7.2 抽签算法决策

### D005 · 降权系数（两段衰减）

- **类型**：抽签引擎软调权
- **触发场景**：卡片被抽中后
- **实现要点**：避免 v1 单调 0.5^t 过度抑制（用户会感觉「喜欢的菜再也抽不到」），改用**两段衰减**：
  ```swift
  // 24h 内的被抽次数 t
  if t < 3 {
      weight_t = weight_0 × 0.5^t       // 急速衰减（1→0.5→0.25）
  } else if t < 7 {
      weight_t = weight_0 × 0.125       // 平台期（保底 1/8，不归零）
  } else {
      weight_t = 0                       // 完全屏蔽（>7 次，触发 Banner）
  }
  ```
- **验收标准**：
  - [ ] Given 卡片 24h 被抽 2 次 When 再抽 Then 权重 = 0.25
  - [ ] Given 卡片 24h 被抽 5 次 When 再抽 Then 权重 = 0.125（不归零，仍可命中）
  - [ ] Given 卡片 24h 被抽 8 次 When 再抽 Then 触发 Banner 兜底（D007）
  - [ ] Given 用户主观反馈 When 100 用户调研 Then ≥ 80% 不会觉得「喜欢的菜抽不到」

### D006 · 冷却期

- **类型**：抽签引擎硬屏
- **触发场景**：抽签过滤阶段
- **实现要点**：单卡 `excludeUntil = drawTime + 4h`；4h 内该卡 weight = 0；4h 后立即恢复原权重，不做半冷却
- **验收标准**：
  - [ ] Given 卡片 3h 前被抽 When 再抽 Then 该卡排除
  - [ ] Given 卡片 5h 前被抽 When 再抽 Then 该卡可命中

### D007 · 兜底策略（两级 · 删除 L3）

- **类型**：兜底
- **触发场景**：过滤后候选 = 0 / 全部冷却
- **实现要点**：**仅保留两级兜底，删除原 L3「忽略冷却」逻辑**（违反硬屏规则，偷偷破冷却会损害算法信任）：
  - **L1：候选为 0**（含全部冷却）→ 顶部 Banner「🦊 歇够了？加点新内容吧」+ 加卡按钮
  - **L2：仅警告级命中**（过敏原）→ 弹「⚠️ 含过敏原 X，确认接受？」+ 接受/重摇
  - **候选 ≥ 1 但全冷却**：**不再返回结果**，与 L1 合并处理（不偷偷破冷却）
  - **连续 3 次触发 L1**：进入「不决策模式」D134
- **验收标准**：
  - [ ] Given 所有候选被硬屏排除 When 抽签 Then 走 L1 返回 Banner + 加卡按钮
  - [ ] Given 仅警告级候选 When 抽签 Then 走 L2 弹确认
  - [ ] Given 候选 ≥ 1 但全冷却 When 抽签 Then **不返回结果**，走 L1（同「候选为 0」）
  - [ ] Given 用户点「加卡」 When 触发 Then 跳转「我的」→ 加卡页
  - [ ] Given 连续 3 次 L1 When 触发 Then 引导进入「不决策模式」D134

### D008 · 抽签并发

- **类型**：UI 锁定
- **触发场景**：动画进行中
- **实现要点**：「换一签」按钮在动画期间 disable + 顶部提示「🦊 等等，结果马上出来」
- **验收标准**：
  - [ ] Given 动画期间 When 用户点换一签 Then 按钮 disabled
  - [ ] Given 动画完成 When 触发 Then 按钮恢复可点

### 7.3 动画系统决策

### D009 · 洗牌动画（v1 跳过）

- **类型**：v1 跳过
- **触发场景**：—
- **实现要点**：v1 直接翻面，无洗牌；v1.1+ 可加洗牌动效
- **验收标准**：
  - [ ] Given v1 抽签 When 触发 Then 仅翻面动画

### D010 · 触发方式（仅按钮）

- **类型**：交互
- **触发场景**：用户主动抽签
- **实现要点**：v1 仅按钮触发，不接摇晃 / 3D Touch / 语音
- **验收标准**：
  - [ ] Given 用户进 Tab When 显示 Then 仅「🔄 换一签」按钮可触发

### D011 · 翻面方向

- **类型**：动画
- **触发场景**：结果呈现
- **实现要点**：Y 轴 3D 翻面（180°），0.6s ease-in-out
- **验收标准**：
  - [ ] Given 抽签结果 When 显示 Then Y 轴翻面
  - [ ] Given Reduce Motion 用户 When 显示 Then 跳过翻面直接显示结果（D108）

### D012 · 结果卡配色

- **类型**：视觉规范
- **触发场景**：结果展示
- **实现要点**：暖色统一背景（米白/奶油），emoji 区分类型；不按类别换色（避免视觉割裂）
- **验收标准**：
  - [ ] Given 任意结果卡 When 显示 Then 背景 = 米白/奶油色
  - [ ] Given 暗色模式 When 显示 Then 背景 = 深咖/炭灰（D107）

### D013 · 触觉反馈

- **类型**：UX 反馈
- **触发场景**：抽签 / 收藏 / 完成
- **实现要点**：`UIImpactFeedbackGenerator(.light)` 抽签 / `.medium` 收藏 / `.heavy` 完成；设置可关
- **验收标准**：
  - [ ] Given 用户抽签 When 触发 Then 轻微震动
  - [ ] Given 设置关震动 When 触发 Then 无震动

### D014 · 动画中状态

- **类型**：UI 状态
- **触发场景**：抽签进行中
- **实现要点**：按钮 disable + 顶部 spinner + 「🦊 帮你想一下~」
- **验收标准**：
  - [ ] Given 动画期间 When 显示 Then 按钮置灰 + spinner + 顶部文案

### 7.4 用户扩展决策

### D015 · 「我的」入口

- **类型**：导航
- **触发场景**：Tab 顶部
- **实现要点**：右上角头像/狐狸图标 → 抽屉，含「我的收藏」「成就」「设置」「反馈」「决策日记（v1.1）」
- **验收标准**：
  - [ ] Given 任意 Tab 顶部右上角 When 用户点 Then 抽屉滑出
  - [ ] Given 抽屉打开 When 显示 Then 5 个菜单项

### D016 · Emoji 选择器

- **类型**：用户输入
- **触发场景**：用户加卡时
- **实现要点**：iOS 系统 emoji 键盘 + 顶部「🦊 常用」快捷栏（10 个预设）
- **验收标准**：
  - [ ] Given 用户加卡 When 输入 emoji Then 系统键盘可用
  - [ ] Given 用户点快捷栏 When 触发 Then 立即填入预设 emoji

### D017 · 内置卡隐藏

- **类型**：用户操作
- **触发场景**：长按内置卡
- **实现要点**：长按 0.5s → 弹「标记不喜欢」「加备注」菜单；标记不喜欢 → `Card.isHidden = true`，参与下次过滤时排除
- **验收标准**：
  - [ ] Given 用户长按内置卡 When 触发 Then 弹出菜单
  - [ ] Given 标记不喜欢 When 触发 Then 该卡从候选池永久移除

### D018 · 标签来源

- **类型**：标签系统
- **触发场景**：卡片详情 / 筛选
- **实现要点**：每个 Scene 预设 5-10 个标签（如吃啥：川菜/粤菜/快手菜/低卡/夜宵），用户可加自定义标签
- **验收标准**：
  - [ ] Given 任意 Scene When 显示 Then 至少 5 个预设标签
  - [ ] Given 用户加自定义标签 When 保存 Then 该 Scene 下可选

### D019 · 收藏夹组织

- **类型**：收藏 UI
- **触发场景**：「我的收藏」Tab
- **实现要点**：按 `favoritedAt` 倒序，可选按 Scene 分组
- **验收标准**：
  - [ ] Given 用户收藏 10 张 When 进入收藏 Tab Then 按时间倒序
  - [ ] Given 用户切分组模式 When 触发 Then 按 Scene 分组

### 7.5 历史记录决策

### D020 · 历史保留（1000 条）

- **类型**：数据保留
- **触发场景**：每次抽签
- **实现要点**：`DrawRecord` 按 `createdAt` 升序，> 1000 条删除最旧
- **验收标准**：
  - [ ] Given 历史 ≥ 1000 条 When 新增 Then 自动删除最旧
  - [ ] Given 历史 < 1000 条 When 新增 Then 不删除

### D021 · 统计呈现

- **类型**：UI
- **触发场景**：设置 → 数据 → 统计
- **实现要点**：数字 + 饼图（按 Scene 分）+ 折线图（按周）；不引入第三方图表库（用 SwiftUI Charts）
- **验收标准**：
  - [ ] Given 用户点统计 When 显示 Then 3 类图表
  - [ ] Given 历史为空 When 显示 Then 空状态引导（D101）

### D022 · 导出/导入入口

- **类型**：数据备份
- **触发场景**：设置 → 数据
- **实现要点**：导出为 JSON（含收藏/自定义卡/历史/DecisionJournalEntry）；导入走 DocumentPicker，格式校验后写入
- **验收标准**：
  - [ ] Given 用户点导出 When 触发 Then 生成 JSON 文件 + 分享菜单
  - [ ] Given 用户导入 JSON When 触发 Then 校验格式 + 冲突提示（D102）

### D023 · 收藏编辑

- **类型**：用户操作
- **触发场景**：「我的收藏」Tab 长按
- **实现要点**：长按 → 弹「取消收藏 / 加备注」ActionSheet
- **验收标准**：
  - [ ] Given 收藏卡 When 长按 Then 弹出菜单
  - [ ] Given 用户加备注 When 保存 Then 详情页显示备注

### D024 · 历史清理

- **类型**：用户操作
- **触发场景**：设置 → 数据 → 清空
- **实现要点**：「清空历史」+「清空全部日记」两按钮，二次确认 Alert
- **验收标准**：
  - [ ] Given 用户点清空 When 触发 Then 弹 Alert「确认清空？此操作不可逆」
  - [ ] Given 用户确认 When 触发 Then 历史表清空

### D025 · 拒绝处理（冷却期 4h）

- **类型**：拒绝机制
- **触发场景**：用户点「换一签」
- **实现要点**：被拒绝的卡立即进入 4h 冷却（与被接受的卡相同），4h 后完全重置（不做「半冷却」）
- **验收标准**：
  - [ ] Given 用户点换一签 When 触发 Then 上张卡立即进入 4h 冷却
  - [ ] Given 4h 后 When 再抽 Then 该卡权重完全恢复（1.0）

### 7.6 多维平衡抽签算法（核心）

```
draw(pool, context):
    1. 过敏硬屏：candidates = pool.cards.where(∀allergen ∉ user.allergens)
    2. 单卡冷却：candidates = candidates.where(excludeUntil <= now)
    3. 类别冷却：candidates = candidates.where(category 在 24h 被抽 < 2 次)
    4. 品牌冷却：candidates = candidates.where(brand 在 7d 被抽 < 1 次)
    5. 主料去重：candidates = candidates.where(mainIngredient 在 24h == 0 次)
    6. 慢节奏上限：candidates = candidates.where(user.drawsToday < 3)
    7. 软调权：candidates.forEach { card -> card.weight *= mealTimeFactor / styleFactor / favoriteBoost / newCardBoost / timeOfDayFactor / historyDecay }
    8. 加权抽样：return weightedSampling(candidates)
```

> **完整参数表**：详见附录 A（抽签引擎权重参数表）

---


---

## 8. 共享功能（17 决策 · D087-D103）

### 8.1 启动引导

### D087 · 启动引导 3 屏

- **类型**：用户旅程
- **触发场景**：首次安装
- **实现要点**：3 屏固定文案，可跳过；非首次启动可设置中重看

| 屏 | 主标题 | 副标题 / 视觉 |
|---|---|---|
| 1 | **"嘿，想啥呢？"** 🦊 | "拿不定主意时，给你一个有趣的解决方案" + 小狐狸招手 |
| 2 | "4 个小帮手，让你动起来" | 4 模块卡片：🍚 吃啥 / 🎮 玩啥 / ✅ 做啥 / 📸 拍啥 |
| 3 | "不焦虑，不鸡汤" | "拿不定主意就摇一签" + 小狐狸递扑克牌 |

- **验收标准**：
  - [ ] Given 首次安装 When 启动 Then 强制走完 3 屏
  - [ ] Given 用户点跳过 When 触发 Then 直接进入 Tab（跳过仍标记已读）

### D088 · 过敏原管理（启动强制 + 后续可改）

- **类型**：法务 + 用户旅程
- **触发场景**：启动引导完成后 + 设置 → 反馈（后续修改）
- **实现要点**：
  - **启动时**：第 4 屏「过敏原设置」— 列出 8 类常见过敏原（花生/坚果/海鲜/蛋/奶/麦/大豆/芝麻）+ 「无」选项，强制勾选（含「无」）
  - **设置入口**：设置 → 反馈分组增加「过敏原管理」菜单（任何时候可改）
  - **修改二次确认**：用户改过敏原时弹 Alert「修改后未来抽签会重新过滤，但历史记录中已抽到的菜不会自动重新评估。如有严重过敏史请咨询医生」
  - **联动清理**：提供「清空历史」按钮（与 D024 联动）
  - **过敏原清单**（必填 + 可选）：
    | 必填 | 可选 |
    |---|---|
    | 「无」 | 花生 / 坚果 / 海鲜 / 蛋 / 奶 / 麦 / 大豆 / 芝麻 |
- **验收标准**：
  - [ ] Given 启动引导完成 When 进入 Then 强制弹过敏原设置
  - [ ] Given 用户未选任何 + 点保存 Then 按钮 disabled（必须勾选至少 1 项含「无」）
  - [ ] Given 用户勾选含花生 When 进入吃啥 Then 花生类候选硬屏
  - [ ] Given 用户在设置改过敏原 When 触发 Then 弹二次确认 Alert
  - [ ] Given 用户确认修改 When 触发 Then 未来抽签用新过敏原过滤，历史不重算

### D089 · 引导可重看

- **类型**：设置项
- **触发场景**：设置 → 关于 → 重看引导
- **实现要点**：重看时强制走完，不能单独跳屏
- **验收标准**：
  - [ ] Given 设置页 When 用户点「重看引导」 Then 立即进入第 1 屏

### 8.2 设置架构（4 类分组）

### D090 · 设置分组

- **类型**：信息架构
- **触发场景**：设置页
- **实现要点**：`Form { Section("外观") / Section("反馈") / Section("数据") / Section("关于") }`
- **验收标准**：
  - [ ] Given 设置页 When 显示 Then 4 个分组

### D091 · 外观设置

- **类型**：设置项
- **触发场景**：设置 → 外观
- **实现要点**：主题（系统/浅色/深色）+ 主色（米咖/抹茶/海雾）+ 强调色（暖橘/暖金/玫瑰）
- **验收标准**：
  - [ ] Given 用户切主色 When 触发 Then 全 App 立即生效
  - [ ] Given 用户选「系统」 When 系统切深色 Then App 跟随

### D092 · 反馈设置

- **类型**：设置项
- **触发场景**：设置 → 反馈
- **实现要点**：震动反馈开关 / 音效开关 / 启动引导显示开关 / 减少动效开关（D108 联动）
- **验收标准**：
  - [ ] Given 设置 → 反馈 When 显示 Then 4 个开关
  - [ ] Given 用户关震动 When 抽签 Then 无震动

### D093 · 数据设置

- **类型**：设置项
- **触发场景**：设置 → 数据
- **实现要点**：统计查看 / 导出 / 导入 / 清空历史 / 清空日记（v1.1）
- **验收标准**：
  - [ ] Given 设置 → 数据 When 显示 Then 5 个菜单项
  - [ ] Given 用户点导出 When 触发 Then 弹 ShareLink

### D094 · 关于设置

- **类型**：设置项
- **触发场景**：设置 → 关于
- **实现要点**：版本号 / 致谢 / 隐私政策链接 / 反馈邮件 / 重看引导 / **连点版本号 5 次进入调试模式**
- **验收标准**：
  - [ ] Given 设置 → 关于 When 显示 Then 6 个菜单项
  - [ ] Given 用户连点版本号 5 次 When 触发 Then 弹调试模式开关（D119）

### 8.3 分享 / 反馈 / 成就

### D095 · 截图分享卡片

- **类型**：导出
- **触发场景**：任意结果页「📤 分享」
- **实现要点**：1024×1024 PNG，包含 logo + emoji + 卡名 + 「想啥」水印 + 预设/留空文案（D038）
- **验收标准**：
  - [ ] Given 用户点分享 When 触发 Then 输出 PNG ≥ 1MB
  - [ ] Given 转发到微信/小红书 When 显示 Then 文字清晰可读

### D096 · 反馈入口

- **类型**：导航
- **触发场景**：每页右下角💌按钮
- **实现要点**：右下角悬浮按钮，点开跳转系统邮件 `MailComposer`；设置 → 关于也有「反馈邮件」入口
- **验收标准**：
  - [ ] Given 任意页面 When 显示 Then 右下角有💌按钮
  - [ ] Given 用户点💌 When 触发 Then 跳邮件 App（收件人：feedback@想啥.app）

### D097 · 成就系统（v1 仅 3 个核心 · 其余 v1.1）

- **类型**：成就
- **触发场景**：里程碑达成
- **实现要点**：**v1 仅上 3 个核心成就**，避免战线过长（8 个太多会变成 8 个都没诚意）：
  | 成就 | 解锁条件 | 解锁动效 | 验证方式 |
  |---|---|---|---|
  | 🆕 **新手试吃** | 完成首次抽签 | 全屏庆祝弹窗 🦊👏 | `DrawRecord.count >= 1` |
  | 🥢 **小试牛刀** | 累计抽签 10 次 | 成就墙 toast | `DrawRecord.count >= 10` |
  | 🆘 **救命稻草** | 首次使用「拖延急救」并完成 | 全屏庆祝 + "🦊 佩服你站起来了！" | `RescueActionRecord.count >= 1 && completedAt != nil` |
  其余 5 个（连吃一周 / 解锁 10 道菜 / 随手拍 / 老吃家 / 行动派）放 v1.1。
- **入口**：「我的」抽屉 → 成就墙
- **验收标准**：
  - [ ] Given 用户首次抽签 When 完成 Then 触发「新手试吃」+ 全屏庆祝
  - [ ] Given 用户进入「我的」→「成就墙」 When 显示 Then 已解锁 3 个 + 未解锁 5 个灰色
  - [ ] Given 成就解锁 When 触发 Then 动效 ≤ 3s 后自动消失

### D098 · 启动引导可跳过

- **类型**：用户旅程
- **触发场景**：非首次启动的用户
- **实现要点**：3 屏引导每屏右上角有「跳过」按钮；首次启动禁用跳过（D087 强制走完）
- **验收标准**：
  - [ ] Given 首次启动 When 引导 When 显示 Then 「跳过」按钮隐藏或 disable
  - [ ] Given 非首次启动 When 进入引导 Then 每屏右上「跳过」可点
  - [ ] Given 用户点跳过 When 触发 Then 直接进入 Tab 且标记已读

### D099 · 调试模式（连点版本号 5 次 · DEBUG 围栏）

- **类型**：开发期工具
- **触发场景**：设置 → 关于 → 连点版本号 5 次
- **实现要点**：
  - **整个连点逻辑都用 `#if DEBUG` 包裹**，生产 build 完全不响应（包括连点本身和调试 UI）
  ```swift
  // AppEnvironment 工具类
  enum AppEnvironment {
      #if DEBUG
      static let isDebug = true
      static let showDebugPanel = true
      #else
      static let isDebug = false
      static let showDebugPanel = false
      #endif
  }
  
  // 设置页版本号连点
  Text(version).onTapGesture(count: 5) {
      #if DEBUG
      showDebugAlert = true
      #else
      // 生产 build 完全无反应（不留任何 UX 痕迹）
      #endif
  }
  ```
  - 调试模式开关**不持久化**（每次启动关闭）
  - 调试 UI 顶部加红色横幅「⚠️ DEBUG BUILD」
  - 调试面板只显示 DrawEngineConfig + 抽签权重 JSON，**不显示真实用户数据**
- **验收标准**：
  - [ ] Given DEBUG build + 连点 5 次 Then 弹「进入调试模式？」
  - [ ] Given 用户确认 When 触发 Then 开启调试面板（顶部红色 ⚠️ 横幅）
  - [ ] Given Release build + 连点 5 次 Then **完全无反应**（连点本身也不触发）
  - [ ] Given 调试模式开启 When 抽签 Then 结果页可展开「因子明细」（每张候选的 6 个软调权因子的贡献值）
  - [ ] Given 调试面板 When 显示 Then 不包含任何 DrawRecord / Favorite 真实数据

### D100 · 物理倒扣计时（电池优化版）

- **类型**：物理交互
- **触发场景**：模块 C 微任务执行
- **实现要点**：
  - **电池优化**：进入执行页才启动 `startAccelerometerUpdates`（低功耗，~5mA）；退出执行页立即 `stopAccelerometerUpdates()`（防漏电）
  ```swift
  // 进入执行页
  motionManager.startAccelerometerUpdates(to: .main) { data, _ in
      guard let z = data?.acceleration.z else { return }
      if z > 0.85 { isFaceDown = true }    // 屏幕朝下阈值
      if z < 0.5  { isFaceDown = false }   // 翻回正面阈值
  }
  // 退出执行页（onDisappear）
  motionManager.stopAccelerometerUpdates()
  ```
  - **同时显示显式按钮**「▶ 直接开始」（CoreMotion 不可靠时的兜底）
  - 检测阈值：accelerometer.z > 0.85 持续 0.5s 才触发（防误启动）
- **验收标准**：
  - [ ] Given 用户进执行页 + 静止 1min When 检测 Then 电量消耗 < 1%（Instruments Energy Log 验证）
  - [ ] Given 用户退出执行页 When 触发 Then CoreMotion 完全停止（Energy Log 验证）
  - [ ] Given 用户接受微任务 When 进入执行页 Then 显示「🦊 翻过来开始」+ 显式「▶ 直接开始」按钮
  - [ ] Given 用户把手机倒扣 0.5s When CoreMotion 检测 Then 倒计时启动
  - [ ] Given 用户把手机翻回正面 When 触发 Then 倒计时暂停 + 提示「🦊 继续吗？」
  - [ ] Given 倒计时归零 When 触发 Then 全屏庆祝 + 震动反馈

### D101 · 真实姿势图库 v1.1+

- **类型**：v1.1+ 内容
- **触发场景**：v1.1+ 模块 D 卡片详情
- **实现要点**：人工收 50-100 张高质量姿势参考图，按 7 场景分类放内置 Assets；v1.1 用 AI 生图 / CC0 素材，v1.2+ 真人图必须有商业授权
- **验收标准**：
  - [ ] Given v1.1 上线 When 用户进「拍啥」Tab Then 每卡池首张卡显示真实图（非 emoji）
  - [ ] Given 用户长按图片 When 触发 Then 弹「保存到相册」选项
  - [ ] Given v1.1 上线 When 安装包大小 Then < 100 MB

### D102 · 反馈邮件

- **类型**：反馈渠道
- **触发场景**：用户点「💌」按钮 / 设置 → 关于 → 反馈邮件
- **实现要点**：调用系统 `MFMailComposeViewController`；收件人 `feedback@想啥.app`；主题预填「想啥 App v1.0 反馈」；附件自动附带 `log.txt`（最近 100 行）
- **验收标准**：
  - [ ] Given 用户点反馈 When 触发 Then 跳邮件 App（已预填收件人 + 主题）
  - [ ] Given 设备无邮件 App When 触发 Then 弹 Toast「请先配置邮件账户」+ 兜底复制邮箱到剪贴板
  - [ ] Given 设置 → 关于 → 反馈邮件 When 点 Then 同上

### D103 · 隐私政策 URL 上线

- **类型**：法务合规
- **触发场景**：v1 上架前
- **实现要点**：在 GitHub Pages 部署 `docs/privacy-policy.md`，URL 填入 App Store Connect；隐私政策核心「我们不收集任何数据」
- **验收标准**：
  - [ ] Given v1 上架前 When 隐私政策 URL 必须可访问
  - [ ] Given App Store 审核 When 提交 Then URL 可正常打开
  - [ ] Given URL 内容 When 显示 Then 含「数据收集 / 数据存储 / 第三方共享 / 联系方式」4 段

### D132 · 慢节奏重置逻辑（防跨午夜 / 改时区作弊）

- **类型**：业务规则
- **触发场景**：App 启动时 / 跨日时
- **实现要点**：
  ```swift
  func resetDrawCountIfNeeded() {
      let calendar = Calendar.current
      let today = calendar.startOfDay(for: .now)
      
      if let lastReset = UserDefaults.standard.object(forKey: "lastDrawReset") as? Date,
         calendar.isDate(lastReset, inSameDayAs: today) {
          return  // 今天已重置
      }
      
      UserDefaults.standard.set(0, forKey: "drawsToday")
      UserDefaults.standard.set(today, forKey: "lastDrawReset")
  }
  ```
  - 用本地日历日，不跟随时区变化重置
  - 改时区不触发重置（保留北京计数）
  - 改系统时间往前调不影响计数（用 `Date()` 实际时间）
- **验收标准**：
  - [ ] Given 北京 23:59 抽 1 次 When 跨到 00:01 Then `drawsToday = 0` 可再抽
  - [ ] Given 用户改时区到伦敦 When 触发 Then `drawsToday` 不重置（保留北京计数）
  - [ ] Given 用户改系统时间往前调 When 触发 Then 不影响计数

### D133 · 启动预热策略（ModelContainer 加载）

- **类型**：性能优化
- **触发场景**：App 启动时
- **实现要点**：
  ```swift
  @main
  struct xiangshaApp: App {
      let container: ModelContainer
      
      init() {
          self.container = try! ModelContainer(
              for: Schema([Scene.self, CardPool.self, Card.self, /* ... */]),
              migrationPlan: xiangshaMigrationPlan.self
          )
          // 预热：触发首次 fetch（避免首 Tab 加载时耗时）
          _ = container.mainContext.fetch(FetchDescriptor<Card>())
      }
      
      var body: some Scene {
          WindowGroup { ContentView() }
              .modelContainer(container)
      }
  }
  ```
- **验收标准**：
  - [ ] Given iPhone 13 / iOS 17.5 When 冷启动 Then < 1.5s 看到首 Tab
  - [ ] Given 启动耗时 When Instruments Time Profiler Then ModelContainer 创建 < 500ms

### D134 · 不决策模式（反焦虑差异化核心）

- **类型**：兜底模式
- **触发场景**：用户在任意模块连续 3 次触发 L1 兜底（候选为 0 / 全冷却）
- **实现要点**：
  - 第 3 次 L1 时弹「🦊 要不今天就不决定了？」
  - 进入「不决策模式」：展示 3 个「什么都不用想」选项：
    | 选项 | 文案 | 写入 |
    |---|---|---|
    | 🍜 「今天就吃上次那家」 | 重复上次 | v1 写 `UserDefaults.skippedCount`；v1.1 写 DecisionJournalEntry(action=.skipped) |
    | 📱 「今天就躺着刷手机吧」 | 摆烂 | 同上 |
    | 🌊 「今天就跟着感觉走吧」 | 随缘 | 同上 |
  - **核心价值**：体现反焦虑差异化（与 Forest 损失厌恶路线完全相反）
- **验收标准**：
  - [ ] Given 连续 3 次 L1 When 触发 Then 弹「不决策」提示
  - [ ] Given 用户选「不决定」 When 触发 Then 写入 `skippedCount += 1`
  - [ ] Given v1.1 上线 When 用户选「不决定」 Then 写入 DecisionJournalEntry

### D135 · 数据闭环 emoji 评分（v1 必加 · 反哺引擎）

- **类型**：用户反馈
- **触发场景**：用户点「✅ 做完了」或「⏭ 没做成」后
- **实现要点**：
  - **3 个 emoji 快选**（不是 5 星，emoji 更轻量）：
    | Emoji | 标签 | 权重调整 |
    |---|---|---|
    | 😋 | 好吃 / 好用 / 好看 | 该卡 7d weight × 1.5 |
    | 😐 | 一般般 | 该卡 weight × 1.0（不变） |
    | 🙅 | 踩雷了 | 该卡 7d weight × 0.3 + 标记不喜欢 |
  - 点完就走，不写文字
  - 数据写入 `Card.feedbackScore`（3 档 enum）+ 自动更新抽签权重
- **验收标准**：
  - [ ] Given 用户点「✅ 做完了」 When 触发 Then 弹 3 emoji 评分
  - [ ] Given 用户选 😋 When 触发 Then 该卡 7d weight × 1.5
  - [ ] Given 用户选 🙅 When 触发 Then 该卡 7d weight × 0.3 + 标记不喜欢
  - [ ] Given 用户未评分直接关闭 When 触发 Then 该次反馈不写，不影响推荐

### D136 · 小狐狸人设卡（v1 立即统一口径）

- **类型**：内容规范
- **触发场景**：所有提示文案撰写时
- **实现要点**：
  - **性格**：「佛系但有点好奇，不催你，但会偶尔吐槽」
  - **核心口吻**：「🦊 想好了吗？」「🦊 那就它啦~」「🦊 好眼光！」
  - **三种反应模板**：
    | 用户动作 | 小狐狸反应 |
    |---|---|
    | 接受了卡片 | 「🦊 好眼光！」/「🦊 就它啦~」 |
    | 换了 1 次 | 「🦊 好吧，再看看~」 |
    | 换了 5 次 | 「🦊 你是不是都不喜欢？要不自己加几个？」 |
  - **完整文案清单**（存入 `docs/fox-persona.md`，v1 上架前 ≥ 100 条）：
    | 场景 | 文案 |
    |---|---|
    | 抽签进行中 | 「🦊 帮你想一下~」 |
    | 抽中结果 | 「🦊 就是它啦，要不要再看看？」 |
    | 拒绝 1 次 | 「🦊 没事，再翻一张」 |
    | 兜底 L1 | 「🦊 歇够了？加点新内容吧」 |
    | 兜底 L2 | 「⚠️ 含过敏原 X，确认接受吗？」 |
    | 完成庆祝 | 「🦊👏 你居然真的做了！」 |
    | 不决策模式 | 「🦊 要不今天就不决定了？」 |
    | 启动引导 1 屏 | 「🦊 拿不定主意？」 |
- **验收标准**：
  - [ ] Given 任何文案 When 撰写 Then 按人设卡统一口径（小狐狸语气）
  - [ ] Given docs/fox-persona.md When v1 上架前 Then 至少 100 条提示语统一
  - [ ] Given 4 个 Tab 文案 When 显示 Then 全部用 🦊 emoji，不混用其他 IP

### D137 · 天气感知（v1 启动取一次天气）

- **类型**：v1 启动轻量集成
- **触发场景**：App 启动时
- **实现要点**：用 `WeatherKit`（Apple 原生，iOS 17 免费 500K 次/月）获取当前天气；写入 `UserProfile.weatherRaw`；抽签时按天气调整权重
  ```swift
  let weather = try await WeatherService.shared.weather(for: location)
  userProfile.weatherRaw = weather.currentWeather.condition.rawValue
  ```
  - 调整规则：
    | 天气 | 推荐权重加成 |
    |---|---|
    | ☀️ 晴 | 不调整 |
    | 🌧️ 雨 | 热汤面/火锅 × 1.3 |
    | ❄️ 雪 | 火锅/热饮 × 1.3 |
    | 🌫️ 雾 | 不调整 |
  - 用户拒绝位置权限 → 跳过（不影响主流程）
- **验收标准**：
  - [ ] Given 用户授权位置 + 启动 When 触发 Then 1s 内获取天气并写入 UserProfile
  - [ ] Given 下雨天 + 用户抽午餐 When 触发 Then 热汤面/火锅权重 × 1.3
  - [ ] Given 用户拒绝位置权限 When 触发 Then 不弹错误，抽签正常进行

### D138 · Schema 迁移代码规范（VersionedSchema 示例）

- **类型**：工程规范
- **触发场景**：v1.1+ 加字段时
- **实现要点**：
  ```swift
  // v1.0 schema
  enum SchemaV1: VersionedSchema {
      static var versionIdentifier: Schema.Version = .init(1, 0, 0)
      static var models: [any PersistentModel.Type] {
          [Scene.self, CardPool.self, Card.self, /* ... */]
      }
  }
  
  // v1.1 schema（加 nutritionFacts 字段）
  enum SchemaV1_1: VersionedSchema {
      static var versionIdentifier: Schema.Version = .init(1, 1, 0)
      static var models: [any PersistentModel.Type] {
          [Scene.self, CardPool.self, Card.self /* + nutritionFacts */, /* ... */]
      }
  }
  
  // 迁移计划
  enum xiangshaMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV1_1.self] }
      static var stages: [MigrationStage] { [migrateV1toV1_1] }
      
      static let migrateV1toV1_1 = MigrationStage.lightweight(
          fromVersion: SchemaV1.self,
          toVersion: SchemaV1_1.self
      )
  }
  ```
- **验收标准**：
  - [ ] Given v1.0 用户升级 v1.1 When 触发 Then 自动 lightweight 迁移
  - [ ] Given 迁移失败 When 触发 Then 启动恢复 backup.json（D093）
  - [ ] Given 迁移成功 When 触发 Then 所有旧数据完整保留

---


---

## 9. 跨模块联动（Routine 概念 + v1/v1.1 分级）

### 9.1 v1 基础联动

> **v1 不做完整 Routine，仅做被动联动**（不打断用户流程）

| 联动 | 触发 | UI |
|---|---|---|
| **时段-卡池联动** | 用户进 Tab | 按本地时间自动选卡池（D033 / D059） |
| **跨模块推荐 Banner** | 用户进 Tab | 顶部 60pt 高度 Banner，显示「今日推荐组合」点击展开 |
| **做菜模式打通** | 用户点「✅ 接受」在家做卡 | 跳做菜模式全屏视图（D044） |

### 9.2 v1.1 Routine 一键三抽

> **v1.1+ 完整 Routine**：预置 5-10 套「场景组合」（周末露营 / 雨天宅家 / 约会之夜 / 加班深夜 / 减脂一周）

```
Routine "周末露营一日" {
  morning:   scene = 玩啥, query = "户外"
  noon:      scene = 吃啥, query = "野餐"
  afternoon: scene = 拍啥, query = "户外/ins"
  evening:   scene = 做啥, query = "整理装备"
}
```

UI：Tab 顶部「今日推荐组合」Banner 可一键依次抽完。

---

### 9.3 首屏呈现模式（v2 沉浸式大图 · 2026-10-04 用户拍板）

> **来源**：用户原话「能不能生成，更直观的 JPG...首先看到的是一整盘...比较好看的照片。其他的信息的话，简单下滑可以查看到其他内容。」
> **设计理念**：**沉浸式大图 + 下滑更多信息**（参考大众点评 / 小红书 / Cookpad 美食卡片设计）
> **mockup 归档**：`docs/samples/m0-ui-previews-v2.md` + `docs/samples/assets/`

#### 9.3.1 三层级信息架构

```
首屏（65% 大图 + 35% 副标题）
  ↓ 上滑
中屏（顶部小图预览 + 元信息 + 标签 + 主按钮 + 次按钮）
  ↓ 继续上滑
详情（菜谱 / 任务详情 / 适合场景）
```

#### 9.3.2 模块适用范围

| 模块 | 是否用 v2 | 原因 |
|---|---|---|
| 🍚 吃啥 | ✅ | 食物视觉是核心吸引力 |
| 🎮 玩啥 | ✅ | 活动场景帮助用户想象 |
| 📸 拍啥 | ✅（天然符合）| 姿势参考图本身就是大图 |
| ✅ 做啥 | ❌ 不需要 | 任务本身就是文字（标题+步骤）|

#### 9.3.3 核心组件规范

| 组件 | 规格 |
|---|---|
| **顶部 pill 标签** | 磨砂玻璃背景 + emoji + 卡名，圆角 12pt |
| **主照片 / 色块** | 占屏 65%，3:4 竖版比例 |
| **副标题** | 一行极简（菜系 · 时间 · 份数） |
| **主按钮** | 全宽，填色（吃啥暖橘 / 玩啥薄荷绿 / 拍啥粉） |
| **次按钮** | 等宽 2 个，outline 样式 |
| **小狐狸气泡** | 照片下方，不被信息淹没 |

---

### D139 · 首屏沉浸式大图设计模式（v2 · 2026-10-04 用户拍板）

- **类型**：跨模块通用设计原则
- **触发场景**：用户抽中任意卡片（吃啥/玩啥/拍啥）
- **实现要点**：
  - **首屏 65% = 大照片或大色块占位**（吃啥食物色 / 玩啥活动场景 / 拍啥姿势参考）
  - **首屏 35% = 1 行副标题 + 底部小狐狸气泡**
  - **下滑揭示**：元信息（时间/难度/份数/过敏原）→ 标签云 → 主按钮 → 次按钮
  - **继续下滑揭示**：详细（菜谱/任务详情/适合场景）
  - **顶部 pill 标签**：磨砂玻璃 + emoji + 卡名
  - **主按钮填色 + 次按钮 outline**
- **设计参考**：大众点评 / 小红书 / Cookpad 的美食卡片设计
- **验收标准**：
  - [ ] Given 用户抽中吃啥卡 When 显示 Then 食物大图（或色块）占屏 65%
  - [ ] Given 用户抽中玩啥卡 When 显示 Then 活动场景图（或色块）占屏 65%
  - [ ] Given 用户上滑 When 触发 Then 显示元信息 + 标签 + 主按钮
  - [ ] Given 用户继续上滑 When 触发 Then 显示详细（菜谱/详情）
  - [ ] Given 任意卡片首屏 When 显示 Then 顶部 pill 标签 + 底部狐狸气泡 + 一行副标题

---

### D140 · v1 占位方案（无真实图时怎么呈现）

- **类型**：v1 内容生产方案
- **触发场景**：v1 上架时（无真实图）
- **实现要点**：
  - **沉浸式大色块**（米色 `#F5E6D3` 背景）+ **大 emoji**（120pt 居中）+ **卡名**（24pt 居中）
  - 布局与真实图**完全一致**，只换数据源（emoji 替代 photo）
  - 卡片结构：
    ```swift
    // v1 占位组件
    struct CardPhotoPlaceholder: View {
        let emoji: String
        let title: String
        let accentColor: Color  // 吃啥暖橘 / 玩啥薄荷绿 / 拍啥粉
        
        var body: some View {
            ZStack {
                Color("cardPlaceholderBG")  // Asset Catalog
                VStack(spacing: 12) {
                    Text(emoji).font(.system(size: 120))
                    Text(title).font(.title2).bold()
                }
            }
            .frame(height: 480)  // 占屏 65%
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    ```
  - **跟真实图无缝切换**：v1.1 上 `Card.photoAssetName` 字段，有图时显示图，无图时显示占位
- **验收标准**：
  - [ ] Given v1 安装包 When 抽中吃啥卡 Then 显示色块 + 大 emoji + 卡名（无真实图）
  - [ ] Given v1 占位组件 When 渲染 Then 跟未来真实图布局一致（无视觉跳跃）
  - [ ] Given v1.1 上线 When `Card.photoAssetName != nil` Then 优先显示真实图

---

### D141 · v1.1 真实图方案（实拍 + AI 生图混合）

- **类型**：v1.1 内容升级方案
- **触发场景**：v1.1 上线时
- **实现要点**：
  - **资源来源**：
    | 来源 | 数量 | 工作量 | 成本 |
    |---|---|---|---|
    | 实拍（签约摄影师） | 60-80 张 | 10-15 天 | ¥5000-8000 |
    | AI 生图（Foundation Models / 云 API） | 40-60 张 | 3-5 天 | ¥500-1500 |
    | CC0 图库（Unsplash / Pexels）| 备份 | 1 天 | 0 |
  - **资源规格**：
    | 项 | 规格 |
    |---|---|
    | 尺寸 | 1080×1440px（3:4）或 1170×2532px（9:16） |
    | 格式 | HEIC（首选）/ WebP |
    | 大小 | 单张 ≤ 300KB |
    | 命名 | `{scene}-{pool}-{id}.heic` |
    | 版权 | 自有 / 商业授权 / CC0 |
  - **数据结构**：
    ```swift
    @Model
    final class Card {
        // 现有字段...
        var photoAssetName: String?       // "eat-home-001.heic"
        var photoAI: Bool = false          // 是否 AI 生成
        var photoPhotographer: String?     // 摄影师署名（实拍）
    }
    ```
  - **上线节奏**：
    | 阶段 | 数量 | 时间 |
    |---|---|---|
    | v1.0 | 0 张（用 D140 占位方案） | 0 |
    | v1.1 灰度 | 30 张 | 第 1 周 |
    | v1.1 全量 | 80 张 | 第 2 周 |
    | v1.2 | 160 张（覆盖所有内置卡） | 第 3-4 周 |
- **验收标准**：
  - [ ] Given v1.1 上线 When 抽中带图卡 Then 显示真实食物照片（占屏 65%）
  - [ ] Given 实拍图 When 显示 Then 摄影师署名（hover/长按可见）
  - [ ] Given AI 生图 When 显示 Then 图标或水印标识（不冒充实拍）

---


---

## 12. 错误状态矩阵（新增）

| # | 错误场景 | 用户提示 | 兜底动作 |
|---|---|---|---|
| E01 | 抽签候选为 0（硬屏全排除） | 顶部 Banner「歇够了？加点新内容吧」 | 跳转「➕ 加卡」按钮 |
| E02 | 抽签候选仅警告级（过敏命中） | 「⚠️ 含过敏原 [花生]，确认接受？」 | 接受 / 重摇 二选一 |
| E03 | 单卡冷却命中全部候选 | 「都是熟悉的？明天再来」 | 提示解锁时间 |
| E04 | 数据导入失败（JSON 格式错） | 「文件格式不正确，请检查」 | 重试 / 取消 |
| E05 | 数据导入冲突（同 ID 不同内容） | 「发现 N 条冲突记录」 | 覆盖 / 跳过 / 合并 |
| E06 | SwiftData 迁移失败 | 「数据迁移失败，应用将重置」 | 备份 + 重置 |
| E07 | 分享卡生成失败（图片 OOM） | 「分享失败，请稍后重试」 | 重试 |
| E08 | 一天 3 次已用完 | 「今天已经做了 3 个决定啦，明天继续~」 | 按钮 disable |
| E09 | iCloud 同步冲突（v1.1） | 「检测到 iCloud 备份，是否恢复？」 | 恢复 / 保留本地 |
| E10 | 隐私政策 URL 加载失败 | 「隐私政策暂时无法加载」 | 重试 |

---


---

## 13. 空状态设计（新增）

| # | 空场景 | 文案 | 主操作 |
|---|---|---|---|
| S01 | 卡池为空（自定义卡池） | 「还没有卡，添加你的第一张吧」 | [➕ 加卡] |
| S02 | 历史为空 | 「还没有决策记录」+ 小狐狸图 | [跳转抽签] |
| S03 | 收藏为空 | 「收藏的卡片会出现在这里」 | [跳转抽签] |
| S04 | 日记为空（v1.1） | 「每天的小决定都在这里汇聚」 | [跳转抽签] |
| S05 | 通知权限拒绝（v1.1+） | 「不开启也没关系，主动来就好」 | [关闭] |
| S06 | 导出成功但无内容 | 「暂无内容可导出」 | [关闭] |
| S07 | 加载超时 | 「加载慢了点，再试一次？」 | [重试] |

---


---

## 15. 上架元数据（新增）

### 15.1 App Store 元数据

| 项 | 内容 |
|---|---|
| 主标题（zh-CN） | 想啥 - 拿不定主意时的好帮手 |
| 主标题（en-US） | Pick Now - Your Daily Decision Buddy |
| 副标题 | 治愈系日间决策引擎 |
| 关键词 | 决策,抽签,吃什么,喝什么,拖延症,拍照姿势,选择困难 |
| 分类 | 效率 / 生活 |
| 年龄分级 | 4+ |
| 价格 | 免费（内购可选） |
| 隐私政策 URL | https://想啥.app/privacy（待上线 GitHub Pages） |

### 15.2 截图（5 张，iPhone 14 Pro）

1. 吃啥主屏（带牌面翻面瞬间）
2. 玩啥主屏（点子库）
3. 做菜模式（步骤 + 计时器）
4. 拍啥（姿势引导）
5. 决策日记（社交证明 · v1.1）

### 15.3 描述模板

「还在为吃什么、喝什么、做什么、拍什么犹豫？想啥用治愈系抽签体验，让每个小决定都有趣起来。一天 3 次，刚刚好。」

---
