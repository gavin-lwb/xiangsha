# 「想啥」Technical Specification (SPEC)

> **代号**：想啥（产品名，主）/ Pick Now（英文副名）/ xiangsha（工程名 · Xcode scheme）
> **平台**：iOS 17+（Xcode / SwiftUI / SwiftData）
> **来源**：拆分自 `DEVELOPMENT.md` v1.3（2026-10-04）
> **范围**：数据架构 / 非功能性需求 / 抽签引擎参数表 / 测试矩阵
**不重复**：产品需求见 `00-PRD.md`，协作规范见 `02-AGENTS.md`，路线图见 `03-ROADMAP.md`

---

## 10. 数据架构（SwiftData）

### 10.1 实体清单

| # | 实体 | 主要字段 | 关系 |
|---|---|---|---|
| 1 | `DecisionScene` | id / type / title / icon | 1 → n CardPool |
| 2 | `CardPool` | id / sceneID / name / icon | 1 → n Card |
| 3 | `Card` | id / sceneID / poolID / title / customTitle / emoji / category / brand / allergens / difficulty / timeMinutes / weight / excludeUntil / isUserCreated / isHidden / createdAt / updatedAt / metadata | 1 → n DrawRecord |
| 4 | `DrawRecord` | id / cardID / createdAt / action（accept/reject/redraw/skip — 替代独立 DrawAction 实体）/ result | n → 1 Card |
| 5 | `UserProfile` | id / allergens / preferredStyles / drawsToday / lastDrawDate / lastResetDate | 1 → 1 |
| 6 | `Favorite` | id / cardID / favoritedAt / noteText | — |
| 7 | `UserTaskRecord` | id / taskID / createdAt / completedAt / status | — |
| 8 | `DecisionJournalEntry`（v1.1） | id / sceneRawValue / cardSnapshotID / cardSnapshot / action / createdAt / completedAt / feedbackRawValue / noteText / moodEmoji | — |
| 9 | `CardSnapshot`（v1.1） | id / title / emoji / category / style / sceneRawValue / tags / capturedAt | — |
| 10 | `Routine`（v1.1） | id / name / steps / enabled | 1 → n RoutineStep |
| 11 | `RoutineStep`（v1.1） | id / sceneRawValue / query / order | — |

### 10.2 ER 图

```
DecisionScene (1) ─── (n) CardPool
                      │
                      │ (1)
                      ▼
                     (n)
                    Card ────── (n) ───── DrawRecord
                      │                        │
                      │ (1)                    │ (n)
                      ▼                        ▼
                  CardSnapshot (冗余存储)
                      
                   DrawRule (参数化配置)

UserProfile (1) ─── (1) DrawCounter
Favorite (n) ─── (1) Card
UserTaskRecord (独立)
```

### 10.3 关系级联策略

| 关系 | 级联策略 | 理由 |
|---|---|---|
| DecisionScene → CardPool | `.cascade` | 场景删除则其下卡池全删 |
| CardPool → Card | `.nullify` | 卡池删除，卡片归入「未分类」 |
| Card → DrawRecord | `.nullify` | 历史是用户的「回忆」，不应随卡片删除 |
| Card → CardSnapshot | `.cascade` | 快照冗余存储，随主卡删 |
| DrawRecord.action 字段 | DrawRecord 内嵌 enum | 动作是记录的一部分（已合并到 DrawRecord，无需独立实体） |
| DrawRule → DrawRecord | `.nullify` | 规则删除不影响已产生的记录 |
| Card → Favorite | `.cascade` | 收藏随卡片删除 |

### 10.4 索引策略

```swift
// Card 必须建索引的字段
@Attribute(.spotlight) var title: String        // Spotlight 搜索
#Index<Card>([\.sceneID, \.poolID])             // 卡池查询
#Index<Card>([\.isHidden])                      // 过滤不喜欢

// DrawRecord 必须建索引的字段
#Index<DrawRecord>([\.createdAt])               // 时间排序
#Index<DrawRecord>([\.cardID, \.createdAt])     // 单卡历史查询
```

