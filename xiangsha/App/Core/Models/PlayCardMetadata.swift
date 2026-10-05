//
//  PlayCardMetadata.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D061（费用字段 · 免费/付费）+ 玩啥专属 metadata
//

import Foundation

/// 费用档（D061 · Free / Low / High）
///
/// - `free`：免费（如散步、看电影、读一本书）
/// - `low`：低费用 < ¥50（如桌游、羽毛球、野餐）
/// - `high`：高费用 > ¥50（如滑雪、密室逃脱、露营）
enum CostLevel: String, Codable, CaseIterable {
    case free
    case low
    case high

    var title: String {
        switch self {
        case .free: return "免费"
        case .low: return "低费"
        case .high: return "高费"
        }
    }

    /// UI 图标（D061 · 💚 / 💛 / ❤️）
    var emoji: String {
        switch self {
        case .free: return "💚"
        case .low: return "💛"
        case .high: return "❤️"
        }
    }
}
