//
//  DoView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 C · 做啥 Tab（占位骨架，待 M3 实现）
//

import SwiftUI

/// 模块 C · 做啥 Tab 根视图
///
/// v1 占位（M3 占位骨架）：关键词模板 + 微任务 + 急救 + 全屏庆祝（D076）。
struct DoView: View {
    var body: some View {
        NavigationStack {
            PlaceholderTabView(sceneType: .task)
        }
    }
}

#Preview {
    DoView()
}