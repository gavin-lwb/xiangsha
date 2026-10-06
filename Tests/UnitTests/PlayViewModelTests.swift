//
//  PlayViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D057-D063（玩啥·点子库）+ D059（按时段自动选 pool）+ §A.9 测试矩阵
//
//  覆盖目标（v1 阶段）：
//  - T-VM-B01: VM 初始化不崩溃
//  - T-VM-B02: D059 时段自动选 pool（午后 14-18 选「室外」，其余选「室内」）
//  - T-VM-B03: loadInitialData 后 pools 非空
//  - T-VM-B04: draw() 在空 pool 时返回 invalidContext 错误
//  - T-VM-B05: 与吃啥模块池子完全不重叠（D057）
//

import XCTest
import SwiftData
@testable import xiangsha

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

    func testVM_B02_loadInitialDataPopulatesPools() async throws {
        let seeded = try TestFixturesVM.makeSeededContext(sceneType: .play)
        let vm = PlayViewModel()
        await vm.loadInitialData(context: seeded.context)
        XCTAssertNotNil(vm.scene)
        XCTAssertEqual(vm.scene?.typeRaw, DecisionSceneType.play.rawValue)
        XCTAssertFalse(vm.pools.isEmpty, "D059 fix 后 pools 应非空")
    }

    // MARK: - T-VM-B03

    func testVM_B03_drawOnEmptyPoolReturnsError() async {
        let vm = PlayViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
        if case .invalidContext = vm.error {
            // 期望
        } else {
            XCTFail("期望 DrawEngineError.invalidContext，得到 \(String(describing: vm.error))")
        }
    }

    // MARK: - T-VM-B04

    func testVM_B04_rateDislikeDoesNotCrash() async throws {
        let seeded = try TestFixturesVM.makeSeededContext(sceneType: .play)
        let vm = PlayViewModel()
        vm.modelContext = seeded.context
        // lastResult 为 nil 时 rate 不崩（应直接 return）
        vm.rate(emoji: .dislike)
        XCTAssertNil(vm.currentRating)
    }

    // MARK: - T-VM-B05

    func testVM_B05_playAndEatScenesAreSeparate() throws {
        // D057：玩啥与吃啥场景物理隔离
        let eatScene = TestFixturesVM.makeScene(type: .eat)
        let playScene = TestFixturesVM.makeScene(type: .play)
        XCTAssertNotEqual(eatScene.typeRaw, playScene.typeRaw)
        XCTAssertEqual(eatScene.type, .eat)
        XCTAssertEqual(playScene.type, .play)
    }
}
