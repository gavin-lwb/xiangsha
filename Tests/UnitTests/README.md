# xiangsha 单元测试 · P0-3 T1 接入手册

> **本 README 是 Claude Code 执行 P0-3 T1（Test Target 接入）的 step-by-step 手册**。
> **T1 完成标志**：下面"接入步骤"全部跑完 + "验证"部分命令全绿 + 5 个测试套件可见（哪怕全 skip）。
> **T2 接手**：T1 完成 idle 后，OpenClaw 会派 T2（把 XCTSkip 升级成实跑）。

---

## 0. TL;DR

| 项 | 状态 |
|---|---|
| 测试代码 | **已写好** · 779 行 · 5 个 VM 文件 + 1 个 DrawEngine + Support/ 夹具 |
| Test Target | ❌ **未配置** · `.swift` 文件目前不会被 Xcode 自动编译/运行 |
| 接入难度 | ⭐⭐☆☆☆（GUI 10 步 / 约 15 分钟） |
| 接入后跑测试 | `xcodebuild test -scheme xiangsha -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` |
| 预期通过率 | 5 套件全绿（VM 测试已从 XCTSkip 升级为可实跑，commit `e902594`） |

---

## 1. 前置检查（5 分钟 · 必须全过再进入下一步）

```bash
cd ~/project/xiangsha

# 1.1 当前在 main 分支
git branch --show-current   # 应输出: main

# 1.2 工作区干净
git status --short          # 应输出空

# 1.3 Xcode 版本 ≥ 15
xcodebuild -version         # 应输出 Xcode 15.0 或更高（推荐 15.4+）

# 1.4 模拟器 iPhone 17 可用
xcrun simctl list devices available | grep "iPhone 17"   # 应至少 1 行

# 1.5 主 app 能 build
xcodebuild build -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -quiet 2>&1 | tail -5
# 应输出 ** BUILD SUCCEEDED **
```

**任何一项不过，先停下来排查**。尤其是 1.5，如果主 app 都 build 不过，加 test target 只会让错误更难定位。

---

## 2. 接入步骤（Xcode GUI · 10 步）

> **必须用 GUI 走通**，CLI 改 `.pbxproj` 是 fallback 路径（见 §6）。Xcode 操作虽然不能脚本化，但每步都有可验证的中间产物。

### Step 1 · 打开工程

```bash
open xiangsha.xcodeproj
```

✅ 验收：Xcode 启动，左侧 File Navigator 看到 `xiangsha` 蓝色工程图标 + 黄色 `xiangsha` 文件夹。

### Step 2 · 新建 Test Target

Xcode 菜单：**File → New → Target...**

- 顶部搜索框输入 `unit`
- 选 **Unit Testing Bundle**（图标：白色方块 + XC 字样，**不是** UI Testing Bundle）
- 点 **Next**

✅ 验收：进入配置页。

### Step 3 · 配置 Test Target

| 字段 | 填什么 | 备注 |
|---|---|---|
| **Product Name** | `xiangshaTests` | 不要带空格/横线 |
| **Team** | 留空（None） | 测试不需要签名 |
| **Organization Identifier** | （用默认） | Xcode 自动从主 app 推断 |
| **Bundle Identifier** | 应自动填为 `Claude.lwb.xiangshaTests` | **手核对一次**——必须以 `.xiangshaTests` 结尾，和主 app `Claude.lwb.xiangsha` 区分 |
| **Language** | **Swift** | 默认就是，别动 |
| **Project** | （默认 `xiangsha`，不要改成 workspace） | — |
| **Embed in** | **Don't Embed** | 测试不走 bundle |

点 **Finish**。

✅ 验收：弹出对话框问 "Activate scheme?" → 点 **Activate**（让 Xcode 自动切到 xiangshaTests scheme）。

### Step 4 · 切回主 scheme

