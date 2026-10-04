//
//  PhotoViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D077-D086（拍啥姿势）+ D082-D084（位置引导）
//

import Foundation
import SwiftUI

/// 模块 D · 拍啥 ViewModel
@Observable
final class PhotoViewModel {
    var engine: DrawEngine = RuleBasedEngine()
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

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

    var greetingText: String { "今天拍点啥？🦊" }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就拍这个 ✅" }
        return "抽一个姿势"
    }

    var showsSecondaryActions: Bool { lastResult != nil }
}