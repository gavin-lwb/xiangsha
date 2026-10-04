# 「想啥」Agent Collaboration Guide (AGENTS)

> **代号**：想啥（产品名，主）/ Pick Now（英文副名）/ xiangsha（工程名 · Xcode scheme）
> **平台**：iOS 17+（Xcode / SwiftUI / SwiftData）
> **来源**：拆分自 `DEVELOPMENT.md` v1.3（2026-10-04）
> **范围**：命名规范 / 目录结构 / 模块边界 / 开发节奏 / 协作流程
**新建时间**：2026-10-04（v1.3 拆分自 DEVELOPMENT.md）

---


## A.1 命名规范

| 类型 | 规范 | 示例 |
|---|---|---|
| **工程名（Xcode scheme）** | `xiangsha` | `xiangsha.xcodeproj` |
| **产品名（App Store）** | `想啥`（zh-CN）/ `Pick Now`（en-US）| — |
| **Swift 类型** | PascalCase | `DrawEngine`, `Card`, `RecipeTaskRunner` |
| **View** | `*View` 后缀 | `HomeView`, `DrawResultView` |
| **ViewModel** | `*ViewModel` 后缀 | `DrawViewModel`, `TaskViewModel` |
| **Service** | `*Service` 后缀 | `DrawService`, `PersistenceService` |
| **Protocol** | 名词或形容词 | `DrawEngine`, `TaskRunner` |
| **方法 / 函数** | camelCase，动词开头 | `drawCard()`, `resetDrawCount()` |
| **常量** | camelCase + `let` | `let maxDrawsPerDay = 3` |
| **枚举 case** | camelCase | `.accept`, `.reject`, `.skip` |
| **资源 / Bundle** | kebab-case | `card-data-eat.json` |

## A.2 目录结构

```
xiangsha/
├── App/                          # App 入口 + 顶层
│   ├── xiangshaApp.swift          # @main 入口 + ModelContainer（D133）
│   └── ContentView.swift         # 4 Tab 主容器
├── Core/                         # 通用基础设施
│   ├── Models/                   # SwiftData @Model
│   │   ├── DecisionScene.swift
│   │   ├── CardPool.swift
│   │   ├── Card.swift
│   │   ├── DrawRecord.swift
│   │   ├── UserProfile.swift
│   │   ├── Favorite.swift
│   │   └── UserTaskRecord.swift
│   ├── Services/                 # 业务服务
│   │   ├── DrawEngine.swift      # 抽签引擎协议
│   │   ├── RuleBasedEngine.swift # 多维平衡实现
│   │   ├── PersistenceService.swift
│   │   └── FeedbackService.swift # D135 emoji 评分
│   └── Utils/
│       ├── AppEnvironment.swift  # D099 DEBUG 围栏
│       └── Logger.swift
├── Modules/                      # 4 个功能模块
│   ├── Eat/                      # 模块 A 吃啥
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Data/                 # eat-cards.json
│   │   └── Components/
│   ├── Play/                     # 模块 B 玩啥 · 点子库（v1.3）
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Data/                 # play-cards.json
│   │   └── Components/
│   ├── Do/                       # 模块 C 做啥
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Tasks/                # 关键词模板 + 微任务 + 急救
│   │   ├── Runner/               # GenericTaskRunner
│   │   └── Components/
│   └── Photo/                    # 模块 D 拍啥
│       ├── Views/
│       ├── ViewModels/
│       ├── Data/                 # photo-cards.json
│       └── Components/
├── Shared/                       # 跨模块共享
│   ├── Components/               # CardView / ButtonStyle / EmptyStateView
│   ├── DesignSystem/             # Color+Theme / Font+Theme
│   ├── Onboarding/               # 启动引导 3 屏
│   ├── Settings/                 # 4 类分组
│   └── Journal/                  # 决策日记（v1.1）
├── Resources/                    # 资源
│   ├── PrivacyInfo.xcprivacy     # D113 Privacy Manifest
│   ├── privacy-policy.md         # D103 隐私政策
│   └── Assets.xcassets/
├── docs/                         # 工程文档（本目录）
│   ├── 00-PRD.md
│   ├── 01-SPEC.md
│   ├── 02-AGENTS.md              # 本文件
│   ├── 03-ROADMAP.md
│   └── 99-CHANGELOG.md
└── Tests/
    ├── UnitTests/                # 抽签引擎 + ViewModel + Service
    └── SnapshotTests/            # UI 快照
```

