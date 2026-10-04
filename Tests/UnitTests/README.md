# xiangsha 单元测试（待 Test Target 接入）

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
9. **拖入** `Tests/UnitTests/DrawEngineTests.swift` 到 `xiangshaTests` target
10. 选择 scheme **xiangsha**（不是 xiangshaTests） → **Product → Test**（`Cmd + U`）

## 验证

```bash
xcodebuild test \
  -scheme xiangsha \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

应输出 `Test Suite 'DrawEngineTests' passed`。

## 覆盖范围

`DrawEngineTests.swift` 已实现 SPEC §A.9 的 **15 个用例中的 12 个**：

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

## 关联决策

- SPEC §A.9 测试矩阵
- 02-AGENTS §10 测试约定
- ROOT_AGENTS.md §10 单元测试