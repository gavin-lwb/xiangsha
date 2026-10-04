//
//  EatViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D015（统一入口）+ D035（按钮三态）+ D088（过敏警告）+ D006（4h 冷却）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 A · 吃啥 ViewModel
@Observable
@MainActor
final class EatViewModel {
    // MARK: - UI 状态

    var engine: DrawEngine
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

    /// L2 过敏警告（D088）— 是否正在显示
    var showingAllergenWarning: Bool = false

    /// 当前抽到的卡片是否已收藏
    var isCurrentFavorite: Bool = false

    /// 注入 ModelContext（v1 简化：让 VM 直接写库）
    var modelContext: ModelContext?

    init(
        engine: DrawEngine = RuleBasedEngine(),
        scene: DecisionScene? = nil,
        selectedPool: CardPool? = nil,
        userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    ) {
        self.engine = engine
        self.scene = scene
        self.selectedPool = selectedPool
        self.userProfileSnapshot = userProfileSnapshot
    }

    // MARK: - 业务动作

    func selectPool(_ pool: CardPool) {
        selectedPool = pool
    }

    func draw() async {
        guard let pool = selectedPool ?? scene?.cardPools.first else {
            error = .invalidContext(reason: "无可用卡池")
            return
        }

        isLoading = true
        error = nil
        showingAllergenWarning = false
        defer { isLoading = false }

        let context = DrawContext(
            pool: pool,
            userProfileSnapshot: userProfileSnapshot
        )

        do {
            let result = try await engine.draw(context: context)
            lastResult = result
            // 检查 L2 过敏警告（fallbackLevel == .l2Allergen）
            if result.fallbackLevel == .l2Allergen {
                showingAllergenWarning = true
            }
            // 收藏状态查询
            updateFavoriteStatus()
        } catch let engineError as DrawEngineError {
            self.error = engineError
            handleFallback(engineError)
        } catch {
            self.error = .invalidContext(reason: error.localizedDescription)
        }
    }

    /// 接受结果（D035 "就这个了 ✅"）→ 写 DrawRecord
    func accept() {
        guard let result = lastResult, let modelContext else { return }
        recordDraw(result: result, action: .accept)
        // 清空字段
        clearCurrent()
    }

    /// 拒绝（D025 "换一个" / "不想要"）→ 写 DrawRecord + 设置 4h 冷却
    func reject() {
        guard let result = lastResult, let modelContext else { return }
        recordDraw(result: result, action: .reject)
        setExcludeUntil(cardID: result.card.id, hours: 4)
        clearCurrent()
    }

    /// 重抽（D006 "换一个 🔁"）→ 不写 DrawRecord（redraw.isPersistent = false）
    func redraw() async {
        await draw()
    }

    /// 切换收藏（⭐ 收藏按钮）
    func toggleFavorite() {
        guard let result = lastResult,
              let modelContext else { return }
        let cardID = result.card.id

        // 查询现有收藏
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            // 取消收藏
            modelContext.delete(existing)
        } else {
            // 加收藏（需要先查询 Card 实体）
            let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
            if let card = (try? modelContext.fetch(cardDescriptor))?.first {
                let fav = Favorite(card: card)
                modelContext.insert(fav)
            }
        }
        try? modelContext.save()
        updateFavoriteStatus()
    }

    /// 重置错误状态
    func dismissError() {
        error = nil
        showingAllergenWarning = false
    }

    // MARK: - 私有

    /// 兜底分类处理（D007）
    private func handleFallback(_ engineError: DrawEngineError) {
        // L1 兜底已在 draw() 中抛 noCandidates；这里只处理 invalidContext 等
    }

    /// 写 DrawRecord
    private func recordDraw(result: DrawResult, action: DrawAction) {
        guard let modelContext else { return }
        let cardID = result.card.id
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? modelContext.fetch(cardDescriptor))?.first else { return }

        let record = DrawRecord(
            card: card,
            action: action,
            candidatesBeforeFilter: result.candidatesBeforeFilter,
            candidatesAfterFilter: result.candidatesAfterFilter,
            fallbackUsed: result.fallbackUsed,
            fallbackLevel: result.fallbackLevel,
            timeOfDay: TimeOfDay.from(),
            drawsTodayAtTime: userProfileSnapshot.drawsToday
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    /// 设置卡片 4h 冷却（D006）
    private func setExcludeUntil(cardID: UUID, hours: Double) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? modelContext.fetch(descriptor))?.first else { return }
        card.excludeUntil = Date().addingTimeInterval(hours * 3600)
        card.updatedAt = Date()
        try? modelContext.save()
    }

    /// 查询当前抽到的卡是否已收藏
    private func updateFavoriteStatus() {
        guard let result = lastResult, let modelContext else {
            isCurrentFavorite = false
            return
        }
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        isCurrentFavorite = ((try? modelContext.fetch(descriptor))?.first) != nil
    }

    private func clearCurrent() {
        lastResult = nil
        isCurrentFavorite = false
        showingAllergenWarning = false
    }

    // MARK: - 派生显示属性

    var greetingText: String {
        guard let scene else { return "你好呀 🦊" }
        switch scene.type {
        case .eat: return "今天想去哪儿吃？🦊"
        case .play: return "今天想玩点啥？🦊"
        case .task: return "今天先做点啥？🦊"
        case .photo: return "今天拍点啥？🦊"
        }
    }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就这个了 ✅" }
        return "抽一个试试"
    }

    var showsSecondaryActions: Bool {
        lastResult != nil
    }
}