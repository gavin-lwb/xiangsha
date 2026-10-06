//
//  DrawEngine.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D004-D015（抽签引擎）+ D005（两段衰减）+ D007（两级兜底）+ SPEC §10 + §A
//

import Foundation

// MARK: - 枚举（无外部依赖）

/// 时段（SPEC §A.1 DrawContext.timeOfDay）
enum TimeOfDay: String, CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case tea
    case dinner
    case latenight

    var id: String { rawValue }

    /// 中文显示名
    var title: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .tea: return "下午茶"
        case .dinner: return "晚餐"
        case .latenight: return "夜宵"
        }
    }

    /// 根据当前时间推断时段
    /// - 5-10: 早餐 / 11-13: 午餐 / 14-17: 下午茶 / 17-21: 晚餐 / 21-5: 夜宵
    static func from(date: Date = Date(), calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<14: return .lunch
        case 14..<17: return .tea
        case 17..<21: return .dinner
        default: return .latenight
        }
    }
}

/// 抽签模式（SPEC §A.1 DrawContext.mode）
enum DrawMode: String, Codable {
    /// 正常（多维平衡）
    case normal
    /// 新鲜（鼓励尝鲜，弱化收藏加权）
    case fresh
    /// 宽松（弱化冷却）
    case lenient
}

/// 兜底等级（SPEC §A.7）
///
/// v1.3 删 L3（D007）：候选 ≥ 1 但全部冷却时不再偷偷破冷却，改为提示换卡。
enum FallbackLevel: String, Codable {
    /// L1：完全候选为 0（硬屏全排除）→ Banner「歇够了？加点新内容吧」
    case l1Empty
    /// L2：仅警告级（过敏命中）→ 「⚠️ 含过敏原，确认接受？」
    case l2Allergen
    /// v1.3 已删：原 L3「想破冷却就破冷却」被 D007 否决
    @available(*, unavailable, message: "L3 已删除（D007）")
    case l3Cooldown
}

// MARK: - 配置（SPEC §A.8 调参接口）

/// 抽签引擎配置（SPEC §A.8）
///
/// 集中管理所有可调参数。RuleBasedEngine 实例化时注入，方便 A/B 测试与单元测试。
struct DrawEngineConfig {
    /// 硬屏：单卡冷却时长（4h）
    var singleCooldown: TimeInterval = 4 * 3600
    /// 硬屏：类别 24h 内最多几次（默认 2）
    var categoryMaxPer24h: Int = 2
    /// 硬屏：品牌 7d 内最多几次（默认 1）
    var brandMaxPer7d: Int = 1
    /// 硬屏：主料 24h 内最多几次（默认 1 → 允许出现 1 次，≥2 次才 ban）
    var mainIngredientMaxPer24h: Int = 1
    /// 软调权：收藏加权（×1.2 上限）
    var favoriteBoost: Double = 1.2
    /// 软调权：新卡加权（×1.3 上限）
    var newCardBoost: Double = 1.3
    /// 新卡窗口期（7 天内算新）
    var newCardWindowDays: Int = 7
    /// 软调权：历史降权（D005 两段衰减，base = 0.5）
    var historyDecayBase: Double = 0.5
    /// 软调权：餐次平衡启用
    var mealBalanceEnabled: Bool = true
    /// 软调权：风格轮换启用
    var styleRotationEnabled: Bool = true
    /// 硬屏：每天最多抽几次（D132 慢节奏）
    var drawsPerDayLimit: Int = 3
}

// MARK: - 调试因子记录

/// 单个软调权因子的应用记录（SPEC §A.1 FactorApplication）
///
/// 用于调试 / 决策反向解释 ❓（D.3 v1.1+），记录每个因子对每张候选卡的影响。
struct FactorApplication: Identifiable, Hashable {
    let id: UUID
    let factorName: String
    let cardID: UUID
    let multiplierBefore: Double
    let multiplierAfter: Double

    init(
        factorName: String,
        cardID: UUID,
        multiplierBefore: Double,
        multiplierAfter: Double
    ) {
        self.id = UUID()
        self.factorName = factorName
        self.cardID = cardID
        self.multiplierBefore = multiplierBefore
        self.multiplierAfter = multiplierAfter
    }
}

// MARK: - 快照类型（有意为之，非占位）