### 10.5 Schema 版本与迁移

```swift
enum SchemaVersion: Int, CaseIterable {
    case v1_0 = 1
    case v1_1 = 2  // 加 nutritionFacts
    case v1_2 = 3  // 加 tagIDs + DecisionJournalEntry
}

static let modelsForSchema: [any PersistentModel.Type] = {
    switch SchemaVersion.current {
    case .v1_0: return [DecisionScene.self, CardPool.self, Card.self, DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self]
    case .v1_1: return [/* + nutritionFacts */]
    case .v1_2: return [/* + DecisionJournalEntry, CardSnapshot, Routine, RoutineStep */]
    }
}()
```

迁移策略：
- **v1.x 小版本**：用 `@Attribute(.transformable)` + 懒加载
- **v1 → v2 大版本**：写 `VersionedSchema` + `SchemaMigrationPlan`
- **每次启动自动导出全量 JSON 到 `Documents/backup.json`**（SwiftData 损坏兜底）

### 10.6 数据生命周期

| 数据类型 | 保留策略 | 用户可主动操作 |
|---|---|---|
| 抽签记录 DrawRecord | 最近 1000 条滚动（D020） | 一键清空 |
| 拒绝记录（excludeUntil） | 4h 到期即重置 | 不需要 |
| 收藏 Favorite | 永久 | 取消 / 加备注 |
| 用户自定义卡 Card | 永久 | 删除 / 编辑 |
| 用户自定义卡池 CardPool | 永久 | 删除 / 编辑 |
| DecisionJournalEntry（v1.1） | 永久 | 一键导出 / 清空 |
| iCloud 同步（v1.1） | 永久（CloudKit Private DB） | 关闭同步 |

---


---

## 11. 非功能性需求

### 11.1 性能预算

| 指标 | 目标 | 测试方法 |
|---|---|---|
| 冷启动到首 Tab | < 1.5s（P95） | iPhone 12 / iOS 17 基线 |
| 抽签响应 | < 1.2s（P95） | Instruments Time Profiler |
| 列表滚动 | 60 FPS | LazyVStack + diffable |
| 内存峰值 | < 150 MB | 全卡池加载 |
| 安装包 | < 50 MB（v1）/ < 100 MB（v1.1+ 含图库） | App Store Connect |
| 搜索响应 | < 200ms | 含 spotlight 索引 |

### 11.2 暗色模式

**策略**：所有色值通过 Asset Catalog Color Set 定义，自动跟随系统。

```swift
extension Color {
    static let bgPrimary = Color("bgPrimary")    // 米白 / 深灰
    static let bgElevated = Color("bgElevated")  // 奶油 / 炭灰
    static let textPrimary = Color("textPrimary") // 深咖 / 米白
    static let accent = Color("accent")           // 暖橘 / 暖金
}
```

验收：
- [ ] 所有界面在浅色 / 深色下对比度 ≥ 4.5:1（WCAG AA）
- [ ] 用户切系统主题时 App 实时跟随
- [ ] 用户在设置里强制选「浅色」则忽略系统

### 11.3 无障碍设计

| 维度 | 实现 |
|---|---|
| VoiceOver | 所有交互按钮加 `.accessibilityLabel`；emoji 加 `.accessibilityHidden(true)`（避免读「猪脸」） |
| Dynamic Type | 用 `.font(.theme.body)` 而非 `.font(.system(size: 14))`；支持 xxxLarge |
| Reduce Motion | 抽签动画 + 庆祝动画检测 `accessibilityReduceMotion` → 跳过或简化 |
| 对比度 | 所有文字 / 背景对比度 ≥ 4.5:1 |
| 触控目标 | 所有可点元素 ≥ 44×44pt |
| 屏幕朗读 | 关键操作（抽签/收藏/完成）有清晰朗读标签 |

### 11.4 隐私政策 / 法务合规

#### 11.4.1 Privacy Manifest（iOS 17+ 强制）

必须创建 `PrivacyInfo.xcprivacy`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>  <!-- App functionality -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

