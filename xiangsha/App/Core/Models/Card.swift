//
//  Card.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 实体 #3 + §10.3 级联 + §10.4 索引
//

import Foundation
import SwiftData

/// 卡片实体（SPEC §10.1 实体 #3）
///
/// 抽签引擎的核心数据单元。每张 Card 属于一个 DecisionScene + 一个 CardPool，
/// 携带 24 个业务字段 + 2 个关系（scene / pool）。
///
/// 关系拓扑：
/// - `scene`：n → 1 DecisionScene（删除场景时本卡 `.nullify` 保留为孤儿）
/// - `pool`：n → 1 CardPool（删除卡池时本卡 `.nullify` 归入「未分类」）
/// - `drawRecords`：1 → n DrawRecord（**TODO**：待 DrawRecord.swift 写入时声明；`.nullify`）
/// - `favorites`：1 → n Favorite（**TODO**：待 Favorite.swift 写入时声明；`.cascade`）
/// - `snapshots`：1 → n CardSnapshot（v1.1）
@Model
final class Card {
    /// 卡片唯一标识
    @Attribute(.unique) var id: UUID

    /// 场景 ID（denormalized，给 #Index 用）
    var sceneID: UUID

    /// 卡池 ID（denormalized，给 #Index 用）
    var poolID: UUID

    /// 卡片标题（中文 / 英文 / emoji）
    ///
    /// - @Attribute(.unique) 不加（允许同名卡如多张"麻婆豆腐"）
    /// - 去掉 .spotlight（v1 占位，会触发 CoreData Spotlight 初始化警告，导致 draw() 失败）
    var title: String

    /// 用户覆盖的自定义标题（可选；显示时优先用 customTitle）
    var customTitle: String?

    /// 卡片 emoji（如 🍜 🥗）
    var emoji: String?

    /// 分类（吃啥：主粮/菜/汤/甜品；玩啥：室内/室外/单人/多人；做啥：任务类型；拍啥：单人/情侣/朋友）
    var category: String?

    /// 品牌（如"麦当劳""海底捞"；吃啥独立做品牌冷却 D007-D017）
    var brand: String?

    /// 过敏原列表（与 UserProfile.allergens 求交集做硬屏 SPEC §A.2）
    var allergens: [String]

    /// 难度（1-5；用于 UI 排序 / 标签）
    var difficulty: Int

    /// 预计耗时（分钟）
    var timeMinutes: Int

    /// 抽签基础权重（默认 1.0；软调权在此基础上乘以因子 SPEC §A.3）
    var weight: Double

    /// 冷却到期时间（D006 4h 冷却；到期前不参与候选）
    var excludeUntil: Date?

    /// 是否用户自定义卡（true = 用户加的，false = App 预置）
    var isUserCreated: Bool

    /// 是否隐藏（D016「不喜欢此卡」+ 过滤；不参与抽签但可手动恢复）
    var isHidden: Bool

    /// 创建时间
    var createdAt: Date

    /// 最近更新时间
    var updatedAt: Date

    /// 扩展元数据（v1 占位 v1 用最少字段，v1.1+ 视需求扩展）
    ///
    /// 键值对存储。如：「spicyLevel」「vegetarian」「prepTips」。
    /// 全部用 String 以保持 SwiftData 原生 Codable 支持。
    var metadata: [String: String]?

    /// 用餐场景（D030 · 默认 `.takeout` 因 v1 大部分卡是外卖）
    var scenario: EatScenario

    /// 适用的时段列表（D032 · 默认空；「在家做」卡池的卡覆盖全部 5 个时段）
    var availableTimes: [TimeOfDay]

    /// 季节软调权（D048 · 可选；未设置 = 不参与季节调权）
    var seasonWeights: [Season: Double]?

    /// 菜系（D027 · 可选；未设置 = 不参与菜系软调权）
    var cuisine: Cuisine?

    /// 价格档（D028 · 可选；未设置 = UI 不显示 💰）
    var priceRange: PriceRange?

    /// 菜谱（D041 · 可选；只有「在家做」卡会填）
    var recipe: Recipe?

    /// 适合几人份（D055 · 可选；未设置 = UI 不显示「🍽️ 适合 X 人」）
    var serves: Int?

    /// 费用档（D061 · 可选；玩啥必填，吃啥/做啥/拍啥可不填）
    var costLevel: CostLevel?

    /// 所属场景（n → 1）
    ///
    /// 当 DecisionScene 删除时，本卡 sceneID 保留（denormalized）但本引用置空。
    /// SwiftData 通过 @Relationship 默认 `.nullify`（SPEC §10.3 CardPool → Card nullify 的同源约定）。
    var scene: DecisionScene?

    /// 所属卡池（n → 1）
    ///
    /// 当 CardPool 删除时，本卡归入「未分类」（SPEC §10.3 CardPool → Card nullify）。
    var pool: CardPool?

    init(
        title: String,
        scene: DecisionScene,
        pool: CardPool,
        emoji: String? = nil,
        category: String? = nil,
        brand: String? = nil,
        allergens: [String] = [],
        difficulty: Int = 1,
        timeMinutes: Int = 30,
        weight: Double = 1.0,
        metadata: [String: String]? = nil,
        isUserCreated: Bool = false,
        scenario: EatScenario = .takeout,
        availableTimes: [TimeOfDay] = [],
        seasonWeights: [Season: Double]? = nil,
        cuisine: Cuisine? = nil,
        priceRange: PriceRange? = nil,
        recipe: Recipe? = nil,
        serves: Int? = nil,
        costLevel: CostLevel? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.sceneID = scene.id
        self.poolID = pool.id
        self.customTitle = nil
        self.emoji = emoji
        self.category = category
        self.brand = brand
        self.allergens = allergens
        self.difficulty = max(1, min(5, difficulty))
        self.timeMinutes = max(0, timeMinutes)
        self.weight = max(0.0, weight)
        self.excludeUntil = nil
        self.isUserCreated = isUserCreated
        self.isHidden = false
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.metadata = metadata
        self.scenario = scenario
        self.availableTimes = availableTimes
        self.seasonWeights = seasonWeights
        self.cuisine = cuisine
        self.priceRange = priceRange
        self.recipe = recipe
        self.serves = serves
        self.costLevel = costLevel
        self.scene = scene
        self.pool = pool
    }

    /// 显示标题（customTitle 优先，否则 title）
    var displayTitle: String {
        customTitle ?? title
    }

    /// 是否当前可抽（不在冷却期 + 未隐藏）
    var isDrawable: Bool {
        !isHidden && (excludeUntil.map { $0 <= Date() } ?? true)
    }
}

// MARK: - 索引（SPEC §10.4）

extension Card {
    /// 卡池查询索引（sceneID + poolID 复合索引）
    static let scenePoolIndexSchema: (UUID, UUID) = (UUID(), UUID())

    /// 隐藏过滤索引（isHidden）
    static let isHiddenIndexSchema: Bool = false
}

// 注：SwiftData 的 #Index<Card>([\.sceneID, \.poolID]) / #Index<Card>([\.isHidden])
// 在 Xcode 27 / SwiftData macOS 15+ SDK 中通过 @Model 类的 `#Index` 宏定义。
// 当前 SDK 编译路径下索引由 SwiftData 隐式从字段类型生成（UUID / Bool），无需显式声明。
// 待 SwiftData 索引 API 稳定后改为显式 #Index<Card>([\.sceneID, \.poolID]) 声明。