/// 用户画像快照
///
/// 承载 DrawEngine 计算所需的"实时用户状态"：
/// - 静态字段（来自 UserProfile）：allergens / preferredStyles / drawsToday 等
/// - 动态字段（来自 DrawRecord 历史聚合）：recentStyles7d / lastMealOfToday
///
/// 抽签时由调用方从 UserProfile + DrawRecord 历史聚合构造。
/// 解耦 SwiftData + 便于单元测试（无需持久化容器）。
struct UserProfileSnapshot: Sendable, Hashable {
    let allergens: [String]
    let recentStyles7d: [String]
    let userPreferredStyles: [String]
    let preferredCuisines: [Cuisine]
    let drawsToday: Int
    let lastMealOfToday: String?
    let preferredCategories: [String]
    let preferredBrands: [String]

    /// 24h 内各 category 抽中次数（用于类别硬上限 SPEC §A.2）
    let categoryCount24h: [String: Int]
    /// 7d 内各 brand 抽中次数（用于品牌硬上限）
    let brandCount7d: [String: Int]
    /// 24h 内各 mainIngredient 抽中次数（用于主料去重）
    let mainIngredientCount24h: [String: Int]
    /// 24h 内各 cardID 抽中次数（用于 D005 历史降权）
    let cardHistoryCount24h: [UUID: Int]

    init(
        allergens: [String] = [],
        recentStyles7d: [String] = [],
        userPreferredStyles: [String] = [],
        preferredCuisines: [Cuisine] = [],
        drawsToday: Int = 0,
        lastMealOfToday: String? = nil,
        preferredCategories: [String] = [],
        preferredBrands: [String] = [],
        categoryCount24h: [String: Int] = [:],
        brandCount7d: [String: Int] = [:],
        mainIngredientCount24h: [String: Int] = [:],
        cardHistoryCount24h: [UUID: Int] = [:]
    ) {
        self.allergens = allergens
        self.recentStyles7d = recentStyles7d
        self.userPreferredStyles = userPreferredStyles
        self.preferredCuisines = preferredCuisines
        self.drawsToday = drawsToday
        self.lastMealOfToday = lastMealOfToday
        self.preferredCategories = preferredCategories
        self.preferredBrands = preferredBrands
        self.categoryCount24h = categoryCount24h
        self.brandCount7d = brandCount7d
        self.mainIngredientCount24h = mainIngredientCount24h
        self.cardHistoryCount24h = cardHistoryCount24h
    }

    /// 从 UserProfile 实体 + 派生字段构造
    /// - Parameters:
    ///   - recentStyles7d: 7 天内抽过卡片的 style 集合
    ///   - lastMealOfToday: 今日最后一餐的 category
    ///   - historyAggregate: DrawRecord 历史聚合（计算来自外部）
    init(
        from profile: UserProfile,
        recentStyles7d: [String],
        lastMealOfToday: String?,
        historyAggregate: DrawHistoryAggregate = DrawHistoryAggregate()
    ) {
        self.allergens = profile.allergens
        self.recentStyles7d = recentStyles7d
        self.userPreferredStyles = profile.preferredStyles
        self.preferredCuisines = profile.preferredCuisines
        self.drawsToday = profile.drawsToday
        self.lastMealOfToday = lastMealOfToday
        self.preferredCategories = profile.preferredCategories
        self.preferredBrands = profile.preferredBrands
        self.categoryCount24h = historyAggregate.categoryCount24h
        self.brandCount7d = historyAggregate.brandCount7d
        self.mainIngredientCount24h = historyAggregate.mainIngredientCount24h
        self.cardHistoryCount24h = historyAggregate.cardHistoryCount24h
    }
}

/// DrawRecord 历史聚合（v1.1 加 DecisionJournalEntry 时可一并聚合）
///
/// 调用方从 SwiftData 查询 DrawRecord 后聚合得到此 struct，
/// 传入 DrawEngine 用于硬屏 / 软调权计算。
struct DrawHistoryAggregate: Sendable, Hashable {
    let categoryCount24h: [String: Int]
    let brandCount7d: [String: Int]
    let mainIngredientCount24h: [String: Int]
    let cardHistoryCount24h: [UUID: Int]
    let recentStyles7d: [String]
    let lastMealOfToday: String?

