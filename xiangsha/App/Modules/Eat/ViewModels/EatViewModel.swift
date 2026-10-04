//
//  EatViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D015（统一入口）+ D035（按钮三态）+ D088（过敏警告）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 A · 吃啥 ViewModel
///
/// iOS 17+ 原生 @Observable（02-AGENTS §A.5 状态管理）。
/// 不直接持有 SwiftData Context（02-AGENTS §A.7 反模式），
/// 通过 View 注入的快照数据计算。
@Observable
final class EatViewModel {
    // MARK: - UI 状态

    /// 抽签引擎
    var engine: DrawEngine

    /// 当前选中的场景
    var scene: DecisionScene?

    /// 候选卡池（用户可手动选；nil = 用第一个）
    var selectedPool: CardPool?

    /// 用户画像快照
    var userProfileSnapshot: UserProfileSnapshot

    /// 最近一次抽签结果
    var lastResult: DrawResult?

    /// 是否正在抽签（动画 loading 态）
    var isLoading: Bool = false

    /// 抽签错误（如 D088 过敏警告）
    var error: DrawEngineError?

    /// 是否显示过敏警告（D088 / L2 兜底）
    var showingAllergenWarning: Bool = false

    // MARK: - Init

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

    /// 选卡池
    func selectPool(_ pool: CardPool) {
        selectedPool = pool
    }

    /// 抽签（D035 主按钮 "抽一个试试"）
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
        } catch let engineError as DrawEngineError {
            self.error = engineError
            handleFallback(engineError)
        } catch {
            self.error = .invalidContext(reason: error.localizedDescription)
        }
    }

    /// 接受结果（D035 "就这个了 ✅"）
    func accept() {
        // v1 占位：v1.1+ 写 DecisionJournalEntry
        // 记录 DrawRecord（接受）
        lastResult = nil
    }

    /// 拒绝（D025 "换一个"）
    func reject() {
        // v1 占位：v1.1+ 设置 excludeUntil 4h
        // 记录 DrawRecord（拒绝）
        lastResult = nil
    }

    /// 重抽（D006 "换一个 🔁"）
    func redraw() async {
        // v1 实现：直接重新 draw（冷却逻辑在硬屏里处理）
        await draw()
    }

    /// 重置错误状态（用户清除警告）
    func dismissError() {
        error = nil
        showingAllergenWarning = false
    }

    // MARK: - 私有

    /// 兜底分类处理（D007）
    private func handleFallback(_ engineError: DrawEngineError) {
        switch engineError {
        case .noCandidates:
            // L1：候选=0，UI 显示"歇够了？加点新内容吧"
            break
        case .invalidContext:
            break
        case .notImplemented:
            break
        }
    }

    // MARK: - 派生显示属性

    /// 🦊 启动气泡文案（fox-persona.md §2.1）
    var greetingText: String {
        guard let scene else { return "你好呀 🦊" }
        switch scene.type {
        case .eat: return "今天想去哪儿吃？🦊"
        case .play: return "今天想玩点啥？🦊"
        case .task: return "今天先做点啥？🦊"
        case .photo: return "今天拍点啥？🦊"
        }
    }

    /// 主按钮文案
    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就这个了 ✅" }
        return "抽一个试试"
    }

    /// 次按钮是否显示（有结果时才显示）
    var showsSecondaryActions: Bool {
        lastResult != nil
    }
}