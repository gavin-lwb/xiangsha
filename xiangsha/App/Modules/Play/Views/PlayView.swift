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
struct PlayView: View {
    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "play" })
    private var playScenes: [DecisionScene]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var viewModel = PlayViewModel()
    @State private var pendingAchievements: [Achievement] = []
    @Environment(\.modelContext) private var modelContext

    let onLinkRequest: (Card) -> Void

    init(onLinkRequest: @escaping (Card) -> Void = { _ in }) {
        self.onLinkRequest = onLinkRequest
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = playScenes.first {
                    PlayContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel,
                        onAcceptComplete: { checkAchievements() },
                        onFavoriteToggle: { checkAchievements() },
                        onLinkRequest: { card in
                            // 跨场景联动：推荐拍啥
                            requestLink(to: .photo, card: card)
                        }
                    )
                } else {
                    PlaceholderTabView(sceneType: .play)
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.play.title)
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                CelebrationToastStack(pendingAchievements: $pendingAchievements)
                    .padding(.top, ThemeSpacing.md)
            }
        }
        .task {
            // ⚠️ SwiftData @Query 异步：直接用 modelContext.fetch 同步拉
            viewModel.modelContext = modelContext
            await viewModel.loadInitialData(context: modelContext)
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

private struct PlayContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: PlayViewModel
    let onAcceptComplete: () -> Void
    let onFavoriteToggle: () -> Void
    let onLinkRequest: (Card) -> Void

    @State private var detailCard: PlayIdentifiableUUID?
    @State private var showComboSheet: Bool = false
    @State private var shareCard: Card?
    @Environment(\.modelContext) private var detailContext

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            VStack(spacing: ThemeSpacing.xs) {
                Image(systemName: scene.icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.accent)
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
                PlayDrawResultView(
                    result: result,
                    isFavorite: viewModel.isCurrentFavorite,
                    onToggleFavorite: {
                        viewModel.toggleFavorite()
                        onFavoriteToggle()
                    },
                    onTap: { cardID in
                        detailCard = PlayIdentifiableUUID(id: cardID)
                    }
                )
                PlayEmojiRatingRow(
                    currentRating: viewModel.currentRating,
                    onRate: { viewModel.rate(emoji: $0) }
                )
                if let feedback = viewModel.ratingFeedback {
                    PlayFeedbackBubble(text: feedback, onDismiss: { viewModel.clearRatingFeedback() })
                }

                // D037 · 分享按钮
                Button {
                    if let card = lookupCard(id: result.card.id) {
                        shareCard = card
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("📤 分享给朋友")
                    }
                    .font(Font.theme.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ThemeSpacing.sm)
                    .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.accent)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // D121 跨场景联动 banner
                if let target = CrossSceneLinkService.recommendedTarget(for: .play),
                   let context = viewModel.modelContext,
                   let recommend = CrossSceneLinkService.recommendCard(target: target, context: context) {
                    CrossSceneBanner(
                        sourceScene: .play,
                        targetScene: target,
                        suggestedCardTitle: recommend.title,
                        suggestedCardEmoji: recommend.emoji,
                        onTap: { onLinkRequest(recommend) }
                    )
                }
            } else if let error = viewModel.error {
                PlayDrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                PlayEmptyStateView()
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
                    PlaySecondaryButton(title: "换一个 🔁", action: { Task { await viewModel.redraw() } })
                    PlaySecondaryButton(title: "拒绝 🙅", action: { viewModel.reject() })
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
        // Pattern 2：点击抽签结果放大详情
        .sheet(item: $detailCard) { wrapper in
            let cardID = wrapper.id
            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardID }
            )
            if let card = try? detailContext.fetch(descriptor).first {
                CardDetailSheet(card: card, sceneType: .play)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        // Pattern 6：今日组合
        .sheet(isPresented: $showComboSheet) {
            TodayComboSheet()
                .presentationDetents([.height(360), .medium])
                .presentationDragIndicator(.visible)
        }
        // D037 · 分享卡 sheet
        .sheet(item: $shareCard) { card in
            ShareCardSheet(card: card)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// 从 modelContext 查询完整 Card（ShareCardSheet / CardDetailSheet 需要 Card 实例）
    private func lookupCard(id: UUID) -> Card? {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        return try? detailContext.fetch(descriptor).first
    }
}

// MARK: - 组件（共享模式，与 EatView 类似）

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
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onTap: (UUID) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            ZStack(alignment: .topTrailing) {
                // Pattern 2：整张卡片可点击放大
                Button {
                    onTap(result.card.id)
                } label: {
                    RoundedRectangle(cornerRadius: ThemeRadius.lg)
                        .fill(Color.theme.accentSubtle)
                        .frame(height: 240)
                        .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md)
                }
                .buttonStyle(.plain)

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(isFavorite ? Color.theme.danger : Color.theme.textSecondary)
                        .padding(ThemeSpacing.sm)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(ThemeSpacing.sm)

                VStack(spacing: ThemeSpacing.md) {
                    Spacer()
                    Text(result.card.emoji ?? "🎮").font(.system(size: 80))
                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }
                .padding()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .contain)
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

private struct PlayEmptyStateView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text("🦊").font(.system(size: 96))
            Text("想好去哪儿玩了吗？")
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct PlaySecondaryButton: View {
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

private struct PlayEmojiRatingRow: View {
    let currentRating: EmojiRating?
    let onRate: (EmojiRating) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text("好玩吗？")
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)
            HStack(spacing: ThemeSpacing.md) {
                ForEach(EmojiRating.allCases, id: \.self) { rating in
                    Button(action: { onRate(rating) }) {
                        Text(rating.rawValue)
                            .font(.system(size: 36))
                            .padding(ThemeSpacing.xs)
                            .background(
                                currentRating == rating ? Color.theme.accentSubtle : Color.clear,
                                in: Circle()
                            )
                            .scaleEffect(currentRating == rating ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct PlayFeedbackBubble: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "bubble.left.fill")
                .foregroundStyle(Color.theme.accent)
            Text(text).font(Font.theme.callout).foregroundStyle(Color.theme.textPrimary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
        .padding()
        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
        .padding(.horizontal)
    }
}

#Preview {
    PlayView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}

/// 辅助：UUID 用于 sheet(item:) 的 Identifiable 包装
private struct PlayIdentifiableUUID: Identifiable, Equatable {
    let id: UUID
}