Xcode 顶部 scheme 下拉框 → 选 **xiangsha**（**不要**用 xiangshaTests，否则 `Cmd+U` 跑的是测试 target 自己，会找不到主 app 的 @testable）。

点完确认顶部设备选择是 **iPhone 17**。

✅ 验收：scheme 下拉显示 `xiangsha > iPhone 17`。

### Step 5 · 删除 Xcode 自动生成的占位文件

File Navigator 里展开新出现的 **xiangshaTests** 文件夹（黄色），找到 `xiangshaTests.swift`：

- 选中 → 右键 → **Move to Trash**（不是 Remove Reference，是真的删）
- 弹出确认框 → **Delete**

✅ 验收：`xiangshaTests/` 文件夹现在是空的（Xcode 默认只生成了一个 .swift 文件）。

### Step 6 · 拖入测试源文件（关键步骤 · 容易踩坑）

**这一步决定 Test Target Membership 是否正确，踩错就是 "no such module" 灾难。**

**前置**：**关闭 Xcode**（拖文件时如果 Xcode 还开着且 schema 没切对，容易触发奇怪的 file lock 问题；先关掉，命令行操作更可控）。

```bash
# 在 shell 里直接把整个 Tests/UnitTests 软链到工程根
ln -s Tests/UnitTests xiangshaTests
# 注：这是临时软链，仅用于下面 Step 6.5 的 Add Files 操作引用；
#     Add Files 完成后立刻删除（见 Step 6.7）
```

重新 `open xiangsha.xcodeproj`。

**Step 6.1** Xcode 菜单 **File → Add Files to "xiangsha"...**

**Step 6.2** 弹出的文件选择器，导航到工程根的 `Tests/UnitTests/` 目录。

**Step 6.3** 选中以下 **6 项**（用 Shift 多选）：
- `DrawEngineTests.swift`
- `EatViewModelTests.swift`
- `PlayViewModelTests.swift`
- `DoViewModelTests.swift`
- `PhotoViewModelTests.swift`
- `Support/`（整个文件夹，**不是** Support/TestFixturesVM.swift 单文件）

**Step 6.4** 弹出选项对话框，**逐项核对**：

| 选项 | 必须设置 |
|---|---|
| **Destination** | ☑ Copy items if needed ← **取消勾选**（保留 git 链接，不要物理复制到工程目录） |
| **Added folders** | ⚪ Create groups（不是 Create folder references） |
| **Add to targets** | ☑ **只勾选 `xiangshaTests`**，**绝对不要勾 `xiangsha`**（否则 Support/ 里的 `@testable import xiangsha` 会自引用死锁） |

**Step 6.5** 点 Finish。

**Step 6.6** 删除刚才的临时软链：

```bash
rm xiangshaTests
```

**Step 6.7** 验证 File Navigator：左侧应能看到 `xiangshaTests`（蓝色 target 文件夹）+ `xiangshaTests/`（黄色组）下面有 5 个 .swift + 1 个 Support/。

✅ 验收：点击任意一个 .swift 文件，右边 inspector → **Target Membership** 标签页 → **只勾 `xiangshaTests`**，**`xiangsha` 必须未勾**。Support/ 内的 TestFixturesVM.swift 同样核对。

### Step 7 · 验证 Build Settings

左侧选 `xiangshaTests` target → **Build Settings** 标签 → 搜索 `test`：

| Key | 应有值 |
|---|---|
| **Product Bundle Identifier** | `Claude.lwb.xiangshaTests` |
| **Test Host** | `$(BUILT_PRODUCTS_DIR)/xiangsha.app/xiangsha`（自动） |
| **Bundle Loader** | `$(TEST_HOST)`（自动） |
| **iOS Deployment Target** | `17.0`（与主 app 一致） |
| **Swift Language Version** | `5.0`（或 Project Default） |

> **常见漏配**：Test Host 没设置会导致 `@testable import xiangsha` 失败。如果你看到 `Test Host = ""`，手工填一次 `$(BUILT_PRODUCTS_DIR)/xiangsha.app/xiangsha`。

