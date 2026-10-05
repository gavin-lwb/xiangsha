//
//  EatCardMetadata.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D027（菜系） + D028（价格档） + D030（用餐场景） + D041（菜谱） + D048（季节）
//

import Foundation

/// 用餐场景（D030 · HomeCook/Takeout/EatIn 三态）
///
/// - `homeCook`：在家做（卡来自「在家做」卡池）
/// - `takeout`：外卖（卡来自外卖店）
/// - `eatIn`：堂食（卡来自餐厅堂食）
enum EatScenario: String, Codable, CaseIterable {
    case homeCook
    case takeout
    case eatIn

    var title: String {
        switch self {
        case .homeCook: return "在家做"
        case .takeout: return "外卖"
        case .eatIn: return "堂食"
        }
    }
}

/// 菜系（D027）
enum Cuisine: String, Codable, CaseIterable {
    case sichuan   // 川
    case cantonese // 粤
    case huaiyang  // 淮
    case fujian    // 闽
    case zhejiang  // 浙
    case xiang     // 湘
    case lu        // 鲁
    case western   // 西
    case japanese  // 日
    case korean    // 韩
    case fusion
    case other

    var title: String {
        switch self {
        case .sichuan: return "川菜"
        case .cantonese: return "粤菜"
        case .huaiyang: return "淮扬菜"
        case .fujian: return "闽菜"
        case .zhejiang: return "浙菜"
        case .xiang: return "湘菜"
        case .lu: return "鲁菜"
        case .western: return "西餐"
        case .japanese: return "日料"
        case .korean: return "韩餐"
        case .fusion: return "Fusion"
        case .other: return "其他"
        }
    }
}

/// 价格档（D028 · budget/mid/premium）
enum PriceRange: String, Codable, CaseIterable {
    case budget   // <¥30
    case mid      // ¥30-100
    case premium  // >¥100

    var title: String {
        switch self {
        case .budget: return "经济"
        case .mid: return "中等"
        case .premium: return "偏高"
        }
    }

    /// UI 图标（D028 「💰 显示」）
    var icon: String { "yensign.circle.fill" }
}

/// 季节（D048 · 软调权因子）
enum Season: String, Codable, CaseIterable {
    case spring
    case summer
    case autumn
    case winter

    /// 根据当前日期推断季节
    static func current(date: Date = Date(), calendar: Calendar = .current) -> Season {
        let month = calendar.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

/// 菜谱（D041 · Recipe 嵌套在 Card.recipe）
///
/// `Recipe` 是 value type + Codable，可直接作为 SwiftData 属性持久化。
struct Recipe: Codable, Hashable {
    /// 食材清单（如 ["鸡腿 500g", "姜 3 片", "料酒 1 勺"]）
    var ingredients: [String]
    /// 步骤（按顺序）
    var steps: [String]
    /// 备料时间（分钟，可选）
    var prepTimeMinutes: Int?
    /// 烹饪时间（分钟，可选）
    var cookTimeMinutes: Int?
    /// 难度 1-5（可选）
    var difficulty: Int?

    init(
        ingredients: [String] = [],
        steps: [String] = [],
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        difficulty: Int? = nil
    ) {
        self.ingredients = ingredients
        self.steps = steps
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.difficulty = difficulty
    }
}
