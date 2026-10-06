# xiangsha 单元测试

## 状态

**当前未配置 Test Target**。本目录的 `.swift` 文件**不会**被自动编译或运行。

## 接入步骤（Xcode UI）

1. 用 Xcode 打开 `xiangsha.xcodeproj`
2. 菜单 **File → New → Target...**
3. 选择 **Unit Testing Bundle**（不是 UI Testing Bundle）
4. Product Name: `xiangshaTests`
5. Language: **Swift**
6. Bundle ID: `Claude.lwb.xiangshaTests`（与主 app 区分）
7. Finish
8. 在 Xcode 文件导航中**删除**自动生成的 `xiangshaTests.swift`
9. **拖入整个 `Tests/UnitTests/` 目录**到 `xiangshaTests` target（包含 Support/）
10. 选择 scheme **xiangsha**（不是 xiangshaTests） → **Product → Test**（`Cmd + U`）

## 验证

```bash
xcodebuild test \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

应输出：
```
Test Suite 'DrawEngineTests' passed
Test Suite 'EatViewModelTests' passed
Test Suite 'PlayViewModelTests' passed
Test Suite 'DoViewModelTests' passed
Test Suite 'PhotoViewModelTests' passed
```

## 测试夹具结构

```
Tests/UnitTests/
├── DrawEngineTests.swift         # 含私有 TestFixtures（makeCard / makeDrawContext）
├── Support/
│   └── TestFixturesVM.swift      # VM 层夹具（makeModelContext / makeSeededContext）
├── EatViewModelTests.swift       # 模块 A · 吃啥 VM
├── PlayViewModelTests.swift      # 模块 B · 玩啥 VM
├── DoViewModelTests.swift        # 模块 C · 做啥 VM
├── PhotoViewModelTests.swift     # 模块 D · 拍啥 VM
└── README.md
```

### 夹具职责分工

| 文件 | 暴露 API | 适用 |
|---|---|---|
| `DrawEngineTests` 末尾私有 `TestFixtures` | `makeCard` / `makeDrawContext` | 抽签引擎单元测试（Sendable，无需 ModelContext） |
| `Support/TestFixturesVM` | `makeModelContext` / `makeSeededContext` / `makeScene` / `makePool` / `makeUserProfileSnapshot` | VM 单元测试（@MainActor + SwiftData 读写） |

> **拆分原因**：DrawEngine 是 `Sendable` + 无 SwiftData 依赖，VM 是 `@MainActor` + 直接读写 SwiftData。两个测试层级的 fixture 诉求不同，合并反而难维护。

## 覆盖范围

### DrawEngine（SPEC §A.9 · T01-T15）

| # | 用例 | 状态 |
|---|---|---|
| T01 | 过敏硬屏 | ✅ |
| T02 | 单卡冷却 | ✅ |
| T03 | 品牌冷却 | ✅ |
| T04 | 类别冷却 | ✅ |
| T05 | 主料去重 | ✅ |
| T06 | 餐次平衡 | ✅ |
| T07 | 风格轮换 | ✅ |
| T08 | 收藏加权 | ✅ |
| T09 | 新卡优先 | ✅ |
| T10 | 历史降权（D005）| ✅ |
| T11 | L1 兜底 | ✅ |
| T12 | L2 兜底 | 🔲（需 L2 路径触发，v1 暂跳） |
| T13 | 性能（1000 候选）| ✅ |
| T14 | 抽样正确性（蒙特卡洛）| ✅ |
| T15 | 慢节奏上限 | ✅ |

### ViewModel（v1 smoke test）

| 模块 | 用例 | 状态 |
|---|---|---|
| **A 吃啥** | T-VM-A01 init / A02 loadInitialData / A03 draw 空 pool / A04 accept / A05 dislike | ✅（A02-A05 现可实跑） |
| **B 玩啥** | T-VM-B01 init / B02 loadInitialData / B03 draw 空 pool / B04 rate / B05 场景隔离 | ✅ |
| **C 做啥** | T-VM-C01 init / C02 loadInitialData / C03 draw 空 pool / C04 庆祝 / C05 已完成任务 | ✅ |
| **D 拍啥** | T-VM-D01 init / D02 loadInitialData / D03 draw 空 pool / D04 createUser / D05 rate / D06 PhotoCaptureService 工厂 | ✅ |

> **2026-10-06 更新**：4 个 VM 测试文件从 XCTSkip 升级为**可实跑**（依赖 `TestFixturesVM.makeModelContext()` / `makeSeededContext()`）。Test Target 一经配置即可运行。

## 关联决策

- SPEC §A.9 测试矩阵
- 02-AGENTS §A.5 测试约定
- ROOT_AGENTS.md §10 单元测试
- ROADMAP G.1.1 当前真实 P0（P0-3 测试覆盖）
