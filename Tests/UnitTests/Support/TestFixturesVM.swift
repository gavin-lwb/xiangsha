//
//  TestFixturesVM.swift
//  xiangshaTests
//
//  Created by OpenClaw Team Leader on 2026/10/6.
//  关联决策：SPEC §A.9 测试矩阵 + 02-AGENTS §A.5 测试约定
//
//  ⚠️ 与 DrawEngineTests.swift 末尾的私有 TestFixtures **互补不冲突**：
//  - DrawEngineTests.TestFixtures：makeCard / makeDrawContext（引擎层用）
//  - 本文件 TestFixturesVM：makeModelContext / seededContext / scene+pool 工厂（VM 层用）
//
//  拆分原因：
//  - DrawEngine 是 Sendable + 无 SwiftData 依赖，所以不需要 ModelContext
//  - VM 是 @MainActor + 直接读写 SwiftData，所以需要 ModelContext
//  - 两个测试层级的 fixture 诉求不同，合并反而难维护
//
//  使用前提：Test Target 已配置（Tests/UnitTests/README.md 步骤 1-10）
//

import XCTest
import SwiftData
@testable import xiangsha

/// VM 层测试夹具（与 DrawEngineTests 末尾的私有 TestFixtures 互补）
enum TestFixturesVM {

    // MARK: - ModelContext

    /// 创建 in-memory ModelContext（VM 测试专用）
    ///
    /// 使用 v1.3 schema（与 App 实际部署版本对齐，xiangshaSchemaV1_3）
    /// in-memory 模式：每个测试独立容器，测试结束自动清理，无副作用。
    ///
    /// **注意**：首次调用会触发 SwiftData 容器初始化（微秒级），无明显性能开销。
    static func makeModelContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: xiangshaSchemaV1_3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: xiangshaSchemaV1_3.self,
            configurations: config
        )
        return ModelContext(container)
    }

    /// 创建并播种（seeded）的 ModelContext
    ///
    /// 一次性返回 context + scene + pool + N 张卡，所有对象已 modelContext.insert。
    /// 适用于需要"已加载数据"的 VM 测试（如 loadInitialData）。
    ///
    /// - Parameters:
    ///   - sceneType: 场景类型（默认 .eat）
    ///   - poolName: 卡池名（默认 "test-pool"）
    ///   - cardTitles: 卡标题列表（默认 2 张"测试A"/"测试B"）
    /// - Returns: (context, scene, pool, cards)
    static func makeSeededContext(
        sceneType: DecisionSceneType = .eat,
        poolName: String = "test-pool",
        cardTitles: [String] = ["测试A", "测试B"]
    ) throws -> (context: ModelContext, scene: DecisionScene, pool: CardPool, cards: [Card]) {
        let context = try makeModelContext()
        let scene = DecisionScene(type: sceneType, sortOrder: 0)
        let pool = CardPool(name: poolName, icon: "rectangle.stack", scene: scene)
        var cards: [Card] = []
        for title in cardTitles {
            let card = Card(
                title: title,
                scene: scene,
                pool: pool,
                emoji: "🍽️",
                category: "main"
            )
            cards.append(card)
        }
        context.insert(scene)
        context.insert(pool)
        for card in cards { context.insert(card) }
        try context.save()
        return (context, scene, pool, cards)
    }

    // MARK: - Scene / Pool / Card 工厂（无需 context）

    /// 创建决策场景（不插入 context，仅用于构造 DTO）
    static func makeScene(type: DecisionSceneType = .eat, sortOrder: Int = 0) -> DecisionScene {
        DecisionScene(type: type, sortOrder: sortOrder)
    }

    /// 创建卡池（不插入 context）
    static func makePool(name: String = "test-pool", scene: DecisionScene) -> CardPool {
        CardPool(name: name, icon: "rectangle.stack", scene: scene)
    }

    /// 创建用户画像快照（默认值）
    static func makeUserProfileSnapshot(
        allergens: [String] = [],
        drawsToday: Int = 0
    ) -> UserProfileSnapshot {
        UserProfileSnapshot(
            allergens: allergens,
            drawsToday: drawsToday
        )
    }

    /// 创建时间 of day mock（v1 默认从当前时间推断，测试需要固定时段时可注入 Calendar）
    static func fixedTimeOfDay(_ kind: TimeOfDay = .lunch) -> TimeOfDay { kind }
}