#### 11.4.2 隐私政策 URL

即使零数据收集，App Store 也要求挂一个 URL（GitHub Pages 即可）。

> 简版隐私政策草案（核心是「我们不收集任何数据」）→ `docs/privacy-policy.md`（待补）

#### 11.4.3 过敏免责声明

启动时（启动引导后）增加勾选页：

> 「想啥 App 会基于你填写的过敏原信息做硬屏过滤，但**最终饮食决策由你本人负责**。如有严重过敏史请咨询医生。」

#### 11.4.4 年龄分级 / 内容审核

- **年龄分级**：4+（无 UGC / 无成人内容）
- **内容审核**：v2 开放 UGC 后需关键词过滤 + 人工抽检

#### 11.4.5 姿势图版权

v1 emoji 无版权问题；v1.1 线稿图必须用自绘 / CC0 / 商业授权；v1.2+ 真人图必须有合法授权。

### 11.5 国际化策略

| 维度 | 策略 |
|---|---|
| 主语言 | zh-CN / en-US 双语 |
| 字符串 | String Catalogs（Xcode 15+） |
| 复数 | 中文无复数；英文用 `.stringsdict`（`Text("^[\(count) item](inflect: true)")`） |
| 性别 / 称谓 | 英文 "friend" / "buddy"；中文「你」中性 |
| 字体 | 中文「苹方」/ 英文「SF Pro」；阿拉伯文 RTL 布局（v2） |
| 时区 | `Calendar.current.startOfDay`；24h / 12h 制自动跟随系统 |
| 货币 | `Decimal` + locale 格式化（不写「¥9.9」） |
| Emoji 渲染 | 测试覆盖 iOS 17 / 18 / iPadOS |

### 11.6 CI/CD 与发布流程

```yaml
# .github/workflows/ci.yml（建议结构）
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app
      - name: Build
        run: xcodebuild -scheme xiangsha -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' build
      - name: Unit Tests
        run: xcodebuild test -scheme xiangsha -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
      - name: UI Snapshot Tests
        run: xcodebuild test -scheme xiangsha -only-testing:Snapshots
      - name: SwiftLint
        run: swiftlint lint --strict
```

**TestFlight 内部测试**：v1.0 M6 应提前开 TestFlight，收集 20-50 个真实用户反馈。

**App Store 上架检查清单**：

- [ ] Privacy Manifest（`PrivacyInfo.xcprivacy`）
- [ ] 隐私政策 URL（GitHub Pages）
- [ ] App Icon（1024×1024 全套）
- [ ] 截图（6.7" / 6.1" / 5.5" / iPad 各 5 张）
- [ ] 关键词（100 字符上限）
- [ ] 描述（中英）
- [ ] 分类 / 年龄分级
- [ ] 出口合规信息（`ITSAppUsesNonExemptEncryption=NO`）
- [ ] 过敏免责声明勾选
- [ ] 测试报告（TestFlight ≥ 20 用户 / 7 天）

---


### 11.7 监控与埋点（v1 必接 MetricKit）

**11.7.1 Crash 监控**
- 工具：Apple MetricKit（零依赖、零隐私问题）
- 数据来源：App Store Connect → Analytics → Crashes
- 阈值：崩溃率 > 1% 触发告警（开发邮箱 + 飞书群机器人）

**11.7.2 关键路径埋点**

| 事件 | 维度 | 优先级 |
|---|---|---|
| 抽签成功 | scene + factors + elapsedMs | P0 |
| 抽签失败（兜底） | scene + fallbackLevel | P0 |
| 收藏 | scene + isNewFavorite | P1 |
| 分享 | scene + channel | P1 |
| 任务完成 | taskType + elapsedMin | P1 |
| emoji 评分 | score + scene | P1 |
| 不决策模式 | trigger | P2 |

**11.7.3 性能监控**
- 工具：MetricKit + Xcode Organizer
- 关键指标：抽签响应 P95 / P99、ModelContainer 启动耗时、滚动帧率
- 阈值：抽签 P99 > 3s 触发告警

