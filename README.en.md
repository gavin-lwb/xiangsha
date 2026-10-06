# 想啥 · Pick Now

> **"Can't decide what to eat, play, do, or shoot? Draw a card."**
> A fully-local iOS decision assistant — 4 modules, 274 cards, zero data collection.

| Codename | 想啥 (zh-CN) · Pick Now (en-US) · **xiangsha** (Xcode scheme) |
|---|---|
| Platform | iOS 17+ / iPhone · SwiftUI · SwiftData |
| Stack | Xcode 15+ · single target, single workspace |
| Status | v1.0 content production in progress (M0) · module scaffolding complete |
| Privacy | **Zero data collection** — see [Privacy Policy](https://gavin-lwb.github.io/xiangsha/xiangsha/Resources/privacy-policy.md) |

---

## ✨ What is this?

A minimalist anti-indecision app. **Don't know what to eat?** Draw a card. **Bored on the weekend?** Draw a card. **Don't know what to do?** Draw a card. The whole draw takes 1.2 seconds. **All results stay on your device** — the app doesn't know who you are or what you drew.

Design principles: **slow decisions, light interactions, personified feedback**. A little fox called "小白" (Xiaobai) accompanies you through every step — never rushing, never judging.

---

## 🎴 4 Modules

| Module | Cards | Purpose | v1 Status |
|---|---|---|---|
| **A 吃啥 (Eat)** | 80 | Breakfast / lunch / dinner + takeout / cook at home / time filters | ✅ Draw + animation + pool picker ready |
| **B 玩啥 (Play) · Idea Library** | 80 | Indoor / outdoor / solo / group / creative / learning | ✅ Draw + pool picker ready |
| **C 做啥 (Do)** | 60 | Housework / exercise / self-improvement / social / care-for-others | ✅ Draw + pool picker ready |
| **D 拍啥 (Photo) · Pose** | 54 | Indoor / outdoor / full body / half body / props | ✅ Draw + photo placeholder + pool picker ready |
| **Total** | **274** | — | M0 content production (user review + maben copy polish) |

> Single-person estimate: 3 weeks (274 × 25 min/card). Multi-agent collaboration compresses to 1.5–2 weeks.
> Detailed breakdown: [`docs/m0-content-blueprint.md`](xiangsha/docs/m0-content-blueprint.md) (zh-CN).

---

## 🚀 Quick Start

### Requirements
- macOS 14+ · Xcode 15+
- iOS 17+ device or simulator
- Apple Developer account (not needed to run, needed to ship)

### Run it
```bash
git clone https://github.com/gavin-lwb/xiangsha.git
cd xiangsha
open xiangsha.xcodeproj
```
In Xcode, select the `xiangsha` scheme → pick a simulator (iPhone 15 recommended) → **Cmd + R**.

### Run tests
Test target setup steps: [`Tests/UnitTests/README.md`](Tests/UnitTests/README.md).
After setup:
```bash
xcodebuild test \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```
Expected output: 5 test suites green — `DrawEngineTests` / `EatViewModelTests` / `PlayViewModelTests` / `DoViewModelTests` / `PhotoViewModelTests`.

---

## 🏗 Project Structure

```
xiangsha/
├── xiangsha.xcodeproj/          # Xcode project
├── xiangsha/                    # Main source
│   ├── App/
│   │   ├── Core/                # Core models + services
│   │   │   ├── Models/          # Card / DecisionScene / DrawRecord / ...
│   │   │   └── Services/        # SeedService / DrawEngine / ...
│   │   ├── Modules/             # 4 independent modules
│   │   │   ├── Eat/             #   A 吃啥
│   │   │   ├── Play/            #   B 玩啥
│   │   │   ├── Do/              #   C 做啥
│   │   │   └── Photo/           #   D 拍啥
│   │   ├── Shared/              # Cross-module (settings / favorites / history / onboarding)
│   │   └── xiangshaApp.swift    # @main entry point
│   ├── Resources/
│   │   ├── PrivacyInfo.xcprivacy
│   │   └── privacy-policy.md    # Privacy policy source (deployed to GitHub Pages)
│   ├── docs/                    # PRD / SPEC / AGENTS / ROADMAP / CHANGELOG (zh-CN)
│   └── DEVELOPMENT.md           # Engineering doc index
└── Tests/
    └── UnitTests/               # Unit tests (5 VMs + DrawEngine)
```

---

## 🛠 Tech Stack

| Layer | Choice | Why |
|---|---|---|
| UI | SwiftUI | Declarative + iOS 17 features (`@Observable`, improved `onChange`) |
| Data | SwiftData | Native, zero dependencies, auto-migration (D138) |
| Animation | TimelineView | Fixes SwiftUI `.task` race conditions (battle-tested) |
| Draw Engine | Custom (D005–D014) | Weight + cooldown + concurrency + 2-tier fallback |
| Testing | XCTest | No third-party frameworks |
| Privacy Manifest | PrivacyInfo.xcprivacy | App Store compliance (D113) |

---

## 🤝 Contributing

1. **Read** [`xiangsha/docs/02-AGENTS.md`](xiangsha/docs/02-AGENTS.md) — naming, structure, boundaries (mostly zh-CN)
2. **Fork** → create a `feat/xxx` or `fix/xxx` branch
3. **Commit** format: `<type>(<scope>): <subject>` (see recent git log)
4. **PR** description must reference decision IDs (D-NNN) and affected modules
5. **CI** green + at least 1 reviewer approval → merge to main

Commit types:
- `feat` new feature
- `fix` bug fix
- `refactor` refactor (no behavior change)
- `test` tests only
- `docs` docs only

---

## 📚 Documentation Index

Most project docs are in Chinese. Translating them is on the v1.1+ roadmap.

| Document | Content |
|---|---|
| [`xiangsha/DEVELOPMENT.md`](xiangsha/DEVELOPMENT.md) | Doc index (role-based navigation) |
| [`xiangsha/docs/00-PRD.md`](xiangsha/docs/00-PRD.md) | Product requirements · 141 decisions D001-D141 · user personas · module PRDs (zh-CN) |
| [`xiangsha/docs/01-SPEC.md`](xiangsha/docs/01-SPEC.md) | Tech spec · data architecture · draw engine params · test matrix (zh-CN) |
| [`xiangsha/docs/02-AGENTS.md`](xiangsha/docs/02-AGENTS.md) | Collaboration spec · naming · structure · PR flow (zh-CN) |
| [`xiangsha/docs/03-ROADMAP.md`](xiangsha/docs/03-ROADMAP.md) | Roadmap · risk register · milestones · P0/P1/P2 action lists (zh-CN) |
| [`xiangsha/docs/m0-content-blueprint.md`](xiangsha/docs/m0-content-blueprint.md) | M0 content production blueprint (274 cards · field templates · task split) (zh-CN) |

---

## 🗺 Current Progress

- [x] v1.2 decision system complete (D132-D138)
- [x] v1.4 doc split (PRD/SPEC/AGENTS/ROADMAP as 4 files)
- [x] **P0-2 Privacy Policy on GitHub Pages** (2026-10-06) ✅
- [x] **P0-4 README rewrite** (2026-10-06) ✅
- [ ] P0-1 M0 content production (274 cards · multi-agent in progress)
- [ ] P0-3 Unit test target setup (Claude Code leading)
- [ ] M1 Universal draw engine + Module A eat basics
- [ ] M2 Cook-at-home extension + maturity
- [ ] M3 Play + Do modules
- [ ] M4 Photo + cross-module links
- [ ] M5 Shared features + onboarding + settings
- [ ] M6 Legal compliance + perf + TestFlight
- [ ] M7 v1.0 release

---

## 🦊 About Xiaobai (the fox)

`小白` is the little fox persona inside the app — **and also the AI collaboration assistant for this project**. All prompts, empty states, and feedback speak in Xiaobai's voice. Visual evolution (v1.1: chef hat / camera) and real pose libraries (v1.2) unlock in later versions.

---

## 📄 License

TBD. See the LICENSE file added before v1.0 release.

---

_Last updated: 2026-10-06 · maintained by OpenClaw Team Leader_
