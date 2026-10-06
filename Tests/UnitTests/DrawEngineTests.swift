//
//  DrawEngineTests.swift
//  xiangshaTests
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §A.9 单元测试矩阵（T01-T15）
//
// 用 XCTest（无需外部依赖）覆盖 DrawEngine 核心算法。
// 当前随主 target 编译；运行需在 Xcode UI 添加 Test Target（Unit Testing Bundle）。
//

import XCTest
import Foundation
@testable import xiangsha

/// 抽签引擎单元测试（SPEC §A.9）
///
/// 覆盖：6 项硬屏 + 5 项软调权 + 加权抽样 + 兜底策略
final class DrawEngineTests: XCTestCase {

    // MARK: - T01 过敏硬屏

    func testT01AllergenHardBlock() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "麻婆豆腐", allergens: ["花生"]),
                TestFixtures.makeCard(title: "番茄炒蛋", allergens: [])
            ],
            userAllergens: ["花生"]
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "番茄炒蛋")
        XCTAssertTrue(result.appliedFactors.contains { $0.factorName == "allergenHardBlock" })
    }

    // MARK: - T02 单卡冷却

    func testT02SingleCardCooldown() async throws {
        let recent = TestFixtures.makeCard(title: "麻婆豆腐")
        recent.excludeUntil = Date().addingTimeInterval(2 * 3600) // 2h 后到期

        let context = TestFixtures.makeDrawContext(
            poolCards: [
                recent,
                TestFixtures.makeCard(title: "番茄炒蛋")
            ]
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "番茄炒蛋")
    }

    // MARK: - T03 品牌冷却

    func testT03BrandCooldown() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "麦当劳", brand: "麦当劳"),
                TestFixtures.makeCard(title: "肯德基", brand: "肯德基")
            ],
            brandCount7d: ["麦当劳": 1]
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "肯德基")
    }

    // MARK: - T04 类别冷却

    func testT04CategoryCooldown() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "川菜A", category: "川菜"),
                TestFixtures.makeCard(title: "粤菜", category: "粤菜")
            ],
            categoryCount24h: ["川菜": 2]
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "粤菜")
    }

    // MARK: - T05 主料去重

    func testT05MainIngredientDedup() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "鸡肉1", metadata: ["mainIngredient": "鸡肉"]),
                TestFixtures.makeCard(title: "鸡肉2", metadata: ["mainIngredient": "鸡肉"]),
                TestFixtures.makeCard(title: "鱼肉", metadata: ["mainIngredient": "鱼"])
            ],
            mainIngredientCount24h: ["鸡肉": 2]  // 已吃过 2 次 → 第三次起 ban
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "鱼肉")
    }

    // MARK: - T06 餐次平衡

    func testT06MealTimeFactor() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "主粮", category: "staple"),
                TestFixtures.makeCard(title: "汤", category: "soup")
            ],
            lastMeal: "staple",
            timeOfDay: .lunch
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertTrue(["主粮", "汤"].contains(result.card.title))
        XCTAssertTrue(result.appliedFactors.contains { $0.factorName == "mealTimeFactor" })
    }

    // MARK: - T07 风格轮换

    func testT07StyleFactor() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "川菜", metadata: ["style": "spicy"]),
                TestFixtures.makeCard(title: "粤菜", metadata: ["style": "light"])
            ],
            recentStyles: ["spicy"]
        )

        let engine = RuleBasedEngine()
        let result = try await engine.draw(context: context)

        XCTAssertEqual(result.card.title, "粤菜")
    }

    // MARK: - T08 收藏加权

    func testT08FavoriteBoost() async throws {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "收藏卡", metadata: ["favoriteCount": "1"]),
                TestFixtures.makeCard(title: "普通卡")
            ]
        )

        let engine = RuleBasedEngine()
        var favoritesCount = 0
        for _ in 0..<500 {
            let r = try await engine.draw(context: context)
            if r.card.title == "收藏卡" { favoritesCount += 1 }
        }
        // 1.2/(1.0+1.2)≈54.5% 期望，500 次期望 272.5；阈值设 250（留 22 次缓冲）
        XCTAssertGreaterThan(favoritesCount, 250)
    }

    // MARK: - T09 新卡优先

    func testT09NewCardBoost() async throws {
        let newCard = TestFixtures.makeCard(title: "新菜", createdAt: Date().addingTimeInterval(-1 * 86400))
        let oldCard = TestFixtures.makeCard(title: "老菜", createdAt: Date().addingTimeInterval(-30 * 86400))

        let context = TestFixtures.makeDrawContext(poolCards: [newCard, oldCard])

        let engine = RuleBasedEngine()
        var newCount = 0
        for _ in 0..<100 {
            let r = try await engine.draw(context: context)
            if r.card.title == "新菜" { newCount += 1 }
        }
        XCTAssertGreaterThan(newCount, 50)
    }

    // MARK: - T10 历史降权（D005 两段衰减）

    func testT10HistoryDecay() async throws {
        let oftenCard = TestFixtures.makeCard(title: "常吃")
        let rarelyCard = TestFixtures.makeCard(title: "偶尔吃")

        let context = TestFixtures.makeDrawContext(
            poolCards: [oftenCard, rarelyCard],
            cardHistoryCount24h: [oftenCard.id: 3]
        )

        let engine = RuleBasedEngine()
        var rarelyCount = 0
        for _ in 0..<100 {
            let r = try await engine.draw(context: context)
            if r.card.title == "偶尔吃" { rarelyCount += 1 }
        }
        XCTAssertGreaterThan(rarelyCount, 50)
    }

    // MARK: - T11 L1 兜底

    func testT11FallbackL1() async {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "麻婆豆腐", allergens: ["花生"])
            ],
            userAllergens: ["花生"]
        )

        let engine = RuleBasedEngine()
        do {
            _ = try await engine.draw(context: context)
            XCTFail("期望抛 noCandidates，但成功了")
        } catch DrawEngineError.noCandidates {
            // 期望
        } catch {
            XCTFail("期望 DrawEngineError.noContexts，得到 \(error)")
        }
    }

    // MARK: - T13 性能（1000 候选 < 50ms）

    func testT13Performance() async throws {
        var cards: [Card] = []
        for i in 0..<1000 {
            cards.append(TestFixtures.makeCard(title: "Card \(i)"))
        }
        let context = TestFixtures.makeDrawContext(poolCards: cards)

        let engine = RuleBasedEngine()
        let start = Date()
        _ = try await engine.draw(context: context)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.05, "性能应 < 50ms，实际为 \(elapsed * 1000)ms")
    }

    // MARK: - T14 加权抽样正确性

    func testT14WeightedSampling() {
        let items: [(Int, Double)] = [
            (1, 0.125),
            (2, 0.125),
            (3, 0.125),
            (4, 0.125),
            (5, 0.125),
            (6, 0.125),
            (7, 0.125),
            (8, 0.125)
        ]
        var counts: [Int: Int] = [:]
        let n = 10000
        for _ in 0..<n {
            if let picked = weightedSampling(items) {
                counts[picked, default: 0] += 1
            }
        }
        // 验证分布：每个值约 1/8 = 1250，±15%
        for i in 1...8 {
            let actual = counts[i] ?? 0
            let expected = Double(n) / 8.0
            XCTAssertEqual(Double(actual), expected, accuracy: expected * 0.15,
                           "值 \(i) 出现次数 \(actual) 偏离期望 \(expected)")
        }
    }

    // MARK: - T15 慢节奏上限

    func testT15DrawsPerDayLimit() async {
        let context = TestFixtures.makeDrawContext(
            poolCards: [
                TestFixtures.makeCard(title: "A"),
                TestFixtures.makeCard(title: "B")
            ],
            drawsToday: 3
        )

        let engine = RuleBasedEngine()
        do {
            _ = try await engine.draw(context: context)
            XCTFail("期望抛 noCandidates，但成功了")
        } catch DrawEngineError.noCandidates {
            // 期望
        } catch {
            XCTFail("期望 DrawEngineError.noCandidates，得到 \(error)")
        }
    }

    // MARK: - 私有夹具
}

