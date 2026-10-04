//
//  PhotoView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 D · 拍啥 Tab（占位骨架，待 M4 实现）
//

import SwiftUI

/// 模块 D · 拍啥 Tab 根视图
///
/// v1 占位（M4 占位骨架）：7 类姿势 66-81 卡，v1 emoji+SF Symbol 占位，v1.1+ 真实图。
struct PhotoView: View {
    var body: some View {
        NavigationStack {
            PlaceholderTabView(sceneType: .photo)
        }
    }
}

#Preview {
    PhotoView()
}