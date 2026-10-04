# 「想啥」隐私政策 / Pick Now Privacy Policy

> **代号**：想啥（zh-CN）/ Pick Now（en-US）/ xiangsha（工程 scheme）
> **生效日期**：2026-10-04
> **最后更新**：2026-10-04
> **适用版本**：v1.0 及以上

---

## 简明版（一句话）

> **我们不知道你是谁，也不知道你抽了什么签。所有数据都在你设备上，从不离开。**

---

## 中文版（zh-CN）

### 1.1 我们的承诺

「想啥」（Pick Now）是一款**完全本地化**的决策辅助 App。我们的核心承诺：

- ❌ 不收集任何用户数据
- ❌ 不放置广告标识符（IDFA）
- ❌ 不集成任何第三方分析 SDK
- ❌ 不向任何第三方传输数据
- ❌ 不需要注册 / 登录

### 1.2 我们不收集什么

| 数据类型 | 是否收集 | 备注 |
|---|---|---|
| 账号信息 | ❌ | 无需注册 |
| 位置数据 | ❌ | 仅用于天气感知（v1.1+），使用粗精度且不上传 |
| 通讯录 | ❌ | — |
| 使用统计 / 分析 | ❌ | — |
| 崩溃报告 | ❌ | — |
| 广告 ID | ❌ | — |
| 设备 ID | ❌ | — |
| 任何标识符 | ❌ | — |

### 1.3 我们存储什么（仅本地）

所有数据保存在你的设备本地（**SwiftData**），从未上传到任何服务器：

- 你抽过的卡（仅用于"重复不抽"功能）
- 你收藏的卡（仅用于显示收藏列表）
- 你设置的食物过敏原（仅用于"不吃啥"功能）
- 你创建的自定义卡
- 你的设置项（`@AppStorage`）
- 3 emoji 评分（😋/😐/🙅，仅用于推荐优化）

> **你可以随时在「设置 → 数据」中清空所有本地数据。**

### 1.4 可选功能（默认关闭 · 需用户主动开启）

| 功能 | 使用数据 | 何时使用 | 如何关闭 |
|---|---|---|---|
| **天气感知**（D137，v1.1+）| 粗精度位置 + 当前天气 | 启动时获取一次 | 设置 → 隐私 → 关闭 |
| **CoreMotion 启动**（D100）| 加速度计 | 仅在你做"做啥"任务时 | 设置 → 隐私 → 关闭 |
| **iCloud 同步**（D131，v1.1+）| 上述所有本地数据 | 跨 Apple 设备同步 | iOS 系统设置 → Apple ID → iCloud |

**重要**：
- 天气 API 调用**仅获取当前天气状况**，不附带位置精度，不存储
- CoreMotion **仅在你主动开始任务时启用**，完成后自动关闭，**不会持续监控**
- iCloud 同步使用 **你的私人 iCloud 账户**，端到端加密，**我们看不到任何同步内容**

### 1.5 儿童隐私

本 App 不面向 13 岁以下儿童，也不收集他们的数据。

### 1.6 政策变更

如果本政策有重大变更，我们会在 App 内显著提示（启动引导或全屏公告）并请求你的同意。继续使用即视为同意。

### 1.7 联系我们

如有问题、建议或投诉：

- **GitHub Issues**：https://github.com/fengxiaohai/xiangsha/issues
- **邮箱**：fengxiaohai@example.com（占位，请替换为真实邮箱）

### 1.8 法律

本政策适用中华人民共和国法律法规。如有冲突，以中国法律为准。

---

## English Version (en-US)

### 2.1 Our Commitment

**Pick Now** is a **fully local** decision-making app. Our core promise:

- ❌ We do **not** collect any user data
- ❌ We do **not** use advertising identifiers (IDFA)
- ❌ We do **not** integrate third-party analytics SDKs
- ❌ We do **not** transmit any data to third parties
- ❌ No registration / login required

### 2.2 What We Do Not Collect

| Data Type | Collected? | Notes |
|---|---|---|
| Account info | ❌ | No sign-up |
| Location data | ❌ | Only for weather (v1.1+), coarse, not uploaded |
| Contacts | ❌ | — |
| Usage analytics | ❌ | — |
| Crash reports | ❌ | — |
| Advertising ID | ❌ | — |
| Device ID | ❌ | — |
| Any identifier | ❌ | — |

### 2.3 What We Store (Local Only)

All data is stored locally on your device via SwiftData. It never leaves your device:

- Cards you've drawn (only for "don't repeat" logic)
- Your favorites (only for display)
- Your food allergens (only for "what NOT to eat" filtering)
- Your custom cards
- Your preferences (`@AppStorage`)
- 3 emoji feedback (😋/😐/🙅, only for recommendation tuning)

> **You can erase all local data anytime at Settings → Data → Erase.**

### 2.4 Optional Features (OFF by default)

| Feature | Data Used | When | How to Disable |
|---|---|---|---|
| **Weather Awareness** (D137, v1.1+) | Coarse location + current weather | Once at launch | Settings → Privacy → Off |
| **CoreMotion Start** (D100) | Accelerometer | Only during active tasks | Settings → Privacy → Off |
| **iCloud Sync** (D131, v1.1+) | All local data above | Cross-device sync | iOS Settings → Apple ID → iCloud |

### 2.5 Children's Privacy

This app is not intended for children under 13, and we do not knowingly collect data from them.

### 2.6 Policy Changes

Material changes will be announced in-app (onboarding or full-screen banner) and require your consent. Continued use indicates acceptance.

### 2.7 Contact

- **GitHub Issues**: https://github.com/fengxiaohai/xiangsha/issues
- **Email**: fengxiaohai@example.com (placeholder)

---

## 变更记录 / Revision History

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0 | 2026-10-04 | 首版（v1.0 上架前） |