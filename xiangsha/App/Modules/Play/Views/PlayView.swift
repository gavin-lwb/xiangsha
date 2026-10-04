//
//  PlayView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 B · 玩啥 Tab（占位骨架，待 M3 实现）
//

import SwiftUI

/// 模块 B · 玩啥 Tab 根视图（v1.3 决策：玩啥·点子库）
///
/// v1 占位（M3 占位骨架）：仅显示场景标题 + 🦊 欢迎文案 + 占位按钮。
struct PlayView: View {
    var body: some View {
        NavigationStack {
            PlaceholderTabView(sceneType: .play)
        }
    }
}

#Preview {
    PlayView()
}