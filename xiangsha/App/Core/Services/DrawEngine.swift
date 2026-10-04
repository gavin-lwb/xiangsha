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
    /// 硬屏：主料 24h 内最多几次（默认 0 → 强制去重）
    var mainIngredientMaxPer24h: Int = 0
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

// MARK: - 占位类型（待实体完成后替换）

/// 用户画像快照（占位）
///
/// 当前为非持久化 struct，承载 DrawEngine 计算所需的用户字段。
/// UserProfile @Model 实体完成后，**直接替换为 UserProfile**（移除本占位）。
struct UserProfileSnapshot: Sendable, Hashable {
    let allergens: [String]
    let recentStyles7d: [String]
    let userPreferredStyles: [String]
    let drawsToday: Int
    let lastMealOfToday: String?
    let preferredCategories: [String]
    let preferredBrands: [String]

    init(
        allergens: [String] = [],
        recentStyles7d: [String] = [],
        userPreferredStyles: [String] = [],
        drawsToday: Int = 0,
        lastMealOfToday: String? = nil,
        preferredCategories: [String] = [],
        preferredBrands: [String] = []
    ) {
        self.allergens = allergens
        self.recentStyles7d = recentStyles7d
        self.userPreferredStyles = userPreferredStyles
        self.drawsToday = drawsToday
        self.lastMealOfToday = lastMealOfToday
        self.preferredCategories = preferredCategories
        self.preferredBrands = preferredBrands
    }
}

/// 卡片快照（占位，区别于 v1.1 实体 CardSnapshot）
///
/// v1 DrawEngine 抽签结果需要的最小字段集合。
/// Card @Model 实体完成后，**直接替换为 Card**（移除本占位）。
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
        createdAt: Date = Date()
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

// MARK: - 默认实现（Stub）

/// 多维平衡抽签引擎（Stub）
///
/// 当前为骨架，**未实现核心逻辑**。等 Card / UserProfile / DrawRecord 实体完成后，
/// 按 SPEC §A 附录 A.1-A.9 实现：
/// - 硬屏：过敏 / 单卡冷却 / 类别上限 / 品牌上限 / 主料去重 / 慢节奏上限
/// - 软调权：餐次平衡 / 风格轮换 / 收藏加权 / 新卡优先 / 时段因子 / 历史降权（D005 两段衰减）
/// - 加权抽样：按 SPEC §A.6
/// - 兜底：L1 / L2（D007 删 L3）
///
/// 关联决策：D005（两段衰减）+ D007（两级兜底）+ D015（统一入口）+ A.9（单元测试矩阵 T01-T15）
struct RuleBasedEngine: DrawEngine {
    let config: DrawEngineConfig

    init(config: DrawEngineConfig = DrawEngineConfig()) {
        self.config = config
    }

    func draw(context: DrawContext) async throws -> DrawResult {
        // TODO: 实现 SPEC §A 多维平衡算法
        // 步骤：
        //   1. 收集 pool.cards → 候选列表
        //   2. 应用硬屏（过敏 / 冷却 / 上限）→ candidatesAfterFilter
        //   3. 应用软调权（餐次 / 风格 / 收藏 / 新卡 / 时段 / 历史）→ 加权候选
        //   4. SPEC §A.6 加权抽样
        //   5. 兜底判断（空 / 警告）
        //   6. 构造 DrawResult + 记录 FactorApplication
        throw DrawEngineError.notImplemented
    }
}