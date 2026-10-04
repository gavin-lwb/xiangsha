//
//  CrossSceneLinkService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D121（v1 基础联动）+ fox-persona 81
//

import Foundation
import SwiftData

/// 跨场景联动服务（D121）
///
/// v1 基础联动（v1.1+ 才做完整 Routine 一键三抽）：
/// - 抽到结果后，从 1 个相关场景推荐 1 张卡
/// - banner 提示，点击切换到目标 Tab 并触发该场景抽签
///
/// 联动规则（v1 简化）：
/// - 吃啥 → 推荐玩啥（餐后活动）
/// - 玩啥 → 推荐拍啥（活动后留念）
/// - 做啥 → 推荐吃啥（工作后犒劳）
/// - 拍啥 → 推荐玩啥（已经出门就别待家里）
@MainActor
enum CrossSceneLinkService {
    /// 联动映射：当前场景 → 推荐目标场景
    static func recommendedTarget(for sourceScene: DecisionSceneType) -> DecisionSceneType? {
        switch sourceScene {
        case .eat: return .play      // 吃完饭玩点啥
        case .play: return .photo    // 玩完拍点啥
        case .task: return .eat      // 干完活吃点啥
        case .photo: return .play    // 拍完可以顺便玩
        }
    }

    /// 联动文案
    static func suggestionText(
        from source: DecisionSceneType,
        to target: DecisionSceneType,
        cardTitle: String
    ) -> String {
        switch (source, target) {
        case (.eat, .play): return "吃完\(cardTitle)，可以顺便："
        case (.eat, .photo): return "\(cardTitle) + 拍点啥"
        case (.play, .photo): return "玩完拍张照留念："
        case (.play, .eat): return "玩累了？吃个："
        case (.task, .eat): return "做完了！奖励自己："
        case (.task, .play): return "做完了休息一下："
        case (.photo, .play): return "拍完继续玩："
        case (.photo, .eat): return "拍饿了？吃个："
        default: return "也可以试试："
        }
    }

    /// 推荐卡片（从目标场景的第一个卡池随机抽 1 张）
    static func recommendCard(
        target: DecisionSceneType,
        context: ModelContext
    ) -> Card? {
        let targetRaw = target.rawValue
        let descriptor = FetchDescriptor<DecisionScene>(
            predicate: #Predicate { $0.typeRaw == targetRaw }
        )
        guard let targetScene = try? context.fetch(descriptor).first else { return nil }

        let cards = targetScene.cardPools.flatMap { $0.cards }.filter { !$0.isHidden }
        return cards.randomElement()
    }
}