/// 测试夹具（XCTest）
enum TestFixtures {
    /// 创建测试用 Card（关联到 stub scene + pool）
    static func makeCard(
        title: String,
        emoji: String? = nil,
        category: String? = nil,
        brand: String? = nil,
        allergens: [String] = [],
        difficulty: Int = 1,
        timeMinutes: Int = 30,
        metadata: [String: String]? = nil,
        createdAt: Date = Date()
    ) -> Card {
        let stubScene = DecisionScene(type: .eat, sortOrder: 0)
        let stubPool = CardPool(name: "stub-pool", icon: "i", scene: stubScene)
        let card = Card(
            title: title,
            scene: stubScene,
            pool: stubPool,
            emoji: emoji,
            category: category,
            brand: brand,
            allergens: allergens,
            difficulty: difficulty,
            timeMinutes: timeMinutes,
            metadata: metadata
        )
        card.createdAt = createdAt
        stubPool.cards.append(card)
        return card
    }

    /// 创建测试用 DrawContext
    static func makeDrawContext(
        poolCards: [Card],
        userAllergens: [String] = [],
        brandCount7d: [String: Int] = [:],
        categoryCount24h: [String: Int] = [:],
        mainIngredientCount24h: [String: Int] = [:],
        cardHistoryCount24h: [UUID: Int] = [:],
        recentStyles: [String] = [],
        lastMeal: String? = nil,
        drawsToday: Int = 0,
        timeOfDay: TimeOfDay = .lunch
    ) -> DrawContext {
        let pool = CardPool(name: "test-pool", icon: "test")
        pool.cards = poolCards

        let profile = UserProfileSnapshot(
            allergens: userAllergens,
            recentStyles7d: recentStyles,
            drawsToday: drawsToday,
            lastMealOfToday: lastMeal,
            categoryCount24h: categoryCount24h,
            brandCount7d: brandCount7d,
            mainIngredientCount24h: mainIngredientCount24h,
            cardHistoryCount24h: cardHistoryCount24h
        )

        return DrawContext(
            pool: pool,
            userProfileSnapshot: profile,
            now: Date(),
            timeOfDay: timeOfDay
        )
    }
}