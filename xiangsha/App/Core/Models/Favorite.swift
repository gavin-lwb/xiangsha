//
//  Favorite.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 实体 #6 + D036（收藏权重）+ D019（收藏夹组织）
//

import Foundation
import SwiftData

/// 收藏实体（SPEC §10.1 实体 #6）
///
/// 用户对 Card 的收藏记录。一张 Card 可被收藏 1 次（uid = cardID 单字段索引）。
/// 收藏加权见 D036：min(1.2, 1.0 + 0.2/log(favoriteCount+1))，防收藏垄断。
@Model
final class Favorite {
    /// 收藏唯一标识
    @Attribute(.unique) var id: UUID

    /// 被收藏的卡片 ID（denormalized，给 #Index 用）
    @Attribute(.unique) var cardID: UUID

    /// 收藏时间
    var favoritedAt: Date

    /// 用户备注（可选）
    var noteText: String?

    /// 所属卡片（n → 1，cascade 删除：Card 删除则 Favorite 一起删）
    ///
    /// 通过 `@Relationship(deleteRule: .cascade, inverse: \Card.favorites)` 与 Card 配对。
    /// 待 Card.swift 写入后生效。
    var card: Card?

    init(card: Card, noteText: String? = nil) {
        self.id = UUID()
        self.cardID = card.id
        self.favoritedAt = Date()
        self.noteText = noteText
        self.card = card
    }

    /// 显示备注
    var displayNote: String {
        noteText?.isEmpty == false ? noteText! : "（无备注）"
    }
}