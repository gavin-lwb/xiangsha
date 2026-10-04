//
//  DecisionScene.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D004（DecisionScene 单独建模）+ SPEC §10.1（数据架构）
//

import Foundation
import SwiftData

/// 决策场景根实体（D004）
///
/// 4 个场景隔离：吃啥 / 玩啥 / 做啥 / 拍啥。每个 DecisionScene 下挂多个 CardPool，
/// 跨场景数据物理隔离，避免抽签串味。
///
/// 命名说明：原 SPEC §10.1 / D004 名为 `Scene`，但与 `SwiftUI.Scene` 协议冲突，
/// 故改为 `DecisionScene`（领域前缀）。SwiftData @Model 表名同步改为 `DecisionScene`。
/// 关系占位：DecisionScene → CardPool 的 `.cascade` 级联将在 CardPool.swift 中双向声明（SPEC §10.3）。
@Model
final class DecisionScene {
    /// 场景唯一标识
    @Attribute(.unique) var id: UUID

    /// 场景类型原始值（与 DecisionSceneType.rawValue 对应）
    var typeRaw: String

    /// 场景显示标题（zh-CN）
    var title: String

    /// 场景图标 SF Symbol 名称
    var icon: String

    /// 创建时间（DEBUG / 数据迁移用）
    var createdAt: Date

    /// 显示排序权重（数值越小越靠前；Tab 顺序由其决定）
    var sortOrder: Int

    /// 该场景下的卡池列表（1 → n CardPool）
    ///
    /// - 级联策略：`.cascade` — 场景删除时，所有 CardPool 一起删（SPEC §10.3）
    /// - 关系由 SwiftData 自动推断双向，无需在 CardPool 显式声明 inverse
    @Relationship(deleteRule: .cascade)
    var cardPools: [CardPool] = []

    init(type: DecisionSceneType, sortOrder: Int = 0) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.title = type.title
        self.icon = type.icon
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    /// 计算属性：转换 rawValue 为强类型枚举
    var type: DecisionSceneType {
        DecisionSceneType(rawValue: typeRaw) ?? .eat
    }
}

// 注：CardPool 类型在 CardPool.swift 中定义，SwiftData 双向关系由框架在编译期自动处理。

/// 决策场景类型（D004 + SPEC §10.1）
///
/// v1 上线 4 个；v1.1+ 评估新增（"喝啥" v1.3 否决、"宠物/礼物/旅行" v2 评估）。
enum DecisionSceneType: String, CaseIterable, Identifiable {
    /// 吃啥
    case eat
    /// 玩啥（v1.3 点子库）
    case play
    /// 做啥
    case task
    /// 拍啥
    case photo

    var id: String { rawValue }

    /// zh-CN 显示名（用于 Tab / 卡片标题）
    var title: String {
        switch self {
        case .eat: return "吃啥"
        case .play: return "玩啥"
        case .task: return "做啥"
        case .photo: return "拍啥"
        }
    }

    /// SF Symbol 图标
    var icon: String {
        switch self {
        case .eat: return "fork.knife"
        case .play: return "gamecontroller.fill"
        case .task: return "checkmark.circle.fill"
        case .photo: return "camera.fill"
        }
    }

    /// v1 默认 Tab 顺序（与 02-AGENTS §A.2 模块顺序一致）
    var defaultSortOrder: Int {
        switch self {
        case .eat: return 0
        case .play: return 1
        case .task: return 2
        case .photo: return 3
        }
    }

    /// v1 上线的 4 个场景（顺序 = Tab 顺序）
    static let v1Scenes: [DecisionSceneType] = [.eat, .play, .task, .photo]
}