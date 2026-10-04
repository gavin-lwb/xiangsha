//
//  CardPool.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 + §10.3（CardPool 实体与级联策略）
//

import Foundation
import SwiftData

/// 卡池实体（SPEC §10.1 实体 #2）
///
/// 一个 CardPool 属于一个 DecisionScene，包含多张 Card。
/// 例：吃啥 Scene 下分「川菜 / 粤菜 / 快手菜 / 夜宵」等多个 CardPool。
///
/// 关系：
/// - `scene`：n → 1 DecisionScene（由 DecisionScene.cardPools 反向引用，cascade 删除）
/// - `cards`：1 → n Card（**TODO**：待 Card.swift 写入时声明；`.nullify` 级联）
@Model
final class CardPool {
    /// 卡池唯一标识
    @Attribute(.unique) var id: UUID

    /// 卡池名（如"川菜""夜宵""30 分钟内"）
    var name: String

    /// 卡池图标 SF Symbol 名称
    var icon: String

    /// 显示排序权重（数值越小越靠前）
    var sortOrder: Int

    /// 是否用户自定义卡池（false = App 内置预置）
    var isUserCreated: Bool

    /// 创建时间
    var createdAt: Date

    /// 所属场景（n → 1）
    ///
    /// 由 `DecisionScene.cardPools` 通过 SwiftData 自动配对。
    /// DecisionScene 删除时本卡池被 `.cascade` 一起删除（SPEC §10.3）。
    var scene: DecisionScene?

    init(
        name: String,
        icon: String = "rectangle.stack",
        sortOrder: Int = 0,
        isUserCreated: Bool = false,
        scene: DecisionScene? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isUserCreated = isUserCreated
        self.createdAt = Date()
        self.scene = scene
    }
}