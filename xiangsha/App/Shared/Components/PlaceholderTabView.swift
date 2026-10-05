//
//  PlaceholderTabView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  共享组件 · 各 Tab 的占位骨架（M1-M4 期间统一使用）
//

import SwiftUI

/// 通用 Tab 占位视图（Shared/Components）
///
/// 4 个 Tab 早期共享此占位，避免每个模块重复样板代码。
/// 各自模块的 ViewModel + 真实 UI 落地后，本组件可在 Shared/Components 保留
/// 作为 EmptyState 模板。
struct PlaceholderTabView: View {
    let sceneType: DecisionSceneType

    /// 🦊 启动气泡文案（fox-persona.md §2.1）
    private var greetingText: String {
        switch sceneType {
        case .eat: return "今天想去哪儿吃？🦊"
        case .play: return "今天想玩点啥？🦊"
        case .task: return "今天先做点啥？🦊"
        case .photo: return "今天拍点啥？🦊"
        }
    }

    /// 🦊 占位按钮文案（fox-persona.md §2.1）
    private var buttonText: String {
        "抽一个试试"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: sceneType.icon)
                .font(.system(size: 72))
                .foregroundStyle(Color.theme.accent)
                .accessibilityHidden(true)

            Text(greetingText)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: {}) {
                Text(buttonText)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .accessibilityLabel("\(sceneType.title)：\(buttonText)")

            Text("v1.0 占位 · \(moduleType().title)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .navigationTitle(sceneType.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private func moduleType() -> DecisionSceneType { sceneType }
}

#Preview {
    NavigationStack {
        PlaceholderTabView(sceneType: .eat)
    }
}