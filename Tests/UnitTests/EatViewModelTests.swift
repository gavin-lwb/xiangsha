//
//  EatViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：SPEC §10.1 模块 A + §A.9 测试矩阵
//
//  ⚠️ 当前仅 smoke test 骨架，完整覆盖待补。
//  Test Target 接入步骤见 Tests/UnitTests/README.md
//

import XCTest
import SwiftData
@testable import xiangsha

/// 模块 A · 吃啥 ViewModel 单元测试
///
/// 覆盖目标（v1 阶段）：
/// - T-VM-A01: VM 初始化不崩溃
/// - T-VM-A02: loadInitialData 后 scene + pools 非空（mock context）
/// - T-VM-A03: draw() 在空 pool 时返回 invalidContext 错误（D088 兜底）
/// - T-VM-A04: accept() 在 lastResult 非空时清除 lastResult
/// - T-VM-A05: rate(emoji: .dislike) 设置 7 天 excludeUntil
final class EatViewModelTests: XCTestCase {

    // MARK: - T-VM-A01

    func testVM_A01_initDoesNotCrash() {
        let vm = EatViewModel()
        XCTAssertNil(vm.scene)
        XCTAssertNil(vm.selectedPool)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.lastResult)
        XCTAssertNil(vm.error)
    }

    // MARK: - T-VM-A02

    func testVM_A02_loadInitialDataPopulatesSceneAndPools() async throws {
        // TODO: 需 TestFixtures.makeModelContext() 真实构造 SwiftData context
        // 当前阻塞：TestFixtures 文件缺失（已记入 P1 任务）
        throw XCTSkip("TestFixtures.makeModelContext 待补（P1 任务）")
    }

    // MARK: - T-VM-A03

    func testVM_A03_drawOnEmptyPoolReturnsError() async {
        let vm = EatViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
    }

    // MARK: - T-VM-A04

    func testVM_A04_acceptClearsLastResult() async throws {
        // TODO: 需 mock lastResult 后验证 modelContext.insert 被调用
        throw XCTSkip("需 TestFixtures + mock DrawResult（P1 任务）")
    }

    // MARK: - T-VM-A05

    func testVM_A05_dislikeSetsExcludeUntil7Days() async throws {
        // TODO: 验证 rate(emoji: .dislike) 写入 card.excludeUntil 为 7 天后
        throw XCTSkip("需 TestFixtures + Card fixture（P1 任务）")
    }
}