**11.7.4 告警通道**
- 邮件 + 飞书群机器人 webhook
- 告警分级：
  | 级别 | 触发条件 | 响应 SLA |
  |---|---|---|
  | 🔴 P0 | 崩溃率 > 1% / 启动崩溃 | 2h |
  | 🟠 P1 | 抽签失败率 > 5% / 数据迁移失败 | 4h |
  | 🟡 P2 | 性能 P99 超阈值 | 24h |

### 11.8 用户反馈与投诉响应

**11.8.1 反馈渠道**
| 渠道 | SLA | 责任人 |
|---|---|---|
| App Store 评论 | 每周回复一次 | 运营 |
| 反馈邮件（feedback@想啥.app）| 48h 内响应 | 客服 |
| 设置 → 关于 → 反馈 | 同上 | 客服 |
| GitHub Issues（公开反馈）| 72h 内响应 | 开发 |

**11.8.2 紧急问题响应**
| 类型 | 响应 SLA | 处理流程 |
|---|---|---|
| 过敏 / 医疗相关 | 2h 内响应 | 法务 + 产品双线跟进 |
| 数据丢失 | 4h 内响应 | 立即备份 + 提供 backup.json 恢复方案 |
| 一般 bug | 48h 内响应 | GitHub Issue + 排期修复 |
| 体验问题 | 1 周内响应 | 收集到反馈表 |

**11.8.3 数据删除请求（GDPR / CCPA）**
- 用户邮件请求 → 7 天内删除
- 流程：导出 Markdown 给用户（保留 30 天）→ 用户确认 → 删除所有 SwiftData + iCloud 同步数据
- 留痕：删除时间 + 用户 ID + 操作人 + 备份链接

### 11.9 App 体积优化策略

**11.9.1 v1 体积预算**

| 项 | 预算 | 措施 |
|---|---|---|
| 编译产物 | < 20 MB | SwiftUI + SwiftData 编译优化 |
| JSON 资源（5 模块卡池） | < 3 MB | Gzip 压缩 + Bundle 分包 |
| AppIcon 全套 | < 2 MB | 1024×1024 PNG |
| 字体 | 0 MB（系统）| — |
| emoji | 0 MB（系统）| — |
| v1 总计 | < 30 MB | < 50 MB 预算（留 20MB 余量） |

**11.9.2 v1.1+ 扩展预算**

| 项 | 预算 | 措施 |
|---|---|---|
| 姿势线稿图（80 张）| < 5 MB | 矢量 PDF（每个 30KB）|
| 姿势高清图（v1.2，50-100 张）| < 20 MB | HEIC 200KB/张 |
| AI 模型（v1.2 Foundation Models）| < 1 GB | 首次启动按需下载 |
| v1.2 总计 | < 100 MB | App Store Thinning 优化 |

**11.9.3 优化手段**
- App Thinning：iOS 自动按设备分发资源
- Asset Catalog：所有图片走 Asset Catalog（自动压缩）
- Lazy Loading：决策日记 / 周报模块按需加载
- On-Demand Resources（ODR）：v1.1 姿势图库按需下载

### 11.10 A/B 测试框架（v1.1+ 起步 · v1 占位）

**11.10.1 v1 占位**
- 所有「实验性功能」（决策反向解释 / 声景设计 / 不决策模式）通过 `FeatureFlag` 开关
- `FeatureFlag.experimentXXXXX: Bool = false` 默认关闭
- 调试模式下可手动开启单个实验

**11.10.2 v1.1 框架**
- 配置中心：Firebase Remote Config（v1.1 评估）或自建 Lightweight Config
- 用户分桶：按 `userID.hashValue % 100` 分桶（A/B 各 50%）
- 关键指标：抽签接受率 / D7 留存 / 收藏率 / 分享率 / 完成率
- 灰度策略：TestFlight 灰度 → 1% → 10% → 50% → 100%
- 回滚：关键指标恶化 > 10% 自动回滚

### 11.11 ASO 关键词策略

