//
//  PhotoViewModelTests.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：D077-D086（拍啥姿势）+ D140（v1 占位）+ D141（v1.1 真实图）
//
//  ⚠️ 当前仅 smoke test 骨架，完整覆盖待补。
//

import XCTest
import SwiftData
@testable import xiangsha

/// 模块 D · 拍啥 ViewModel 单元测试
///
/// 覆盖目标（v1 阶段）：
/// - T-VM-D01: VM 初始化不崩溃
/// - T-VM-D02: loadInitialData 后 scene + pools 非空
/// - T-VM-D03: draw() 在空 pool 时返回 invalidContext 错误
/// - T-VM-D04: createUserPhotoCard 正确创建用户自定义卡
/// - T-VM-D05: deleteUserPhotoCard 只能删除用户自定义卡（isUserCreated 校验）
/// - T-VM-D06: rate(emoji: .dislike) 设置 7 天 excludeUntil
/// - T-VM-D07: PhotoCaptureServiceFactory.make() 返回 EmojiPhotoCaptureService（v1 占位）
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
        throw XCTSkip("TestFixtures.makeModelContext 待补（P1 任务）")
    }

    // MARK: - T-VM-D03

    func testVM_D03_drawOnEmptyPoolReturnsError() async {
        let vm = PhotoViewModel()
        await vm.draw()
        XCTAssertNotNil(vm.error)
    }

    // MARK: - T-VM-D04

    func testVM_D04_createUserPhotoCard() async throws {
        // TODO: 验证 createUserPhotoCard 创建 isUserCreated=true 的 Card
        throw XCTSkip("需 TestFixtures + user pool 创建校验（P1 任务）")
    }

    // MARK: - T-VM-D05

    func testVM_D05_deleteUserPhotoCardOnlyDeletesUserCreated() async throws {
        // TODO: 验证对非用户卡的删除操作被忽略
        throw XCTSkip("需 TestFixtures（P1 任务）")
    }

    // MARK: - T-VM-D06

    func testVM_D06_dislikeSetsExcludeUntil7Days() async throws {
        // TODO: 验证 rate(emoji: .dislike) 写入 card.excludeUntil 为 7 天后
        throw XCTSkip("需 TestFixtures + Card fixture（P1 任务）")
    }

    // MARK: - T-VM-D07

    func testVM_D07_captureServiceFactoryReturnsEmojiPlaceholder() async {
        let service = PhotoCaptureServiceFactory.make()
        let fakeCard = Card(
            title: "测试姿势",
            scene: DecisionScene(typeRaw: "photo", displayName: "拍啥"),
            pool: CardPool(name: "test", icon: "camera", sortOrder: 0, scene: DecisionScene(typeRaw: "photo", displayName: "拍啥")),
            emoji: "📸",
            category: "single"
        )
        let resource = await service.visualResource(for: fakeCard)
        if case .placeholder(let emoji, _) = resource {
            XCTAssertEqual(emoji, "📸")
        } else {
            XCTFail("v1 阶段应返回 .placeholder，实际返回其他")
        }
    }
}
