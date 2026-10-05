//
//  PlayViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D057-D063（玩啥·点子库）+ D135（D135 emoji 评分）+ D019（收藏）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 B · 玩啥 ViewModel（v1.3 决策：玩啥·点子库）
@Observable
@MainActor
final class PlayViewModel {
    var engine: DrawEngine = RuleBasedEngine()
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

    var currentRating: EmojiRating?
    var ratingFeedback: String?
    var isCurrentFavorite: Bool = false

    var modelContext: ModelContext?

    init() {}

    /// 主动加载初始数据（替代 @Query 的异步时序问题）
    func loadInitialData(context: ModelContext) async {
        var scenes: [DecisionScene] = []
        for _ in 0..<20 {
            let sceneDescriptor = FetchDescriptor<DecisionScene>(
                predicate: #Predicate { $0.typeRaw == "play" }
            )
            scenes = (try? context.fetch(sceneDescriptor)) ?? []
            if !scenes.isEmpty { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        self.scene = scenes.first

        if selectedPool == nil, let scene = self.scene {
            let sceneID = scene.id
            var allPools: [CardPool] = []
            for _ in 0..<20 {
                allPools = (try? context.fetch(FetchDescriptor<CardPool>())) ?? []
                if !allPools.isEmpty { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let scenePools = allPools.filter { $0.scene?.id == sceneID }
            // D059 · 按当前时段自动选 pool（午后偏室外，其余按名字包含匹配）
            let hour = Calendar.current.component(.hour, from: Date())
            let preferred: CardPool?
            if 14 <= hour && hour < 18 {
                preferred = scenePools.first { $0.name.contains("室外") } ?? scenePools.first
            } else {
                preferred = scenePools.first { $0.name.contains("室内") } ?? scenePools.first
            }
            self.selectedPool = preferred
        }
    }

    func selectPool(_ pool: CardPool) { selectedPool = pool }

    func draw() async {
        guard let pool = selectedPool ?? scene?.cardPools.first else {
            error = .invalidContext(reason: "无可用卡池")
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }

        let context = DrawContext(pool: pool, userProfileSnapshot: userProfileSnapshot)
        do {
            let result = try await engine.draw(context: context)
            lastResult = result
            updateFavoriteStatus()
        } catch let engineError as DrawEngineError {
            self.error = engineError
        } catch {
            self.error = .invalidContext(reason: error.localizedDescription)
        }
    }

    func accept() {
        guard let result = lastResult, let modelContext else { lastResult = nil; return }
        // 写 DrawRecord（与 Eat 模块一致；统计 + 历史聚合）
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(descriptor))?.first {
            let record = DrawRecord(
                card: card,
                action: .accept,
                candidatesBeforeFilter: result.candidatesBeforeFilter,
                candidatesAfterFilter: result.candidatesAfterFilter,
                fallbackUsed: result.fallbackUsed,
                fallbackLevel: result.fallbackLevel,
                timeOfDay: TimeOfDay.from(),
                drawsTodayAtTime: userProfileSnapshot.drawsToday,
                emojiRating: nil
            )
            modelContext.insert(record)
            try? modelContext.save()
        }
        lastResult = nil
    }
    func reject() {
        guard let result = lastResult, let modelContext else {
            lastResult = nil
            return
        }
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(descriptor))?.first {
            card.excludeUntil = Date().addingTimeInterval(4 * 3600)
            card.updatedAt = Date()
            try? modelContext.save()
        }
        lastResult = nil
    }

    func redraw() async { await draw() }

    func dismissError() { error = nil }

    func toggleFavorite() {
        guard let result = lastResult, let modelContext else { return }
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            modelContext.delete(existing)
        } else {
            let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
            if let card = (try? modelContext.fetch(cardDescriptor))?.first {
                let fav = Favorite(card: card)
                modelContext.insert(fav)
            }
        }
        try? modelContext.save()
        updateFavoriteStatus()
    }

    func rate(emoji: EmojiRating) {
        guard let result = lastResult, let modelContext else { return }
        currentRating = emoji
        ratingFeedback = emoji.feedbackText

        let cardID = result.card.id
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(descriptor))?.first {
            var meta = card.metadata ?? [:]
            let current = Double(meta["preferenceScore"] ?? "1.0") ?? 1.0
            let delta: Double = (emoji == .like) ? 0.3 : (emoji == .dislike ? -0.3 : 0)
            let newScore = max(0.1, min(2.0, current + delta))
            meta["preferenceScore"] = String(format: "%.2f", newScore)
            card.metadata = meta
            card.updatedAt = Date()

            if emoji == .dislike {
                card.excludeUntil = Date().addingTimeInterval(7 * 24 * 3600)
            }
            try? modelContext.save()
        }
    }

    func clearRatingFeedback() {
        ratingFeedback = nil
        currentRating = nil
    }

    private func updateFavoriteStatus() {
        guard let result = lastResult, let modelContext else {
            isCurrentFavorite = false
            return
        }
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        isCurrentFavorite = ((try? modelContext.fetch(descriptor))?.first) != nil
    }

    var greetingText: String { "今天想玩点啥？🦊" }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就这个了 ✅" }
        return "抽一个试试"
    }

    var showsSecondaryActions: Bool { lastResult != nil }
}