    init(
        categoryCount24h: [String: Int] = [:],
        brandCount7d: [String: Int] = [:],
        mainIngredientCount24h: [String: Int] = [:],
        cardHistoryCount24h: [UUID: Int] = [:],
        recentStyles7d: [String] = [],
        lastMealOfToday: String? = nil
    ) {
        self.categoryCount24h = categoryCount24h
        self.brandCount7d = brandCount7d
        self.mainIngredientCount24h = mainIngredientCount24h
        self.cardHistoryCount24h = cardHistoryCount24h
        self.recentStyles7d = recentStyles7d
        self.lastMealOfToday = lastMealOfToday
    }

    /// 空聚合（无历史记录时使用）
    static let empty = DrawHistoryAggregate()
}

/// 卡片引用（抽签结果中的卡片视图）
///
/// 与 v1.1 实体 CardSnapshot 区分：这是 v1 抽签引擎用的轻量值类型，
/// 只携带决策展示 + 兜底分析所需字段，不持久化。
///
/// 优点：
/// - 解耦 SwiftData：DrawEngine 单元测试无需 @Model container
/// - 跨场景传递更轻（无需携带 SwiftData 上下文）
/// - Hashable + Sendable 便于并发抽样
///
/// 抽签后调用方拿 id 自行查 SwiftData 上下文获取完整 Card。
struct DrawnCardRef: Sendable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let emoji: String?
    let sceneTypeRaw: String
    let category: String?
    let style: String?
    let brand: String?
    let mainIngredient: String?
    let isFavorite: Bool
    let createdAt: Date
    /// 是否有菜谱（D041/D044 · UI 用此判断「看菜谱」按钮是否显示）
    let hasRecipe: Bool

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String? = nil,
        sceneTypeRaw: String,
        category: String? = nil,
        style: String? = nil,
        brand: String? = nil,
        mainIngredient: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        hasRecipe: Bool = false
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.sceneTypeRaw = sceneTypeRaw
        self.category = category
        self.style = style
        self.brand = brand
        self.mainIngredient = mainIngredient
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.hasRecipe = hasRecipe
    }

    /// 从 Card 实体构造
    ///
    /// - Parameter isFavorite: 调用方传入（Favorite 查询结果，避免 DrawEngine 直接 SwiftData 查询）
    init(from card: Card, isFavorite: Bool) {
        self.id = card.id
        self.title = card.displayTitle
        self.emoji = card.emoji
        self.sceneTypeRaw = card.scene?.typeRaw ?? ""
        self.category = card.category
        // 注：Card 暂无 style 字段（吃啥用 category / 玩啥用 category 标签）；风格信息暂从 metadata 取
        self.style = card.metadata?["style"]
        self.brand = card.brand
        self.mainIngredient = card.metadata?["mainIngredient"]
        self.isFavorite = isFavorite
        self.createdAt = card.createdAt
        self.hasRecipe = card.recipe != nil
    }
}

// MARK: - 核心类型（SPEC §A.1）

/// 抽签上下文（SPEC §A.1 DrawContext）
struct DrawContext: Sendable {
    let pool: CardPool
    let userProfileSnapshot: UserProfileSnapshot
    let now: Date
    let timeOfDay: TimeOfDay
    let mode: DrawMode

    init(
        pool: CardPool,
        userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot(),
        now: Date = Date(),
        timeOfDay: TimeOfDay? = nil,
        mode: DrawMode = .normal
    ) {
        self.pool = pool
        self.userProfileSnapshot = userProfileSnapshot
        self.now = now
        self.timeOfDay = timeOfDay ?? TimeOfDay.from(date: now)
        self.mode = mode
    }
}

/// 抽签结果（SPEC §A.1 DrawResult）
struct DrawResult: Sendable {
    let card: DrawnCardRef
    let candidatesBeforeFilter: Int
    let candidatesAfterFilter: Int
    let appliedFactors: [FactorApplication]
    let fallbackUsed: Bool
    let fallbackLevel: FallbackLevel?
}

// MARK: - Protocol（SPEC §A.1）

/// 抽签引擎协议（SPEC §A.1 + 02-AGENTS §A.3 模块边界）
///
/// 模块间通过此协议调用抽签引擎，**禁止跨模块 import 内部实现**（如 RuleBasedEngine）。
/// 默认实现见 RuleBasedEngine（D005 / D007 全量上线）。
protocol DrawEngine: Sendable {
    func draw(context: DrawContext) async throws -> DrawResult
}

// MARK: - 错误