✅ 验收：所有上述字段值正确。

### Step 8 · 第一次 build（命令行验证 · 不跑测试）

```bash
xcodebuild build-for-testing \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -quiet 2>&1 | tail -20
```

期望输出末尾：
```
** TEST BUILD SUCCEEDED **
```

**常见错误**：

| 错误 | 原因 | 修复 |
|---|---|---|
| `no such module 'xiangsha'` | Test Host 未设 | 回 Step 7 手工填 |
| `Cannot find 'EatViewModel' in scope` | Test Target Membership 漏勾文件 | 回 Step 6.4 重新 Add |
| `Command SwiftCompile failed` | Support/ 没加入 xiangshaTests | 回 Step 6.3 重做 |
| `Failed to load module 'xiangsha'` | 主 app build 没过 | 先单独 `xcodebuild build -scheme xiangsha` 排查 |

### Step 9 · 跑测试（核心验证）

```bash
xcodebuild test-without-building \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 2>&1 | tail -60
```

期望输出末尾（**5 套件全绿**）：
```
Test Suite 'DrawEngineTests' passed
Test Suite 'EatViewModelTests' passed
Test Suite 'PlayViewModelTests' passed
Test Suite 'DoViewModelTests' passed
Test Suite 'PhotoViewModelTests' passed

** TEST SUCCEEDED **
```

✅ 验收：5 个测试套件全部 passed，统计行 `Executed 5 tests, with 0 failures`。

### Step 10 · 在 Xcode GUI 里也跑一次

回到 Xcode，按 **Cmd + U**（或菜单 **Product → Test**）。

✅ 验收：Xcode 左侧 Test Navigator 弹出，每条用例前是绿色 ✓。展开 DrawEngineTests 应看到 T01-T15 共 15 个用例（12 passed + 1 skipped + 2 性能类）。

---

## 3. 验收清单（DoD · Definition of Done）

T1 完成必须满足 **全部**：

- [ ] `xcodebuild build-for-testing -scheme xiangsha -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` 输出 `** TEST BUILD SUCCEEDED **`
- [ ] `xcodebuild test -scheme xiangsha -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` 输出 `** TEST SUCCEEDED **`
- [ ] 5 个测试套件全部 passed
- [ ] DrawEngineTests 至少 14 个用例 passed（T12 L2 兜底可 skip）
- [ ] 4 个 VM 测试套件各至少 5 个用例 passed（A/B/C/D 模块）
- [ ] File Navigator 看起来干净（无 黄色警告 / 无 Duplicate Symbol）
- [ ] 没有把任何测试文件误加入 `xiangsha` app target

---

## 4. 完成后 commit

```bash
cd ~/project/xiangsha

# 4.1 检查 pbxproj 变更
git status --short
# 应至少包含: xiangsha.xcodeproj/project.pbxproj (modified)
#           + xiangsha.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved (maybe)

# 4.2 千万不要 commit Tests/UnitTests/ 下的源文件 —— 它们本来就 tracked
git diff --stat

# 4.3 commit
git add xiangsha.xcodeproj/
git commit -m "test(target): 接入 xiangshaTests Unit Test Target

- 新建 Unit Testing Bundle target: xiangshaTests (bundle: Claude.lwb.xiangshaTests)
- 添加 5 个 VM 测试文件 + DrawEngineTests + Support/ 夹具
- Test Host 配置: \$(BUILT_PRODUCTS_DIR)/xiangsha.app/xiangsha
- iOS Deployment Target: 17.0 (与主 app 对齐)
- 验证: xcodebuild test 全 5 套件通过
- 关联: P0-3 T1 完成 → 解锁 T2 实跑化" 2>&1

# 4.4 push
git push origin main
```

---

## 5. 接下来（交接给 T2）

T1 完成后 **不要继续动测试代码**。等 OpenClaw Lead 派 T2 任务（具体内容会附在 task description 里）。T2 大致会是：

