//
//  DoViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D064-D076（做啥）+ D097（firstTaskComplete 成就）
//
//  ⚠️ 当前仅 smoke test 骨架，完整覆盖待补。
//

import XCTest
import SwiftData
@testable import xiangsha

/// 模块 C · 做啥 ViewModel 单元测试
///
/// 覆盖目标（v1 阶段）：
/// - T-VM-C01: VM 初始化不崩溃
/// - T-VM-C02: loadInitialData 后 scene + pools 非空
/// - T-VM-C03: draw() 在空 pool 时返回 invalidContext 错误
/// - T-VM-C04: D076 完成庆祝（showingCelebration 状态正确翻转）
/// - T-VM-C05: D097 firstTaskComplete 成就触发条件
final class DoViewModelTests: XCTestCase {

    // MARK: - T-VM-C01

    func testVM_C01_initDoesNotCrash() {
        let vm = DoViewModel()
        XCTAssertNil(vm.scene)
        XCTAssertFalse(vm.showingCelebration)
        XCTAssertEqual(vm.completedTasksToday, 0)
    }

    // MARK: - T-VM-C02

    func testVM_C02_loadInitialDataPopulatesSceneAndPools() async throws {
        throw XCTSkip("TestFixtures.makeModelContext 待补（P1 任务）")
    }

    // MARK: - T-VM-C03

    func testVM_C03_drawOnEmptyPoolReturnsError() async {
        let vm = DoViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
    }

    // MARK: - T-VM-C04

    func testVM_C04_celebrationFlagToggles() async throws {
        // TODO: 验证 accept() 后 showingCelebration = true（触发条件由 D076 决定）
        throw XCTSkip("需 TestFixtures + accept mock（P1 任务）")
    }

    // MARK: - T-VM-C05

    func testVM_C05_firstTaskCompleteAchievementTriggers() async throws {
        // D097：第一次完成任务解锁 firstTaskComplete 成就
        throw XCTSkip("需 AchievementService mock（P1 任务）")
    }
}
