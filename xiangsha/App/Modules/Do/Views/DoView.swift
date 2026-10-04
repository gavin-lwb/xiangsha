//
//  DoView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 C · 做啥 Tab
//

import SwiftUI
import SwiftData

/// 模块 C · 做啥 Tab 根视图
struct DoView: View {
    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "task" })
    private var doScenes: [DecisionScene]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var viewModel = DoViewModel()
    @State private var pendingAchievements: [Achievement] = []
    @Environment(\.modelContext) private var modelContext

    let onLinkRequest: (Card) -> Void

    init(onLinkRequest: @escaping (Card) -> Void = { _ in }) {
        self.onLinkRequest = onLinkRequest
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = doScenes.first {
                    DoContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel,
                        onAcceptComplete: { checkAchievements() },
                        onLinkRequest: { card in
                            requestLink(to: .eat, card: card)
                        }
                    )
                } else {
                    PlaceholderTabView(sceneType: .task)
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.task.title)
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                CelebrationToastStack(pendingAchievements: $pendingAchievements)
                    .padding(.top, ThemeSpacing.md)
            }
        }
        .onAppear {
            viewModel.scene = doScenes.first
            viewModel.selectedPool = doScenes.first?.cardPools.first
            viewModel.modelContext = modelContext
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

    private func checkAchievements() {
        guard let profile = profiles.first else { return }
        let unlocked = AchievementService.checkAndUnlock(context: modelContext, profile: profile)
        if !unlocked.isEmpty {
            pendingAchievements.append(contentsOf: unlocked)
        }
    }

    private func requestLink(to target: DecisionSceneType, card: Card) {
        if let recommend = CrossSceneLinkService.recommendCard(target: target, context: modelContext) {
            onLinkRequest(recommend)
        } else {
            onLinkRequest(card)
        }
    }
}

private struct DoContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: DoViewModel
    let onAcceptComplete: () -> Void
    let onLinkRequest: (Card) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            VStack(spacing: ThemeSpacing.xs) {
                Text(scene.icon).font(.system(size: 56))
                Text(viewModel.greetingText)
                    .font(Font.theme.title3)
                    .foregroundStyle(Color.theme.textPrimary)
                    .multilineTextAlignment(.center)
                if viewModel.completedTasksToday > 0 {
                    Text("今天已完成 \(viewModel.completedTasksToday) 件小事 ✨")
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.success)
                }
            }
            .padding(.top, ThemeSpacing.md)

            if let result = viewModel.lastResult {
                DoDrawResultView(result: result, celebrationText: viewModel.celebrationText)

                // D121 跨场景联动 banner（做啥 → 吃啥犒劳）
                if let target = CrossSceneLinkService.recommendedTarget(for: .task),
                   let context = viewModel.modelContext,
                   let recommend = CrossSceneLinkService.recommendCard(target: target, context: context) {
                    CrossSceneBanner(
                        sourceScene: .task,
                        targetScene: target,
                        suggestedCardTitle: recommend.title,
                        suggestedCardEmoji: recommend.emoji,
                        onTap: { onLinkRequest(recommend) }
                    )
                }
            } else if let error = viewModel.error {
                DoDrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                DoEmptyStateView()
            }

            Spacer()

            Button(action: {
                if viewModel.lastResult != nil {
                    viewModel.accept()
                    onAcceptComplete()
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
                    SecondaryDoButton(title: "换一个 🔁", action: { Task { await viewModel.redraw() } })
                    SecondaryDoButton(title: "不想做", action: { viewModel.reject() })
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
        .overlay {
            // D076 完成庆祝全屏弹窗
            if viewModel.showingCelebration {
                CompletionCelebration(
                    text: viewModel.celebrationText,
                    onDismiss: { viewModel.dismissCelebration() }
                )
            }
        }
    }
}

/// D076 全屏完成庆祝
private struct CompletionCelebration: View {
    let text: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: ThemeSpacing.md) {
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(scale)

                Text(text)
                    .font(Font.theme.title1)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ThemeSpacing.xl)

                Button("继续", action: onDismiss)
                    .font(Font.theme.buttonLarge)
                    .padding(.horizontal, ThemeSpacing.xl)
                    .padding(.vertical, ThemeSpacing.sm)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.black)
                    .padding(.top, ThemeSpacing.sm)
            }
            .padding(.vertical, ThemeSpacing.huge)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

private struct DoDrawResultView: View {
    let result: DrawResult
    let celebrationText: String

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.lg)
                    .fill(Color.theme.success.opacity(0.15))
                    .frame(height: 280)
                    .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md)

                VStack(spacing: ThemeSpacing.md) {
                    Text(result.card.emoji ?? "✅").font(.system(size: 80))

                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)

                    if let minutes = metadataTime(result.card) {
                        Text("约 \(minutes) 分钟")
                            .font(Font.theme.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("做啥任务：\(result.card.title)")
        }
    }

    private func metadataTime(_ card: DrawnCardRef) -> Int? {
        // DrawnCardRef 不带 timeMinutes；从 createdAt 推不出来
        return nil
    }
}

private struct DoDrawErrorView: View {
    let error: DrawEngineError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.warning)
            Text("歇够了？加点新内容吧")
                .font(Font.theme.title3)
            Button("知道了", action: onDismiss).buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }
}

private struct DoEmptyStateView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text("🦊").font(.system(size: 96))
            Text("迈出第一步就好")
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
            Text("小狐狸陪你搞定一件件小事")
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct SecondaryDoButton: View {
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
    DoView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}