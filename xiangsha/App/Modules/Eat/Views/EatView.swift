//
//  EatView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 A · 吃啥 Tab（占位骨架，待 M1 实现）
//

import SwiftUI

/// 模块 A · 吃啥 Tab 根视图
///
/// v1 占位（M1 占位骨架）：仅显示场景标题 + 🦊 欢迎文案 + 占位按钮。
/// 后续 M1 实现：抽签按钮 + 候选结果 + 收藏 + 历史 + 过敏原过滤。
struct EatView: View {
    var body: some View {
        NavigationStack {
            PlaceholderTabView(sceneType: .eat)
        }
    }
}

#Preview {
    EatView()
}