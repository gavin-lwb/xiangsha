//
//  PlayViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D057-D063（玩啥·点子库）+ D134（不决策模式）
//

import Foundation
import SwiftUI

/// 模块 B · 玩啥 ViewModel
///
/// v1.3 决策：玩啥·点子库（30-50 张卡，4 卡池：室内单人/室外单人/室内多人/室外多人）
@Observable
final class PlayViewModel {
    var engine: DrawEngine = RuleBasedEngine()
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

    init() {}

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

    func accept() { lastResult = nil }
    func reject() { lastResult = nil }
    func redraw() async { await draw() }
    func dismissError() { error = nil }

    var greetingText: String {
        "今天想玩点啥？🦊"
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