**11.11.1 主关键词（100 字符上限）**
- `决策,抽签,吃什么,喝什么,拖延症,拍照姿势,周末,选择困难,治愈,小狐狸`

**11.11.2 长尾关键词（标题/副标题覆盖）**
- 主标题：「想啥 - 拿不定主意的小狐狸」
- 副标题：「吃啥·玩啥·做啥·拍啥·一签搞定」
- 覆盖查询：「周末玩什么」「吃什么外卖」「拍照怎么摆pose」「做什么菜」「选择困难症」

**11.11.3 标题 A/B 测试**
- A 版：「想啥 - 拿不定主意时的好帮手」
- B 版：「想啥 - 治愈系抽签 App」
- 评估指标：下载转化率（点击→安装）

**11.11.4 评分引导**
- 触发时机：成就解锁时（D097）+ 用户主动反馈（D135 emoji 评分）
- 频率限制：每版本最多 3 次 / 每年最多 8 次（避免 Apple 警告）
- 跳过条件：用户拒绝过 → 30 天内不再弹

### 11.12 数据可视化规范（D021 展开）

| 图表 | 尺寸 | 配色 | 字体 | 交互 |
|---|---|---|---|---|
| 饼图（场景分布）| 240×240pt | 暖色 5 档 + emoji 区分 | SF Pro Rounded 14pt | 点击扇区显示明细 |
| 折线图（周分布）| 全宽 × 200pt | 主色（暖橘） + 浅色背景 | SF Pro 12pt 轴标 | 长按显示 tooltip |
| 数字卡 | 单行 28pt | 主色 | SF Pro Bold | 无 |
| 进度条 | 200×8pt | 主色（暖橘） + 灰底 | — | 无 |

图表库：SwiftUI Charts（iOS 17+ 原生，不引入第三方）。

### 11.13 App Store 截图视觉规范

**11.13.1 截图规格**

| 设备 | 尺寸 | 必填 |
|---|---|---|
| iPhone 6.7" | 1290×2796 | ✅ 主截图 |
| iPhone 6.1" | 1179×2556 | ✅ |
| iPhone 5.5" | 1242×2208 | 🟡 选填 |
| iPad 12.9" | 2048×2732 | 🟡 iPad 支持时必填 |

**11.13.2 视觉规范**
- 主色：米咖奶油色系（`#F5E6D3` 背景 + `#8B4513` 文字）
- 字体：中文「苹方」+ 英文「SF Pro Rounded」
- 必备元素：小狐狸 🦊 IP + Tab 名称 + 一句话价值主张

**11.13.3 5 张主截图内容**
1. 吃啥主屏（牌面翻面瞬间）
2. 玩啥主屏（点子库）
3. 做啥 - 做菜模式（步骤 + 计时器）
4. 拍啥（姿势引导气泡）
5. 决策日记（v1.1）

### 11.14 Widget / Spotlight / Siri 被动留存设计（v1.1+）

**v1 不接任何被动系统集成**（保持反焦虑）。

| 系统集成 | 触发 | v1.1 用户感知 | v1.1 实现 |
|---|---|---|---|
| **主屏 Widget** | 用户主动添加 | 「今日三签」卡片，点开直接抽 | WidgetKit + App Intents |
| **锁屏 Widget** | 用户主动添加 | 「今日还剩 X 次」+ 小狐狸 | WidgetKit accessoryRectangular |
| **Spotlight 索引** | 用户在主屏搜索「吃啥」 | 看到 App + 最近抽签结果 | CoreSpotlight + NSUserActivity |
| **Siri 快捷指令** | 「嘿 Siri，帮我决定吃啥」 | 直接打开抽签页 | App Intents（iOS 16+）|
| **App Intents（iOS 16+）** | 其他 App 调用 | 决定 App 可作为「决策装置」 | AppShortcutsProvider |

**关键原则**：所有集成**用户显式启用**，v1.1 默认关闭，符合「不打扰」原则。

### 11.15 iPad / Mac Catalyst / App Tracking Transparency

