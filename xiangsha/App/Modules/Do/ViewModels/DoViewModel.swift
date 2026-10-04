//
//  DoViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D064-D076（做啥）+ D076（完成庆祝）+ D134（不决策模式）
//

import Foundation
import SwiftUI

/// 模块 C · 做啥 ViewModel
@Observable
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

    init() {}

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

    func accept() {
        completedTasksToday += 1
        lastResult = nil
    }

    func reject() { lastResult = nil }

    func redraw() async { await draw() }

    func dismissError() { error = nil }

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