//
//  AchievementService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D097（成就系统 v1 上线 3 个）
//

import Foundation
import SwiftData

/// D097 成就系统（v1 上线 3 个）
///
/// v1 三个成就（按 SPEC §6.4 / fox-persona §12.1）：
/// - 首次抽签
/// - 首次完成做啥
/// - 首次收藏
///
/// v1.1+ 5 个（视觉成长放 v1.1）
@MainActor
enum AchievementService {
    /// 检查并返回新解锁的成就（已自动写入 UserProfile.earnedAchievements）
    ///
    /// 调用时机：
    /// - EatViewModel.accept() 后
    /// - EatViewModel.toggleFavorite() 后（首次收藏）
    /// - DoViewModel.accept() 后（首次完成做啥）
    static func checkAndUnlock(
        context: ModelContext,
        profile: UserProfile
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        let already = Set(profile.earnedAchievements)

        for achievement in Achievement.v1Achievements where !already.contains(achievement.id) {
            if achievement.isUnlocked(context: context) {
                unlocked.append(achievement)
            }
        }

        if !unlocked.isEmpty {
            profile.earnedAchievements.append(contentsOf: unlocked.map(\.id))
            profile.updatedAt = Date()
            try? context.save()
        }

        return unlocked
    }

    /// 查询已解锁的所有成就
    static func earnedAchievements(profile: UserProfile) -> [Achievement] {
        let earnedIDs = Set(profile.earnedAchievements)
        return Achievement.v1Achievements.filter { earnedIDs.contains($0.id) }
    }
}

/// 成就定义（D097）
enum Achievement: String, CaseIterable, Identifiable {
    /// 首次抽签
    case firstDraw = "firstDraw"
    /// 首次完成做啥
    case firstTaskComplete = "firstTaskComplete"
    /// 首次收藏
    case firstFavorite = "firstFavorite"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDraw: return "首次抽签"
        case .firstTaskComplete: return "首次完成做啥"
        case .firstFavorite: return "首次收藏"
        }
    }

    /// 🦊 解锁文案（fox-persona §12.1）
    var unlockText: String {
        switch self {
        case .firstDraw: return "🦊 第一次见面，请多关照"
        case .firstTaskComplete: return "迈出了第一步，不错嘛"
        case .firstFavorite: return "这张进了你的心头好名单"
        }
    }

    var icon: String {
        switch self {
        case .firstDraw: return "sparkles"
        case .firstTaskComplete: return "checkmark.seal.fill"
        case .firstFavorite: return "heart.fill"
        }
    }

    /// 是否已解锁（基于现有数据）
    func isUnlocked(context: ModelContext) -> Bool {
        switch self {
        case .firstDraw:
            // 任意 DrawRecord 存在
            let count = (try? context.fetchCount(FetchDescriptor<DrawRecord>())) ?? 0
            return count >= 1
        case .firstTaskComplete:
            // 任意 UserTaskRecord.status = completed 存在
            let count = (try? context.fetchCount(FetchDescriptor<UserTaskRecord>(
                predicate: #Predicate { $0.statusRaw == "completed" }
            ))) ?? 0
            return count >= 1
        case .firstFavorite:
            // 任意 Favorite 存在
            let count = (try? context.fetchCount(FetchDescriptor<Favorite>())) ?? 0
            return count >= 1
        }
    }

    /// v1 上线的 3 个成就
    static let v1Achievements: [Achievement] = [
        .firstDraw,
        .firstTaskComplete,
        .firstFavorite
    ]
}