**11.15.1 iPad 支持（v1 即支持）**
- Info.plist：`UIRequiresFullScreen = NO`（支持多任务分屏）
- 布局：Tab 顶部用 NavigationSplitView（iPad 横屏显示侧边栏）
- 键盘：Tab 切换支持 ⌘1-⌘4 快捷键
- Apple Pencil：无特定支持

**11.15.2 Mac Catalyst（v1.1 评估）**
- v1 上架时禁用在 Mac 上销售：`LSApplicationCategoryType` + `UIRequiredDeviceCapabilities`
- v1.1 评估是否启用（App Store 自动上架 Mac）

**11.15.3 App Tracking Transparency（ATT）**
- 本项目零追踪：
  ```xml
  <key>NSPrivacyTracking</key>
  <false/>
  ```
- 不调用 IDFA / SKAdNetwork
- 不弹「允许追踪」系统弹窗
- PrivacyInfo.xcprivacy 已声明（D113 等同）

**11.15.4 Sign in with Apple**
- 本项目零账号，**不集成**
- App Store Connect → App 隐私 → 「不提供 Sign in with Apple」



---

## 14. 数据生命周期（新增）

### 14.1 删除策略

| 关系 | 策略 |
|---|---|
| DecisionScene 删除 → CardPool | cascade |
| CardPool 删除 → Card | nullify（卡片归入「未分类」） |
| Card 删除 → DrawRecord | nullify（保留历史但 cardSnapshot 兜底） |
| Card 删除 → CardSnapshot | nullify（保留日记） |
| Card 删除 → Favorite | cascade |
| DecisionJournalEntry 删除 | 永久删除（用户主动操作） |

### 14.2 Schema 版本

- v1.0 → v1.1 加字段：用 `@Attribute(.transformable)` + 懒加载
- v1.x → v2.0 大版本：写 `VersionedSchema` + `SchemaMigrationPlan`

### 14.3 导入去重 key

- Card：`{sceneRawValue}:{title}:{emoji}` 三元组
- DrawRecord：`{id}` 单字段
- CardSnapshot：`{id}@{createdAt}` 二元组
- Favorite：`{cardID}` 单字段

### 14.4 历史滚动

- DrawRecord：按 `createdAt` 升序，> 1000 条删除最旧
- DecisionJournalEntry：永久保留（用户主动管理）
- UserTaskRecord：按 `createdAt` 升序，> 1000 条删除最旧

### 14.5 自动备份

每次启动自动导出全量 JSON 到 `Documents/backup.json`，作为 SwiftData 损坏的最后兜底（D093）。

---


---

## 附录 A · 抽签引擎权重参数表

> **来源**：一号评审员 B.2 / 三号评审员 3.3 整合

### A.1 引擎架构

```swift
// MARK: - 核心类型
struct DrawContext {
    let pool: CardPool
    let user: UserProfile
    let now: Date
    let timeOfDay: TimeOfDay
    let mode: DrawMode
}

struct DrawResult {
    let card: Card
    let candidatesBeforeFilter: Int
    let candidatesAfterFilter: Int
    let appliedFactors: [FactorApplication]
    let fallbackUsed: Bool
    let fallbackLevel: FallbackLevel?
}

protocol DrawEngine {
    func draw(context: DrawContext) async throws -> DrawResult
}

struct RuleBasedEngine: DrawEngine {
    let config: DrawEngineConfig
    // ... 多维平衡实现
}
```

### A.2 硬屏参数表

| 因子 | 公式 | 默认值 | 可调范围 | 备注 |
|---|---|---|---|---|
| **过敏硬屏** | `card.allergens ∩ user.allergens == ∅` | 必须通过 | — | 候选=0 时降级为「警告」 |
| **单卡冷却** | `now >= card.excludeUntil` | 4h | v1 不可调 | 4h 后立即恢复 |
| **类别硬上限** | `count24h(category) < 2` | 2 次/24h | [1, 3] | 接近上限（=1）时 × 0.7 |
| **品牌硬上限** | `count7d(brand) < 1` | 1 次/7d | — | 「我就要这个」可破 |
| **主料去重** | `count24h(mainIngredient) == 0` | 0 次/24h | — | v1 强制 |
| **慢节奏上限** | `user.drawsToday < 3` | 3 次/天 | v1 不可调 | 跨午夜重置 |

