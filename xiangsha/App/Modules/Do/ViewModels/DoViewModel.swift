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

    /// 接受（任务完成 D076）→ 写 UserTaskRecord(.completed)
    func accept() {
        guard let result = lastResult, let modelContext else { return }
        let cardID = result.card.id

        // 写 UserTaskRecord
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = (try? modelContext.fetch(cardDescriptor))?.first {
            let record = UserTaskRecord(
                taskID: card.id,
                status: .completed,
                noteText: nil
            )
            // taskID 用 Card UID（v1.1+ 用专用 TaskTemplate ID）
            record.taskID = card.id
            modelContext.insert(record)
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
}