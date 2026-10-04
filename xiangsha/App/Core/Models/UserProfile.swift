//
//  UserProfile.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 实体 #5 + D088（过敏原强制填）+ D133（每日重置）
//

import Foundation
import SwiftData

/// 用户画像实体（SPEC §10.1 实体 #5）
///
/// 全局唯一实例（D088 / D094 等强制至少 1 个）。
/// 承载：
/// - 过敏原（硬屏基础）
/// - 偏好风格（软调权）
/// - 每日抽签计数（D132 慢节奏上限）
/// - 上次抽签 / 重置日期（D132 慢节奏重置逻辑）
@Model
final class UserProfile {
    /// 用户画像唯一标识
    @Attribute(.unique) var id: UUID

    /// 过敏原列表（与 Card.allergens 求交集做硬屏 SPEC §A.2）
    ///
    /// D088：启动时强制勾选至少 1 项（包括「无」选项）。
    var allergens: [String]

    /// 偏好的餐次风格 / 玩啥风格 / 拍啥风格（软调权 SPEC §A.5）
    var preferredStyles: [String]

    /// 偏好分类（如「菜」「汤」「主粮」）
    var preferredCategories: [String]

    /// 偏好品牌（吃啥独立做品牌冷却）
    var preferredBrands: [String]

    /// 今日已抽次数（D132 慢节奏上限，跨午夜重置）
    var drawsToday: Int

    /// 上次抽签日期（用于检测跨天重置）
    var lastDrawDate: Date?

    /// 上次重置日期（用于冷启动重置判定）
    var lastResetDate: Date?

    /// 用户首启动时间
    var createdAt: Date

    /// 最近更新（设置变更时）
    var updatedAt: Date

    /// Debug 模式启用（D099 5-tap 解锁后开启）
    var debugModeEnabled: Bool

    init(
        allergens: [String] = [],
        preferredStyles: [String] = [],
        preferredCategories: [String] = [],
        preferredBrands: [String] = []
    ) {
        self.id = UUID()
        self.allergens = allergens
        self.preferredStyles = preferredStyles
        self.preferredCategories = preferredCategories
        self.preferredBrands = preferredBrands
        self.drawsToday = 0
        self.lastDrawDate = nil
        self.lastResetDate = nil
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.debugModeEnabled = false
    }

    /// 检查是否包含指定过敏原
    func hasAllergen(_ allergen: String) -> Bool {
        allergens.contains(allergen)
    }

    /// 检查是否含指定风格偏好
    func prefersStyle(_ style: String) -> Bool {
        preferredStyles.contains(style)
    }
}

// MARK: - 单例辅助（D088 全局唯一）

extension UserProfile {
    /// 全局「无过敏原」哨兵（用户明确表示"无"）
    static let noAllergenSentinel = "__none__"

    /// 检查用户是否明确选了「无过敏原」
    var hasNoAllergens: Bool {
        allergens.contains(UserProfile.noAllergenSentinel) || allergens.isEmpty
    }
}