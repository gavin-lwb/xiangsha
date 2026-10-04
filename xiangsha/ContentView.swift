//
//  ContentView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D121（跨场景联动）+ fox-persona §2
//

import SwiftUI
import SwiftData

/// 应用根视图：4 Tab 容器 + 跨场景联动
///
/// Tab 顺序按 SPEC §10：吃啥 / 玩啥 / 做啥 / 拍啥
/// 跨场景联动（D121）：从某 Tab 跳到另一 Tab 时自动触发该场景抽签
struct ContentView: View {
    @State private var selectedTab: DecisionSceneType = .eat
    @State private var pendingLink: CrossSceneLinkRequest?

    var body: some View {
        TabView(selection: $selectedTab) {
            EatView(onLinkRequest: { card in
                requestLink(to: .play, card: card)
            })
            .tabItem {
                Label(DecisionSceneType.eat.title, systemImage: DecisionSceneType.eat.icon)
            }
            .tag(DecisionSceneType.eat)

            PlayView(onLinkRequest: { card in
                requestLink(to: .photo, card: card)
            })
            .tabItem {
                Label(DecisionSceneType.play.title, systemImage: DecisionSceneType.play.icon)
            }
            .tag(DecisionSceneType.play)

            DoView(onLinkRequest: { card in
                requestLink(to: .eat, card: card)
            })
            .tabItem {
                Label(DecisionSceneType.task.title, systemImage: DecisionSceneType.task.icon)
            }
            .tag(DecisionSceneType.task)

            PhotoView(onLinkRequest: { card in
                requestLink(to: .play, card: card)
            })
            .tabItem {
                Label(DecisionSceneType.photo.title, systemImage: DecisionSceneType.photo.icon)
            }
            .tag(DecisionSceneType.photo)
        }
        .onChange(of: pendingLink) { _, newLink in
            if let link = newLink {
                selectedTab = link.targetScene
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    pendingLink = nil
                }
            }
        }
    }

    private func requestLink(to target: DecisionSceneType, card: Card) {
        pendingLink = CrossSceneLinkRequest(targetScene: target, suggestedCard: card)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}