## A.3 模块边界

| 模块 | 职责 | 不应包含 |
|---|---|---|
| **App** | 应用启动、ModelContainer、4 Tab 容器 | 业务逻辑 |
| **Core** | 通用数据模型、服务、工具 | UI |
| **Modules/Eat** | 吃啥相关 View / ViewModel / 数据 | 玩啥/做啥/拍啥逻辑 |
| **Modules/Play** | 玩啥（点子库）相关 | 吃啥/做啥/拍啥逻辑 |
| **Modules/Do** | 做啥 + 任务执行器 | 吃啥/玩啥/拍啥逻辑 |
| **Modules/Photo** | 拍啥相关 | 吃啥/玩啥/做啥逻辑 |
| **Shared** | 跨模块通用组件 | 任何模块专属逻辑 |

**模块间通信**：
- 通过 `DrawEngine` Protocol（附录 A.1）调用抽签引擎
- 通过 `JournalService.shared` 写入决策日记（v1.1）
- 通过 SwiftData `@Query` 跨模块读取（仅读，不写）
- **禁止**：模块 A 直接 import 模块 B 内部类型

## A.4 开发节奏与优先级

### 优先级分级

| 优先级 | 定义 | 处理 SLA |
|---|---|---|
| **P0** | 阻塞上架 / 数据丢失 / 法务风险 | 当天修 |
| **P1** | 影响核心功能 / 用户感知明显的 bug | 1 周内 |
| **P2** | 体验优化 / 性能调优 | 排期 |
| **P3** | 创新功能 / v1.1+ 规划 | 路线图 |

### 单次任务流程

1. 从 `03-ROADMAP.md` 找当前里程碑（M0-M7）
2. 创建 branch：`git checkout -b feature/D-NNN-short-desc`
3. 编写代码 + 单测
4. `swift run lint`（如配置）
5. `xcodebuild test`（必须通过）
6. PR + 描述关联的决策号
7. Review → Merge

### Commit 规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

| Type | 说明 |
|---|---|
| `feat` | 新功能（关联 D-NNN） |
| `fix` | Bug 修复 |
| `docs` | 文档变更（仅 docs/ 或根级 .md） |
| `refactor` | 重构（不改变行为） |
| `test` | 测试 |
| `chore` | 构建 / 工具链 |

**示例**：
```
feat(draw-engine): D005 两段衰减公式

- t < 3: weight × 0.5^t
- t ∈ [3, 7): weight × 0.125
- t ≥ 7: weight = 0

关联决策：D005 / D007
Reviewer: @xxx
```

## A.5 提交流程

1. **本地测试**：`xcodebuild test` 必须通过
2. **Lint**：`swiftlint lint --strict`
3. **PR 模板**：
   ```
   ## 关联决策
   - D-NNN: <title>

   ## 变更
   - <list>

   ## 测试
   - [ ] 单元测试已加
   - [ ] UI 快照测试已加（若涉及 UI）
   - [ ] 性能测试已加（若涉及性能）
   ```
4. **Reviewer**：≥ 1 人 review 通过
5. **Merge**：squash and merge

## A.6 与小白（AI 助手）协作

- 跨会话启动：先 `memory_search` + `read` `docs/00-PRD.md` §6 模块 PRD
- 决策变更：必须同步更新 `00-PRD.md` + `99-CHANGELOG.md`
- 写决策：每个决策**必须三段式**（触发场景 / 实现要点 / 验收标准）
- 异议：写到 `03-ROADMAP.md` 附录 D，**不在主文档反驳评审员**

## A.7 反模式（禁止）

| 反模式 | 后果 | 替代 |
|---|---|---|
| 在 View 里直接操作 SwiftData Context | 难以测试 | 用 ViewModel 包装 |
| 跨模块 import 内部类型 | 强耦合 | 通过 Core/Services 协议调用 |
| 硬编码字符串 | i18n 困难 | 用 String Catalogs |
| 在主线程做重操作 | 卡顿 | 异步 + Task |
| 跳过单元测试 | 回归 bug | TDD（抽签引擎 + 评分逻辑必须覆盖）|
| 直接修改 v1 决策而不更新 PRD | 文档失真 | 决策变更流程（见 §A.4）|
