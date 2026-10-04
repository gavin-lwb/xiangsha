//
//  PhotoViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D077-D086（拍啥姿势）+ D135（emoji 评分）+ D019（收藏）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 D · 拍啥 ViewModel
@Observable
@MainActor
final class PhotoViewModel {
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

    func selectPool(_ pool: CardPool) { selectedPool = pool }

    func draw() async {
        guard let pool = selectedPool ?? scene?.cardPools.first else {
            error = .invalidContext(reason: "无可用姿势")
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

    func accept() { lastResult = nil }
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

    var greetingText: String { "今天拍点啥？🦊" }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就拍这个 ✅" }
        return "抽一个姿势"
    }

    var showsSecondaryActions: Bool { lastResult != nil }
}