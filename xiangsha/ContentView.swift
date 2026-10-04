//
//  ContentView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：02-AGENTS §A.4 优先级 / D004（4 Tab 场景隔离）
//

import SwiftUI

/// 应用根视图：4 Tab 容器
///
/// Tab 顺序按 SPEC §10 + fox-persona：吃啥 / 玩啥 / 做啥 / 拍啥
struct ContentView: View {
    var body: some View {
        TabView {
            EatView()
                .tabItem {
                    Label(DecisionSceneType.eat.title, systemImage: DecisionSceneType.eat.icon)
                }

            PlayView()
                .tabItem {
                    Label(DecisionSceneType.play.title, systemImage: DecisionSceneType.play.icon)
                }

            DoView()
                .tabItem {
                    Label(DecisionSceneType.task.title, systemImage: DecisionSceneType.task.icon)
                }

            PhotoView()
                .tabItem {
                    Label(DecisionSceneType.photo.title, systemImage: DecisionSceneType.photo.icon)
                }
        }
    }
}

#Preview {
    ContentView()
}