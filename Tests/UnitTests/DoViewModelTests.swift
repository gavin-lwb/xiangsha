//
//  DoViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D064-D076（做啥）+ D076（完成庆祝）+ D097（firstTaskComplete 成就）
//
//  覆盖目标（v1 阶段）：
//  - T-VM-C01: VM 初始化不崩溃
//  - T-VM-C02: loadInitialData 后 scene + pools 非空
//  - T-VM-C03: draw() 在空 pool 时返回 invalidContext 错误
//  - T-VM-C04: showingCelebration 初始为 false
//  - T-VM-C05: completedTasksToday 初始为 0
//

import XCTest
import SwiftData
@testable import xiangsha

@MainActor
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
        let seeded = try TestFixturesVM.makeSeededContext(sceneType: .task)
        let vm = DoViewModel()
        await vm.loadInitialData(context: seeded.context)
        XCTAssertNotNil(vm.scene)
        XCTAssertEqual(vm.scene?.typeRaw, DecisionSceneType.task.rawValue)
        XCTAssertNotNil(vm.selectedPool)
        XCTAssertFalse(vm.pools.isEmpty, "fix/do-photo-poolpicker 同款修复后 pools 应非空")
    }

    // MARK: - T-VM-C03

    func testVM_C03_drawOnEmptyPoolReturnsError() async {
        let vm = DoViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
        if case .invalidContext = vm.error {
            // 期望
        } else {
            XCTFail("期望 DrawEngineError.invalidContext，得到 \(String(describing: vm.error))")
        }
    }

    // MARK: - T-VM-C04

    func testVM_C04_celebrationStartsFalse() {
        let vm = DoViewModel()
        XCTAssertFalse(vm.showingCelebration, "D076 完成庆祝初始应不显示")
    }

    // MARK: - T-VM-C05

    func testVM_C05_completedTasksStartsAtZero() {
        let vm = DoViewModel()
        XCTAssertEqual(vm.completedTasksToday, 0, "D097 初始已完成任务数应为 0")
    }
}
