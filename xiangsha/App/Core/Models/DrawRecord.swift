//
//  DrawRecord.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 实体 #4 + D020-D024（历史）+ D007（兜底）+ D134（不决策模式）
//

import Foundation
import SwiftData

/// 抽签历史记录实体（SPEC §10.1 实体 #4）
///
/// 每次抽签 / 用户对抽签结果的动作都记一条。**保留最近 1000 条滚动**（SPEC §10.6 / §14.4）。
///
/// 关系：
/// - `card`：n → 1 Card（`.nullify`：Card 删除则记录保留为历史档案，仅 card 引用置空）
@Model
final class DrawRecord {
    /// 记录唯一标识
    @Attribute(.unique) var id: UUID

    /// 被抽卡片 ID（denormalized，给 #Index 用）
    var cardID: UUID

    /// 场景 ID（denormalized，给跨场景统计 / D097 成就用）
    var sceneID: UUID

    /// 抽签时间（按时间排序索引 §10.4）
    var createdAt: Date

    /// 用户对抽签结果采取的动作（accept / reject / redraw / skip）
    var actionRaw: String

    /// D135 3 emoji 评分（😋/😐/🙅），可空
    var emojiRating: String?

    /// 抽签结果分析：候选前的卡池总数
    var candidatesBeforeFilter: Int

    /// 抽签结果分析：硬屏过滤后剩余候选
    var candidatesAfterFilter: Int

    /// 是否触发兜底
    var fallbackUsed: Bool

    /// 兜底等级（L1 / L2；D007 已删 L3）
    var fallbackLevelRaw: String?

    /// 抽签时段（breakfast / lunch / ...；D137 天气感知相关）
    var timeOfDayRaw: String?

    /// 抽签当天的累计次数（D132 慢节奏）
    var drawsTodayAtTime: Int

    /// 所属卡片（n → 1，`.nullify` 删除保留历史）
    ///
    /// 待 Card.swift 写入后生效（Card 已写入 ✓）。
    var card: Card?

    init(
        card: Card,
        action: DrawAction,
        candidatesBeforeFilter: Int,
        candidatesAfterFilter: Int,
        fallbackUsed: Bool = false,
        fallbackLevel: FallbackLevel? = nil,
        timeOfDay: TimeOfDay? = nil,
        drawsTodayAtTime: Int = 0,
        emojiRating: EmojiRating? = nil
    ) {
        self.id = UUID()
        self.cardID = card.id
        self.sceneID = card.scene?.id ?? UUID()
        self.createdAt = Date()
        self.actionRaw = action.rawValue
        self.emojiRating = emojiRating?.rawValue
        self.candidatesBeforeFilter = candidatesBeforeFilter
        self.candidatesAfterFilter = candidatesAfterFilter
        self.fallbackUsed = fallbackUsed
        self.fallbackLevelRaw = fallbackLevel?.rawValue
        self.timeOfDayRaw = timeOfDay?.rawValue
        self.drawsTodayAtTime = drawsTodayAtTime
        self.card = card
    }

    /// 计算属性：强类型动作
    var action: DrawAction {
        DrawAction(rawValue: actionRaw) ?? .redraw
    }

    /// 计算属性：强类型 emoji 评分
    var rating: EmojiRating? {
        emojiRating.flatMap(EmojiRating.init(rawValue:))
    }

    /// 计算属性：强类型兜底等级
    var fallbackLevel: FallbackLevel? {
        fallbackLevelRaw.flatMap(FallbackLevel.init(rawValue:))
    }

    /// 计算属性：强类型时段
    var timeOfDay: TimeOfDay? {
        timeOfDayRaw.flatMap(TimeOfDay.init(rawValue:))
    }
}

/// D135 3 emoji 评分枚举
enum EmojiRating: String, CaseIterable, Codable {
    /// 😋 喜欢（×1.5 加权）
    case like = "😋"
    /// 😐 一般（×1.0 无加权）
    case neutral = "😐"
    /// 🙅 不喜欢（×0.3 + dislike flag → 7d 内不再抽）
    case dislike = "🙅"

    /// 评分对应的引擎权重乘数
    var engineWeightMultiplier: Double {
        switch self {
        case .like: return 1.5
        case .neutral: return 1.0
        case .dislike: return 0.3
        }
    }

    /// 🦊 反馈文案（fox-persona §7.2）
    var feedbackText: String {
        switch self {
        case .like: return "记下来啦，下次多给你推 😋"
        case .neutral: return "收到，继续找找你的心头好"
        case .dislike: return "抱歉，下次小狐狸多注意"
        }
    }
}

/// 抽签动作枚举（D035 + D134 + D024）
///
/// 用户对抽签结果的反应。`redraw` 不入库（用户没决定），其余三个入库。
enum DrawAction: String, CaseIterable, Codable {
    /// 主按钮「就这个了」→ 接受，决定按这张卡行动
    case accept

    /// 拒绝（D025 拒绝处理）→ 用户明确表示不要
    case reject

    /// 换一签（D006 4h 冷却）→ 重新抽
    case redraw

    /// 跳过（D134 不决策模式）→ 放弃抽签
    case skip

    var title: String {
        switch self {
        case .accept: return "接受"
        case .reject: return "拒绝"
        case .redraw: return "换一签"
        case .skip: return "跳过"
        }
    }

    /// 是否入库（redraw 不入库）
    var isPersistent: Bool {
        self != .redraw
    }

    /// 🦊 反馈文案（fox-persona.md §5）
    var feedbackText: String {
        switch self {
        case .accept: return "🦊 记下来啦"
        case .reject: return "👌 不想就不想呗"
        case .redraw: return "再来一个？"
        case .skip: return "今天歇歇也行"
        }
    }
}