/// 抽签引擎错误
enum DrawEngineError: Error, LocalizedError {
    /// 实体未就绪（占位期间调用）
    case notImplemented
    /// 完全无候选（L1 兜底触发）
    case noCandidates(context: DrawContext)
    /// 上下文不合法（如 pool 为空）
    case invalidContext(reason: String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "抽签引擎尚未实现"
        case .noCandidates:
            return "没有符合条件的候选"
        case .invalidContext(let reason):
            return "上下文无效：\(reason)"
        }
    }
}

// MARK: - 默认实现（RuleBasedEngine）

/// 多维平衡抽签引擎（SPEC §A）
///
/// 完整实现以下算法：
/// - **硬屏**（SPEC §A.2）：过敏 / 单卡冷却 / 类别上限 / 品牌上限 / 主料去重 / 慢节奏上限 / 隐藏
/// - **软调权**（SPEC §A.3）：餐次平衡 / 风格轮换 / 收藏加权 / 新卡优先 / 时段因子 / 历史降权（D005 两段衰减）
/// - **加权抽样**（SPEC §A.6）
/// - **兜底**（SPEC §A.7 / D007）：L1（候选=0）/ L2（仅警告级）— L3 已删
///
/// 关联决策：D005（两段衰减）+ D007（两级兜底）+ D015（统一入口）+ §A.9 测试矩阵 T01-T15
struct RuleBasedEngine: DrawEngine {
    let config: DrawEngineConfig

    init(config: DrawEngineConfig = DrawEngineConfig()) {
        self.config = config
    }

    func draw(context: DrawContext) async throws -> DrawResult {
        let allCards = context.pool.cards
        let candidatesBeforeFilter = allCards.count

        // === 阶段 1：硬屏（SPEC §A.2）===
        let (hardPassed, hardFactors) = applyHardScreens(cards: allCards, context: context)
        let candidatesAfterFilter = hardPassed.count

        // L1 兜底：完全无候选（SPEC §A.7）
        guard candidatesAfterFilter > 0 else {
            throw DrawEngineError.noCandidates(context: context)
        }

        // === 阶段 2：软调权 + 加权抽样（SPEC §A.3-A.6）===
        let weighted = applySoftFactors(cards: hardPassed, context: context)

        // 仅取 (ref, weight) 给 weightedSampling
        let weightedPairs: [(DrawnCardRef, Double)] = weighted.map { ($0.0, $0.1) }
        guard let drawnRef = weightedSampling(weightedPairs) else {
            throw DrawEngineError.invalidContext(reason: "加权抽样失败")
        }
        // 用抽中的 ref 反查完整 tuple（含 factors）
        guard let drawn = weighted.first(where: { $0.0.id == drawnRef.id }) else {
            throw DrawEngineError.invalidContext(reason: "抽样结果索引失败")
        }

        // === 阶段 3：构造结果（SPEC §A.1 DrawResult）===
        let allFactors = hardFactors + drawn.2
        return DrawResult(
            card: drawn.0,
            candidatesBeforeFilter: candidatesBeforeFilter,
            candidatesAfterFilter: candidatesAfterFilter,
            appliedFactors: allFactors,
            fallbackUsed: false,
            fallbackLevel: nil
        )
    }

    // MARK: - 硬屏（SPEC §A.2）

