//
//  UserCookedRecord.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D045（"我做过"进收藏 + D046 "已解锁 X/80" 进度）
//

import Foundation
import SwiftData

/// 「我做过」记录（D045 + D046）
///
/// 用户每完成一次「做完了」动作，就创建一条 UserCookedRecord。
/// 用于：
/// - 收藏（与 Favorite 并列）
/// - D046 「已解锁 X/80」进度统计
/// - 反查（按 cardID 聚合）
///
/// 设计取舍：不维护 Card.cookedRecords 关系（避免污染 Card 关系拓扑），
/// 用 cardID 字符串反查即可。
@Model
final class UserCookedRecord {
    /// 记录唯一标识
    @Attribute(.unique) var id: UUID

    /// 关联卡 ID（denormalized，给 #Index / 反查用）
    var cardID: UUID

    /// 烹饪完成时间
    var cookedAt: Date

    /// 备注（可选）
    var noteText: String?

    /// 用户自评 1-5（可选；与 EmojiRating 解耦，方便独立打分）
    var rating: Int?

    /// 创建时间
    var createdAt: Date

    /// 最近更新时间
    var updatedAt: Date

    init(
        card: Card,
        noteText: String? = nil,
        rating: Int? = nil,
        cookedAt: Date = Date()
    ) {
        self.id = UUID()
        self.cardID = card.id
        self.cookedAt = cookedAt
        self.noteText = noteText
        self.rating = rating.flatMap { v in (1...5).contains(v) ? v : nil }
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