### A.3 软调权参数表

| 因子 | 公式 | 默认乘数 | 范围 | 说明 |
|---|---|---|---|---|
| **餐次平衡** | 见 A.4 | 0.5 ~ 1.5 | — | 仅午餐/晚餐生效 |
| **风格轮换** | 见 A.5 | 0.7 ~ 1.5 | — | 长期偏好 + 临时 override |
| **收藏加权** | `card.isFavorite ? min(1.2, 1.0 + 0.2/log(count+1)) : 1.0` | × 1.2 | 1.0 ~ 1.2 | 防收藏卡垄断 |
| **新卡优先** | `now - card.createdAt < 7d ? 1.3 : 1.0` | × 1.3 | 1.0 ~ 1.3 | 鼓励尝鲜 |
| **时段因子** | `card.pool == defaultPool(timeOfDay) ? 1.0 : 0.5` | × 1.0 / 0.5 | — | 当前时段卡池优先 |
| **历史降权** | `pow(0.5, historyCount[card.id])` | × 0.5^n | 0.03125 ~ 1.0 | n = 24h 内被抽次数 |

### A.4 餐次平衡公式

```swift
func mealTimeFactor(card: Card, context: DrawContext) -> Double {
    guard [.lunch, .dinner].contains(context.timeOfDay) else { return 1.0 }
    guard let lastMeal = context.user.lastMealOfToday else { return 1.0 }

    switch (lastMeal.category, card.category) {
    case (.staple, .staple):  return 0.5
    case (.staple, .dish):    return 1.2
    case (.staple, .soup):    return 1.5
    case (.dish, .staple):    return 1.0
    case (.dish, .dish):      return 0.8
    case (.dish, .soup):      return 1.3
    case (.soup, .staple):    return 1.2
    case (.soup, .dish):      return 1.0
    case (.soup, .soup):      return 0.5
    default:                  return 1.0
    }
}
```

### A.5 风格轮换公式

```swift
func styleFactor(card: Card, context: DrawContext) -> Double {
    let recentStyles = context.user.recentStyles7d
    let userPreferredStyles = context.user.preferredStyles

    if userPreferredStyles.contains(card.style) && !recentStyles.contains(card.style) {
        return 1.5
    }
    if recentStyles.contains(card.style) {
        return 0.7
    }
    return 1.0
}
```

### A.6 加权抽样算法

```swift
func weightedSampling(_ items: [(Card, Double)]) -> Card? {
    let total = items.map(\.1).reduce(0, +)
    guard total > 0 else { return items.randomElement()?.0 }

    var pick = Double.random(in: 0..<total)
    for (card, weight) in items.sorted(by: { $0.1 > $1.1 }) {
        pick -= weight
        if pick <= 0 { return card }
    }
    return items.last?.0
}
```

### A.7 兜底策略

| 兜底等级 | 触发 | UI |
|---|---|---|
| **L1：完全候选为 0** | 硬屏全排除 | 顶部 Banner「歇够了？加点新内容吧」+ 加卡按钮 |
| **L2：仅警告级** | 过敏命中 | 「⚠️ 含过敏原 [花生]，确认接受？」+ 接受/重摇 |
| **L3：忽略冷却** | 候选 ≥ 1 但全部冷却 | Toast「这是 X 小时前抽过的哦」+ 强制展示 |

### A.8 调参接口

```swift
struct DrawEngineConfig {
    var singleCooldown: TimeInterval = 4 * 3600
    var categoryMaxPer24h: Int = 2
    var brandMaxPer7d: Int = 1
    var mainIngredientMaxPer24h: Int = 0
    var favoriteBoost: Double = 1.2
    var newCardBoost: Double = 1.3
    var newCardWindowDays: Int = 7
    var historyDecayBase: Double = 0.5
    var mealBalanceEnabled: Bool = true
    var styleRotationEnabled: Bool = true
    var drawsPerDayLimit: Int = 3
}
```

