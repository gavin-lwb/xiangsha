//
//  DoViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D064-D076（做啥）+ D076（完成庆祝）+ D097（firstTaskComplete）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 C · 做啥 ViewModel
@Observable
@MainActor
final class DoViewModel {
    var engine: DrawEngine = RuleBasedEngine()
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

    /// v1.1+ 接 UserTaskRecord
    var completedTasksToday: Int = 0

    /// D076 完成庆祝显示中
    var showingCelebration: Bool = false

    /// 注入 ModelContext
    var modelContext: ModelContext?

    init() {}

    /// 主动加载初始数据（替代 @Query 的异步时序问题）
    func loadInitialData(context: ModelContext) async {
        var scenes: [DecisionScene] = []
        for _ in 0..<20 {
            let sceneDescriptor = FetchDescriptor<DecisionScene>(
                predicate: #Predicate { $0.typeRaw == "task" }
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
            self.selectedPool = allPools.first { $0.scene?.id == sceneID }
        }
    }

    func selectPool(_ pool: CardPool) { selectedPool = pool }

    func draw() async {
        guard let pool = selectedPool ?? scene?.cardPools.first else {
            error = .invalidContext(reason: "无可用任务")
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }

        let context = DrawContext(pool: pool, userProfileSnapshot: userProfileSnapshot)
        do {
            lastResult = try await engine.draw(context: context)
        } catch let engineError as DrawEngineError {
            error = engineError
        } catch {
            self.error = .invalidContext(reason: error.localizedDescription)
        }
    }

    /// 接受（任务完成 D076）→ 写 UserTaskRecord(.completed) + DrawRecord
    func accept() {
        guard let result = lastResult, let modelContext else { return }
        let cardID = result.card.id

        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(cardDescriptor))?.first {
            // 写 UserTaskRecord（D076 任务完成状态）
            let taskRecord = UserTaskRecord(
                taskID: card.id,
                status: .completed,
                noteText: nil
            )
            taskRecord.taskID = card.id
            modelContext.insert(taskRecord)

            // 写 DrawRecord（与 Eat/Play 一致；统一历史聚合）
            let drawRecord = DrawRecord(
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
            modelContext.insert(drawRecord)
            try? modelContext.save()
        }

        completedTasksToday += 1
        showingCelebration = true
        lastResult = nil
    }

    func reject() {
        guard let result = lastResult, let modelContext else {
            lastResult = nil
            return
        }
        let cardID = result.card.id
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(cardDescriptor))?.first {
            let record = UserTaskRecord(taskID: card.id, status: .abandoned)
            record.taskID = card.id
            modelContext.insert(record)
            try? modelContext.save()
        }
        lastResult = nil
    }

    func redraw() async { await draw() }

    func dismissError() { error = nil }

    /// 关闭庆祝弹窗
    func dismissCelebration() {
        showingCelebration = false
    }

    var greetingText: String {
        "今天先做点啥？🦊"
    }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "做完了 ✅" }
        return "抽一个小任务"
    }

    var showsSecondaryActions: Bool { lastResult != nil }

    /// D076 完成庆祝文案
    var celebrationText: String {
        "你居然真的做了！🦊👏"
    }

    // MARK: - 用户自定义任务

    /// 用户新增一个微任务
    func createUserTaskCard(title: String, emoji: String, type: String) {
        guard let modelContext, let scene = self.scene, let pool = findOrCreateUserTaskPool(scene: scene) else { return }
        let card = Card(
            title: title,
            scene: scene,
            pool: pool,
            emoji: emoji,
            category: type,
            isUserCreated: true
        )
        modelContext.insert(card)
        try? modelContext.save()
    }

    /// 删除一个用户自定义任务
    func deleteUserTaskCard(_ card: Card) {
        guard let modelContext, card.isUserCreated else { return }
        modelContext.delete(card)
        try? modelContext.save()
    }

    private func findOrCreateUserTaskPool(scene: DecisionScene) -> CardPool? {
        guard let modelContext else { return nil }
        let sceneID = scene.id
        let allPools = (try? modelContext.fetch(FetchDescriptor<CardPool>())) ?? []
        let userPools = allPools.filter { $0.scene?.id == sceneID && $0.isUserCreated }
        if let existing = userPools.first(where: { $0.name == "我的任务" }) {
            return existing
        }
        let pool = CardPool(
            name: "我的任务",
            icon: "person.crop.circle.fill",
            sortOrder: 100,
            isUserCreated: true,
            scene: scene
        )
        modelContext.insert(pool)
        return pool
    }
}