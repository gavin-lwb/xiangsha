//
//  PlayView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 B · 玩啥 Tab（v1.3 决策：玩啥·点子库）
//

import SwiftUI
import SwiftData

/// 模块 B · 玩啥 Tab 根视图
///
/// v1.3 决策：玩啥·点子库（30-50 张活动卡，4 卡池：室内单人/室外单人/室内多人/室外多人）
struct PlayView: View {
    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "play" })
    private var playScenes: [DecisionScene]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var viewModel = PlayViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = playScenes.first {
                    PlayContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel
                    )
                } else {
                    PlaceholderTabView(sceneType: .play)
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.play.title)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.scene = playScenes.first
            viewModel.selectedPool = playScenes.first?.cardPools.first
            if let profile = profiles.first {
                viewModel.userProfileSnapshot = UserProfileSnapshot(
                    from: profile,
                    recentStyles7d: [],
                    lastMealOfToday: nil,
                    historyAggregate: .empty
                )
            }
        }
    }
}

// 复用 EatView 的子组件 — 通过 CardResultRenderer 提取共享渲染
private struct PlayContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: PlayViewModel

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            VStack(spacing: ThemeSpacing.xs) {
                Text(scene.icon).font(.system(size: 56))
                Text(viewModel.greetingText)
                    .font(Font.theme.title3)
                    .foregroundStyle(Color.theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, ThemeSpacing.md)

            if pools.count > 1 {
                PoolPickerStrip(pools: pools, selectedPool: $viewModel.selectedPool)
            }

            if let result = viewModel.lastResult {
                PlayDrawResultView(result: result)
            } else if let error = viewModel.error {
                PlayDrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                PlaceholderTabView(sceneType: .play)
            }

            Spacer()

            Button(action: {
                if viewModel.lastResult != nil {
                    viewModel.accept()
                } else {
                    Task { await viewModel.draw() }
                }
            }) {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(Color.theme.textOnPrimary) }
                    Text(viewModel.primaryButtonText).font(Font.theme.buttonLarge)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                .foregroundStyle(Color.theme.textOnPrimary)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal)

            if viewModel.showsSecondaryActions {
                HStack(spacing: ThemeSpacing.md) {
                    SecondaryButton(title: "换一签 🔁", action: { Task { await viewModel.redraw() } })
                    SecondaryButton(title: "拒绝 🙅", action: { viewModel.reject() })
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
    }
}

private struct PoolPickerStrip: View {
    let pools: [CardPool]
    @Binding var selectedPool: CardPool?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ThemeSpacing.xs) {
                ForEach(pools) { pool in
                    Button(action: { selectedPool = pool }) {
                        Text(pool.name)
                            .font(Font.theme.caption)
                            .padding(.horizontal, ThemeSpacing.sm)
                            .padding(.vertical, ThemeSpacing.xxs)
                            .background(
                                selectedPool?.id == pool.id ? Color.theme.accent : Color.theme.surface,
                                in: Capsule()
                            )
                            .foregroundStyle(
                                selectedPool?.id == pool.id ? Color.theme.textOnPrimary : Color.theme.textPrimary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PlayDrawResultView: View {
    let result: DrawResult

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.lg)
                    .fill(Color.theme.accentSubtle)
                    .frame(height: 240)
                    .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md)

                VStack(spacing: ThemeSpacing.md) {
                    Text(result.card.emoji ?? "🎮").font(.system(size: 80))
                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)
                }
                .padding()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("玩啥结果：\(result.card.title)")
        }
    }
}

private struct PlayDrawErrorView: View {
    let error: DrawEngineError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.warning)
            Text(headline)
                .font(Font.theme.title3)
            Button("知道了", action: onDismiss).buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }

    private var headline: String {
        switch error {
        case .noCandidates: return "歇够了？加点新内容吧"
        case .invalidContext: return "暂时没法抽"
        case .notImplemented: return "小狐狸还在准备"
        }
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.theme.button)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                .foregroundStyle(Color.theme.textPrimary)
        }
    }
}

#Preview {
    PlayView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}