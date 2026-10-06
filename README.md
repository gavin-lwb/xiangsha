# 想啥 · Pick Now

> **「不知道吃啥玩啥做啥拍啥？抽一张就好。」**
> 完全本地化的 iOS 决策辅助 App，4 模块 274 张卡，零数据收集。

| 代号 | 想啥（产品名）· Pick Now（英文副名）· **xiangsha**（Xcode scheme） |
|---|---|
| 平台 | iOS 17+ / iPhone · SwiftUI · SwiftData |
| 工程 | Xcode 15+ · 单 target 单 workspace |
| 状态 | v1.0 内容生产中（M0）· 4 模块脚手架已完成 |
| 隐私 | **零数据收集** · 详见 [隐私政策](https://gavin-lwb.github.io/xiangsha/xiangsha/Resources/privacy-policy.md) |

---

## ✨ 这是什么

一个反"选择困难症"的极简 App。**不知道吃什么**？抽一张；**周末无聊**？抽一张；**不知道做点啥**？抽一张。决策过程 1.2 秒，**所有结果只在你设备上**，App 不知道你是谁，也不知道你抽了什么。

设计原则：**慢决策、轻交互、人格化反馈**。一只叫"小白"的小狐狸全程陪伴，不催促不评价。

---

## 🎴 4 模块

| 模块 | 卡数 | 用途 | v1 状态 |
|---|---|---|---|
| **A 吃啥** | 80 | 早午晚 + 外卖 / 在家做 / 时段过滤 | ✅ 抽签 + 动画 + 池子选择 已就位 |
| **B 玩啥 · 点子库** | 80 | 室内 / 室外 / 单人 / 多人 / 创作 / 学习 | ✅ 抽签 + 池子选择 已就位 |
| **C 做啥** | 60 | 家务 / 运动 / 自我提升 / 社交 / 关怀他人 | ✅ 抽签 + 池子选择 已就位 |
| **D 拍啥 · 姿势** | 54 | 室内 / 室外 / 全身 / 半身 / 道具 | ✅ 抽签 + 拍照占位 + 池子选择 已就位 |
| **合计** | **274** | — | M0 内容生产中（用户终审 + maben 文案润色） |

> 单人估时 3 周（274 × 25 分钟/张），多分身协作可压到 1.5-2 周。
> 详细分工见 [`docs/m0-content-blueprint.md`](xiangsha/docs/m0-content-blueprint.md)。

---

## 🚀 快速开始

### 环境要求
- macOS 14+ · Xcode 15+
- iOS 17+ 真机或模拟器
- 已配置 Apple Developer 账号（运行不需要，发布需要）

### 跑起来
```bash
git clone https://github.com/gavin-lwb/xiangsha.git
cd xiangsha
open xiangsha.xcodeproj
```
Xcode 里选 `xiangsha` scheme → 选模拟器（推荐 iPhone 15）→ **Cmd + R**。

### 跑测试
测试 target 接入步骤见 [`Tests/UnitTests/README.md`](Tests/UnitTests/README.md)。
接入后：
```bash
xcodebuild test \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```
应输出 5 个测试套件全绿：`DrawEngineTests` / `EatViewModelTests` / `PlayViewModelTests` / `DoViewModelTests` / `PhotoViewModelTests`。

---

## 🏗 工程结构

```
xiangsha/
├── xiangsha.xcodeproj/          # Xcode 工程
├── xiangsha/                    # 主代码目录
│   ├── App/
│   │   ├── Core/                # 核心模型 + 服务
│   │   │   ├── Models/          # Card / DecisionScene / DrawRecord / ...
│   │   │   └── Services/        # SeedService / DrawEngine / ...
│   │   ├── Modules/             # 4 个独立模块
│   │   │   ├── Eat/             #   A 吃啥
│   │   │   ├── Play/            #   B 玩啥
│   │   │   ├── Do/              #   C 做啥
│   │   │   └── Photo/           #   D 拍啥
│   │   ├── Shared/              # 跨模块复用（设置/收藏/历史/Onboarding...）
│   │   └── xiangshaApp.swift    # @main 入口
│   ├── Resources/
│   │   ├── PrivacyInfo.xcprivacy
│   │   └── privacy-policy.md    # 隐私政策源文件（已部署到 GitHub Pages）
│   ├── docs/                    # PRD / SPEC / AGENTS / ROADMAP / CHANGELOG
│   └── DEVELOPMENT.md           # 工程文档索引
└── Tests/
    └── UnitTests/               # 单元测试（5 个 VM + DrawEngine）
```

---

## 🛠 技术栈

| 层 | 选型 | 理由 |
|---|---|---|
| UI | SwiftUI | 声明式 + iOS 17 新特性（`@Observable`、`onChange` 改进） |
| 数据 | SwiftData | 原生 + 零依赖 + 自动迁移（D138） |
| 动画 | TimelineView | 解决 SwiftUI `.task` race condition（实测教训） |
| 抽签引擎 | 自研（D005-D014） | 降权 + 冷却 + 并发 + 兜底两级 |
| 测试 | XCTest | 不引第三方 framework |
| 隐私清单 | PrivacyInfo.xcprivacy | 上架合规（D113） |

---

## 🤝 贡献规范

1. **读** [`xiangsha/docs/02-AGENTS.md`](xiangsha/docs/02-AGENTS.md) — 命名 + 目录 + 边界
2. **Fork** → 新建 `feat/xxx` 或 `fix/xxx` 分支
3. **Commit** 格式：`<type>(<scope>): <subject>`（参考最近 git log）
4. **PR** 描述里说明改动的决策号（D-NNN）和影响模块
5. **CI** 通过 + 至少 1 位 reviewer 通过 → 合 main

类型约定：
- `feat` 新功能
- `fix` bug 修复
- `refactor` 重构（无行为变化）
- `test` 仅测试
- `docs` 仅文档

---

## 📚 文档索引

| 文档 | 内容 |
|---|---|
| [`xiangsha/DEVELOPMENT.md`](xiangsha/DEVELOPMENT.md) | 工程文档总入口（按角色跳转） |
| [`xiangsha/docs/00-PRD.md`](xiangsha/docs/00-PRD.md) | 产品需求 · 141 个决策 D001-D141 · 5 类用户画像 · 模块 PRD |
| [`xiangsha/docs/01-SPEC.md`](xiangsha/docs/01-SPEC.md) | 技术规范 · 数据架构 · 抽签引擎参数表 · 测试矩阵 |
| [`xiangsha/docs/02-AGENTS.md`](xiangsha/docs/02-AGENTS.md) | 协作规范 · 命名 · 目录 · 提交流程 |
| [`xiangsha/docs/03-ROADMAP.md`](xiangsha/docs/03-ROADMAP.md) | 路线图 · 风险登记册 · 里程碑 · P0/P1/P2 行动清单 |
| [`xiangsha/docs/99-CHANGELOG.md`](xiangsha/docs/99-CHANGELOG.md) | 变更日志 |
| [`xiangsha/docs/m0-content-blueprint.md`](xiangsha/docs/m0-content-blueprint.md) | M0 内容生产蓝图（274 张卡 · 字段模板 · 协作分工） |
| [`xiangsha/docs/fox-persona.md`](xiangsha/docs/fox-persona.md) | 小狐狸 IP 人格化文案清单 |

---

## 🗺 当前进度

- [x] v1.2 决策体系（D132-D138 补全）
- [x] v1.4 文档拆分（PRD/SPEC/AGENTS/ROADMAP 4 文件）
- [x] **P0-2 隐私政策 GitHub Pages 部署**（2026-10-06）✅
- [x] **P0-4 README 重写**（2026-10-06）✅
- [ ] P0-1 M0 内容生产（274 张卡 · 多人协作中）
- [ ] P0-3 单元测试 Test Target 接入（Claude Code 主力）
- [ ] M1 通用抽签引擎 + 模块 A 吃啥基础
- [ ] M2 在家做扩展 + 成熟度
- [ ] M3 玩啥 + 做啥
- [ ] M4 拍啥 + 跨模块联动
- [ ] M5 共享功能 + 启动引导 + 设置
- [ ] M6 法务合规 + 性能调优 + TestFlight
- [ ] M7 v1.0 发布

---

## 🦊 关于小狐狸

`小白`是 App 里的小狐狸人格化角色，**也是这个项目的 AI 协作助手**。所有提示语、空状态文案、反馈语都从小狐狸嘴里说出。视觉成长（v1.1 戴厨师帽 / 拿相机）和真实图库（v1.2）待后续版本解锁。

---

## 📄 License

待定。详见后续 v1.0 发布前的 LICENSE 文件。

---

_最后更新：2026-10-06 · OpenClaw Team Leader 维护_
