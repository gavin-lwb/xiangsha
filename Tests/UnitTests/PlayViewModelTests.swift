//
//  PlayViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D057-D063（玩啥·点子库）+ §A.9 测试矩阵
//
//  ⚠️ 当前仅 smoke test 骨架，完整覆盖待补。
//

import XCTest
import SwiftData
@testable import xiangsha

/// 模块 B · 玩啥 ViewModel 单元测试
///
/// 覆盖目标（v1 阶段）：
/// - T-VM-B01: VM 初始化不崩溃
/// - T-VM-B02: D059 时段自动选 pool（午后 14-18 选「室外」，其余选「室内」）
/// - T-VM-B03: loadInitialData 后 pools 非空
/// - T-VM-B04: draw() 在空 pool 时返回 invalidContext 错误
/// - T-VM-B05: 与吃啥模块池子完全不重叠（D057）
final class PlayViewModelTests: XCTestCase {

    // MARK: - T-VM-B01

    func testVM_B01_initDoesNotCrash() {
        let vm = PlayViewModel()
        XCTAssertNil(vm.scene)
        XCTAssertNil(vm.selectedPool)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.lastResult)
    }

    // MARK: - T-VM-B02

    func testVM_B02_autoSelectOutdoorPoolInAfternoon() async throws {
        // TODO: 需 TestFixtures + 时段 mock（注入 Calendar.current）
        // 验证 14:00-18:00 选中「室外」pool
        throw XCTSkip("需 TestFixtures + Calendar mock（P1 任务）")
    }

    // MARK: - T-VM-B03

    func testVM_B03_loadInitialDataPopulatesPools() async throws {
        throw XCTSkip("TestFixtures.makeModelContext 待补（P1 任务）")
    }

    // MARK: - T-VM-B04

    func testVM_B04_drawOnEmptyPoolReturnsError() async {
        let vm = PlayViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
    }

    // MARK: - T-VM-B05

    func testVM_B05_playPoolsDoNotOverlapWithEatPools() async throws {
        // D057：玩啥与吃啥完全不重叠
        // TODO: 验证 DecisionScene(typeRaw: "play") 与 DecisionScene(typeRaw: "eat") 的 CardPool 无交集
        throw XCTSkip("需 TestFixtures + 双向 fetch（P1 任务）")
    }
}