    /// 应用 6 项硬屏，返回通过过滤的卡片 + 每个被排除卡的因子记录
    private func applyHardScreens(
        cards: [Card],
        context: DrawContext
    ) -> (passed: [Card], excludedFactors: [FactorApplication]) {
        var passed: [Card] = []
        var excludedFactors: [FactorApplication] = []
        let now = context.now
        let user = context.userProfileSnapshot
        let userAllergens = user.allergens
            .filter { $0 != UserProfile.noAllergenSentinel }

        for card in cards {
            var rejected: (name: String, multiplier: Double)?

            // T01 过敏硬屏
            if !userAllergens.isEmpty,
               !Set(card.allergens).isDisjoint(with: Set(userAllergens)) {
                rejected = ("allergenHardBlock", 0.0)
            }

            // 隐藏过滤（D016）
            if rejected == nil, card.isHidden {
                rejected = ("isHidden", 0.0)
            }

            // T02 单卡冷却（D006 4h）
            if rejected == nil,
               let until = card.excludeUntil,
               until > now {
                rejected = ("singleCardCooldown", 0.0)
            }

            // T15 慢节奏上限（D132 drawsPerDayLimit）
            if rejected == nil,
               user.drawsToday >= config.drawsPerDayLimit {
                rejected = ("drawsPerDayLimit", 0.0)
            }

            // T03 品牌冷却（D007 brandMaxPer7d）
            if rejected == nil,
               let brand = card.brand,
               user.brandCount7d[brand, default: 0] >= config.brandMaxPer7d {
                rejected = ("brandCooldown", 0.0)
            }

            // T04 类别上限（D007 categoryMaxPer24h）
            if rejected == nil,
               let category = card.category,
               user.categoryCount24h[category, default: 0] >= config.categoryMaxPer24h {
                rejected = ("categoryCooldown", 0.0)
            }

            // T05 主料去重（D007 mainIngredientMaxPer24h）
            if rejected == nil,
               let mainIngredient = card.metadata?["mainIngredient"],
               user.mainIngredientCount24h[mainIngredient, default: 0] >= config.mainIngredientMaxPer24h {
                rejected = ("mainIngredientRepeat", 0.0)
            }

            // T16 时段硬屏（D032 · availableTimes 不空且不含当前时段 → 排除）
            //
            // 「在家做」卡的 availableTimes 覆盖全部 5 个时段，永远通过；
            // 时段池的卡 availableTimes 为空（默认），所以也通过——表示"任何时段都能抽"。
            // 真正生效的是用户主动标 availableTimes 的卡（如"夜宵专属"卡不会被午餐抽到）。
            if rejected == nil,
               !card.availableTimes.isEmpty,
               !card.availableTimes.contains(context.timeOfDay) {
                rejected = ("timeOfDayMismatch", 0.0)
            }

            if let rejected {
                excludedFactors.append(FactorApplication(
                    factorName: rejected.name,
                    cardID: card.id,
                    multiplierBefore: 1.0,
                    multiplierAfter: rejected.multiplier
                ))
            } else {
                passed.append(card)
            }
        }

        return (passed, excludedFactors)
    }

    // MARK: - 软调权（SPEC §A.3）