### A.9 单元测试矩阵

| # | 用例 | 输入 | 期望 | 因子覆盖 |
|---|---|---|---|---|
| T01 | 过敏硬屏 | 花生过敏 + 含花生候选 | 花生排除 | allergenHardBlock |
| T02 | 单卡冷却 | 4h 内抽过 | 该卡排除 | singleCardCooldown |
| T03 | 品牌冷却 | 品牌 7d 内 1 次 | 该品牌候选排除 | brandCooldown |
| T04 | 类别冷却 | 类别 24h 内 2 次 | 该类别候选排除 | categoryCooldown |
| T05 | 主料去重 | 主料 24h 内 1 次 | 该主料候选排除 | mainIngredientRepeat |
| T06 | 餐次平衡 | 上一餐=主粮 + 午餐 | 主食 × 0.5 | mealTimeFactor |
| T07 | 风格轮换 | 偏好粤菜 + 7d 未吃 | 粤菜 × 1.5 | styleFactor |
| T08 | 收藏加权 | 收藏 1 张 | × 1.2 | favoriteBoost |
| T09 | 新卡优先 | 1 天前新增 | × 1.3 | newCardBoost |
| T10 | 历史降权 | 抽中 3 次 | × 0.125 | historyDecay |
| T11 | 兜底 L1 | 所有硬屏排除 | 返回空 + Banner | fallback |
| T12 | 兜底 L2 | 仅警告级 | 返回警告 + 确认 | fallback.warning |
| T13 | 性能 | 1000 候选 + 全软因子 | < 50ms | performance |
| T14 | 抽样正确性 | 10000 次蒙特卡洛 | 分布与权重一致 | sampling |
| T15 | 慢节奏上限 | 今日已抽 3 次 | 按钮 disable | drawsPerDayLimit |

---


---

## 附录 C · 单元测试用例集

> **来源**：三号评审员 3.3 + 一号评审员 B.6 整合。覆盖抽签引擎、用户旅程、数据迁移三类。

### C.1 抽签引擎测试（继承自附录 A.9）

- T01-T15（见附录 A.9）

### C.2 用户旅程测试

| # | 场景 | 验证 |
|---|---|---|
| U01 | 新用户首次启动 | 走完 3 屏引导 + 过敏原设置 |
| U02 | 首次进入吃啥 | 自动按当前时段选卡池 |
| U03 | 首次抽签 | 走硬屏过滤 + 软调权 + 加权抽样 |
| U04 | 用户点换一签 5 次 | 触发 Top 3 兜底（v1.1） |
| U05 | 用户一天抽 4 次 | 第 4 次按钮 disable + Toast |
| U06 | 用户删自定义卡 | 候选池立即移除 |
| U07 | 用户长按标记不喜欢 | 该卡从候选池永久移除 |
| U08 | 用户导出 JSON | 生成符合规范的 JSON |
| U09 | 用户导入 JSON | 校验格式 + 冲突提示 |
| U10 | 用户清空历史 | 二次确认 + 真实删除 |

### C.3 数据迁移测试

| # | 场景 | 验证 |
|---|---|---|
| M01 | v1.0 → v1.1 升级 | nutritionFacts 字段懒加载 |
| M02 | v1.x → v2.0 升级 | VersionedSchema + MigrationPlan |
| M03 | SwiftData 损坏 | 自动恢复到 backup.json |
| M04 | 导入跨版本 JSON | 字段缺失时填默认值 |
| M05 | 大量历史数据（>10000 条） | 滚动删除到 1000 条 |

### C.4 UI 快照测试

- 4 Tab 主屏（浅色 / 深色）
- 抽签结果页（5 种 fallback）
- 启动引导 3 屏
- 设置 4 个分组
- 启动引导可重看

### C.5 无障碍测试

- VoiceOver 全流程
- Dynamic Type xxxLarge
- Reduce Motion 启用
- 高对比度模式

---
