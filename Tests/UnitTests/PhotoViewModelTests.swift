//
//  PhotoViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D077-D086（拍啥姿势）+ D140（v1 占位）+ D141（v1.1 真实图）
//
//  覆盖目标（v1 阶段）：
//  - T-VM-D01: VM 初始化不崩溃
//  - T-VM-D02: loadInitialData 后 scene + pools 非空
//  - T-VM-D03: draw() 在空 pool 时返回 invalidContext 错误
//  - T-VM-D04: createUserPhotoCard 不在空 context 时不崩
//  - T-VM-D05: rate(emoji: .dislike) 不崩（lastResult nil 时不报错）
//  - T-VM-D06: PhotoCaptureServiceFactory.make() 返回 EmojiPhotoCaptureService（v1 占位）
//

import XCTest
import SwiftData
@testable import xiangsha

final class PhotoViewModelTests: XCTestCase {

    // MARK: - T-VM-D01

    func testVM_D01_initDoesNotCrash() {
        let vm = PhotoViewModel()
        XCTAssertNil(vm.scene)
        XCTAssertNil(vm.selectedPool)
        XCTAssertEqual(vm.pools.count, 0)
        XCTAssertEqual(vm.greetingText, "今天拍点啥？🦊")
    }

    // MARK: - T-VM-D02

    func testVM_D02_loadInitialDataPopulatesSceneAndPools() async throws {
        let seeded = try TestFixturesVM.makeSeededContext(sceneType: .photo)
        let vm = PhotoViewModel()
        await vm.loadInitialData(context: seeded.context)
        XCTAssertNotNil(vm.scene)
        XCTAssertEqual(vm.scene?.typeRaw, DecisionSceneType.photo.rawValue)
        XCTAssertNotNil(vm.selectedPool)
        XCTAssertFalse(vm.pools.isEmpty, "fix/do-photo-poolpicker 同款修复后 pools 应非空")
    }

    // MARK: - T-VM-D03

    func testVM_D03_drawOnEmptyPoolReturnsError() async {
        let vm = PhotoViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
        if case .invalidContext = vm.error {
            // 期望
        } else {
            XCTFail("期望 DrawEngineError.invalidContext，得到 \(String(describing: vm.error))")
        }
    }

    // MARK: - T-VM-D04

    func testVM_D04_createUserPhotoCardDoesNotCrashWithoutContext() {
        let vm = PhotoViewModel()
        // modelContext 为 nil 时应不崩（guard 直接 return）
        vm.createUserPhotoCard(title: "测试姿势", emoji: "📸")
        XCTAssert(true, "未崩溃")
    }

    // MARK: - T-VM-D05

    func testVM_D05_rateOnEmptyResultDoesNotCrash() {
        let vm = PhotoViewModel()
        // lastResult 为 nil 时 rate 不崩
        vm.rate(emoji: .dislike)
        XCTAssertNil(vm.currentRating)
    }

    // MARK: - T-VM-D06

    func testVM_D06_captureServiceFactoryReturnsEmojiPlaceholder() async throws {
        let seeded = try TestFixturesVM.makeSeededContext(sceneType: .photo)
        let service = PhotoCaptureServiceFactory.make()
        let resource = await service.visualResource(for: seeded.cards[0])
        if case .placeholder(let emoji, _) = resource {
            XCTAssertEqual(emoji, "🍽️", "默认 emoji 与 Card fixture 一致")
        } else {
            XCTFail("v1 阶段应返回 .placeholder，实际返回其他")
        }
    }
}