1. **重跑一遍 T1** 确认 green baseline
2. **逐 VM 检查** XCTSkip 标记是否还有残留（应该没有，commit `e902594` 已清理）
3. **补缺失的 setUp/tearDown**（如有）
4. **加 coverage 报告** `xcodebuild test -enableCodeCoverage YES ...`
5. **CI 集成**（Gitee → GitHub Actions 迁移后的 .github/workflows/）

---

## 6. Fallback · CLI 改 pbxproj（仅 GUI 卡死时用）

> ⚠️ **不推荐**。`.pbxproj` 是内部格式，手改容易破坏 ID 引用。
> **仅当** macOS 找不到 Xcode GUI 或 sandbox 限制 GUI 时使用。

```bash
# 6.1 备份
cp xiangsha.xcodeproj/project.pbxproj{,.bak-$(date +%s)}

# 6.2 用 ruby + xcodeproj gem 操作（OpenClaw Lead 可代跑）
gem install xcodeproj --user-install
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("xiangsha.xcodeproj")
# ... (脚本由 OpenClaw Lead 在任务描述里给出)
'

# 6.3 build 验证
xcodebuild build-for-testing -scheme xiangsha ...
```

如果走到这条路径，**先停下来 @OpenClaw Lead 一起排**，不要硬上。

---

## 7. 测试套件预期明细（运行时长参考）

| 套件 | 文件 | 用例数 | 预期时长 | 备注 |
|---|---|---|---|---|
| **DrawEngineTests** | `DrawEngineTests.swift` | 15（T01-T15） | ~2-3s | 纯计算，无 SwiftData，最快 |
| **EatViewModelTests** | `EatViewModelTests.swift` | 5（A01-A05） | ~1-2s | VM + seeded context |
| **PlayViewModelTests** | `PlayViewModelTests.swift` | 5（B01-B05） | ~1-2s | 同上 |
| **DoViewModelTests** | `DoViewModelTests.swift` | 5（C01-C05） | ~1-2s | 同上 |
| **PhotoViewModelTests** | `PhotoViewModelTests.swift` | 6（D01-D06） | ~1-2s | 含 PhotoCaptureService mock |
| **合计** | — | **36 用例** | **~7-10s** | xcodebuild test 全跑耗时 |

> 如果总耗时 > 30s，多半是模拟器没启动好或 cache miss，先重跑一次。

---

## 8. 关联文档

- **SPEC §A.9** 测试矩阵（DrawEngine T01-T15 + VM T-VM-A/B/C/D 系列）
- **02-AGENTS §A.5** 测试约定（命名 / setUp / 边界）
- **ROADMAP G.1.1 P0-3** 当前真实 P0（测试覆盖任务）
- **`Tests/UnitTests/Support/TestFixturesVM.swift`** 夹具 API 文档（行内注释）
- **`xiangsha/App/Core/Models/XiangshaSchema.swift`** SwiftData Schema 定义（test fixture 用 v1_3）

---

## 9. 紧急情况

- **跑不过但不知道原因** → 跑 `xcodebuild test ... 2>&1 | grep -E "error:|warning:"` 抓所有错误，附在 OpenClaw Lead 的任务回复里
- **GUI 找不到 Unit Testing Bundle 模板** → Xcode 版本太旧，更新到 15.4+ 或换 macOS
- **Bundle Identifier 冲突** → 把 `Claude.lwb.xiangshaTests` 改成 `Claude.lwb.xiangshaTests.dev` 等，加后缀即可
- **git push 被拒** → 远端 main 有新 commit，先 `git pull --rebase` 再 push

---

_最后更新：2026-10-06 · OpenClaw Team Leader 为 P0-3 T1 编写_
_配套 commit：`e902594 test(vm): 补 TestFixturesVM + 4 模块 VM 测试从 XCTSkip 升级为可实跑`_