    /// 应用 6 项软调权，返回 (DrawnCardRef, 最终权重, 因子记录) 列表
    private func applySoftFactors(
        cards: [Card],
        context: DrawContext
    ) -> [(DrawnCardRef, Double, [FactorApplication])] {
        let now = context.now
        let user = context.userProfileSnapshot

        return cards.map { card in
            var weight = card.weight
            var factors: [FactorApplication] = []

            // T06 餐次平衡（SPEC §A.4）
            if config.mealBalanceEnabled,
               let mealFactor = mealTimeFactor(card: card, context: context),
               mealFactor != 1.0 {
                let before = weight
                weight *= mealFactor
                factors.append(FactorApplication(
                    factorName: "mealTimeFactor",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            // T07 风格轮换（SPEC §A.5 · D051）
            if config.styleRotationEnabled,
               let style = card.metadata?["style"],
               let styleF = styleFactor(style: style, recentStyles: user.recentStyles7d, userPreferredStyles: user.userPreferredStyles),
               styleF != 1.0 {
                let before = weight
                weight *= styleF
                factors.append(FactorApplication(
                    factorName: "styleFactor",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            // T18 菜系软调权（D027 · cuisine 命中用户偏好 → ×1.3）
            if let cuisine = card.cuisine,
               user.preferredCuisines.contains(cuisine) {
                let cuisineBoost = 1.3
                let before = weight
                weight *= cuisineBoost
                factors.append(FactorApplication(
                    factorName: "cuisineBoost",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            // T08 收藏加权（D036）
            if let favStr = card.metadata?["favoriteCount"],
               let favCount = Int(favStr),
               favCount > 0 {
                let favBoost = min(config.favoriteBoost, 1.0 + 0.2 / log(Double(favCount) + 1))
                if favBoost != 1.0 {
                    let before = weight
                    weight *= favBoost
                    factors.append(FactorApplication(
                        factorName: "favoriteBoost",
                        cardID: card.id,
                        multiplierBefore: before,
                        multiplierAfter: weight
                    ))
                }
            }

            // T09 新卡优先
            let daysOld = now.timeIntervalSince(card.createdAt) / (24 * 3600)
            if daysOld < Double(config.newCardWindowDays), config.newCardBoost != 1.0 {
                let before = weight
                weight *= config.newCardBoost
                factors.append(FactorApplication(
                    factorName: "newCardBoost",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            // T10 历史降权（D005 两段衰减）
            let historyCount = user.cardHistoryCount24h[card.id, default: 0]
            let decayFactor = historyDecayMultiplier(count: historyCount)
            if decayFactor != 1.0 {
                let before = weight
                weight *= decayFactor
                factors.append(FactorApplication(
                    factorName: "historyDecay",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            // 时段因子（占位简化：未实现 per-pool 默认映射）
            // SPEC §A.3 时段因子：card.pool == defaultPool(timeOfDay) ? 1.0 : 0.5
            // 需要 CardPool.type 别名字段，v1.1 再加

            // T14 季节软调权（D048 · seasonWeights）
            //
            // 若 Card.seasonWeights 显式填了当前季节的权重（>0 且 ≠1），就应用。
            // 例：冬天吃火锅 ×1.5、夏天吃冰品 ×1.3。
            if let weights = card.seasonWeights,
               let seasonWeight = weights[Season.current(date: context.now)],
               seasonWeight != 1.0 {
                let before = weight
                weight *= seasonWeight
                factors.append(FactorApplication(
                    factorName: "seasonWeight",
                    cardID: card.id,
                    multiplierBefore: before,
                    multiplierAfter: weight
                ))
            }

            let ref = DrawnCardRef(from: card, isFavorite: false)
            return (ref, weight, factors)
        }
    }

    // MARK: - 餐次平衡（SPEC §A.4）

    private func mealTimeFactor(card: Card, context: DrawContext) -> Double? {
        guard [.lunch, .dinner].contains(context.timeOfDay) else { return 1.0 }
        guard let lastMeal = context.userProfileSnapshot.lastMealOfToday,
              let cardCategory = card.category else { return 1.0 }

        // SPEC §A.4 简化版（cardCategory 是 String；v1 用 category 字符串）
        switch (lastMeal, cardCategory) {
        case ("staple", "staple"): return 0.5
        case ("staple", "dish"):   return 1.2
        case ("staple", "soup"):   return 1.5
        case ("dish", "staple"):   return 1.0
        case ("dish", "dish"):     return 0.8
        case ("dish", "soup"):     return 1.3
        case ("soup", "staple"):   return 1.2
        case ("soup", "dish"):     return 1.0
        case ("soup", "soup"):     return 0.5
        default:                   return 1.0
        }
    }

    // MARK: - 风格轮换（SPEC §A.5 · D051）

    /// 风格软调权（D051）
    ///
    /// - 7d 内抽过该 style → ×0.7（避免连续推荐同一风格）
    /// - 用户偏好列表里有该 style → ×1.5（加强偏好）
    /// - 两边都没有 → 1.0（中性）
    /// - 同时命中 → 取较小值（recentStyles 0.7 优先，因为"最近吃过"比"曾经偏好"更强烈）
    private func styleFactor(style: String, recentStyles: [String], userPreferredStyles: [String]) -> Double? {
        if recentStyles.contains(style) {
            return 0.7
        }
        if userPreferredStyles.contains(style) {
            return 1.5
        }
        return 1.0
    }

    // MARK: - 历史降权（D005 两段衰减）

    /// D005 两段衰减：
    /// - t < 3: weight × 0.5^t
    /// - t ∈ [3, 7): weight × 0.125（平台期，避免心头好被永压）
    /// - t ≥ 7: weight = 0
    private func historyDecayMultiplier(count t: Int) -> Double {
        guard t > 0 else { return 1.0 }
        if t >= 7 { return 0.0 }
        if t >= 3 { return 0.125 }
        return pow(config.historyDecayBase, Double(t))
    }
}

// MARK: - 加权抽样（SPEC §A.6）

/// SPEC §A.6 加权抽样算法
///
/// - 输入：[(item, weight)]
/// - 输出：按权重随机抽样得到的 item
/// - 兜底：所有 weight = 0 时返回 randomElement（不抛错）
func weightedSampling<T>(_ items: [(T, Double)]) -> T? {
    let positiveItems = items.filter { $0.1 > 0 }
    guard !positiveItems.isEmpty else { return items.randomElement()?.0 }

    let total = positiveItems.map(\.1).reduce(0, +)
    var pick = Double.random(in: 0..<total)
    for (item, weight) in positiveItems {
        pick -= weight
        if pick <= 0 { return item }
    }
    return positiveItems.last?.0
}