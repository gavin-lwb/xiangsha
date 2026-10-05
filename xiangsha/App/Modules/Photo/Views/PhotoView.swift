//
//  PhotoView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 D · 拍啥 Tab
//

import SwiftUI
import SwiftData

/// 模块 D · 拍啥 Tab 根视图
struct PhotoView: View {
    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "photo" })
    private var photoScenes: [DecisionScene]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var viewModel = PhotoViewModel()
    @State private var pendingAchievements: [Achievement] = []
    @State private var showUserCardSheet: Bool = false
    @Environment(\.modelContext) private var modelContext

    let onLinkRequest: (Card) -> Void

    init(onLinkRequest: @escaping (Card) -> Void = { _ in }) {
        self.onLinkRequest = onLinkRequest
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = photoScenes.first {
                    PhotoContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel,
                        onAcceptComplete: { checkAchievements() },
                        onFavoriteToggle: { checkAchievements() },
                        onLinkRequest: { card in
                            requestLink(to: .play, card: card)
                        }
                    )
                } else {
                    PlaceholderTabView(sceneType: .photo)
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.photo.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showUserCardSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.theme.accent)
                    }
                    .accessibilityLabel("加姿势")
                }
            }
            .overlay(alignment: .top) {
                CelebrationToastStack(pendingAchievements: $pendingAchievements)
                    .padding(.top, ThemeSpacing.md)
            }
        }
        .sheet(isPresented: $showUserCardSheet) {
            PhotoUserCardSheet { title, emoji in
                viewModel.createUserPhotoCard(title: title, emoji: emoji)
            }
            .presentationDetents([.medium])
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

private struct PhotoContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: PhotoViewModel
    let onAcceptComplete: () -> Void
    let onFavoriteToggle: () -> Void
    let onLinkRequest: (Card) -> Void

    @State private var detailCard: PhotoIdentifiableUUID?
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

            if let result = viewModel.lastResult {
                PhotoDrawResultView(
                    result: result,
                    isFavorite: viewModel.isCurrentFavorite,
                    onToggleFavorite: {
                        viewModel.toggleFavorite()
                        onFavoriteToggle()
                    },
                    onTap: { cardID in
                        detailCard = PhotoIdentifiableUUID(id: cardID)
                    }
                )
                PhotoEmojiRatingRow(
                    currentRating: viewModel.currentRating,
                    onRate: { viewModel.rate(emoji: $0) }
                )
                if let feedback = viewModel.ratingFeedback {
                    PhotoFeedbackBubble(text: feedback, onDismiss: { viewModel.clearRatingFeedback() })
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
                if let target = CrossSceneLinkService.recommendedTarget(for: .photo),
                   let context = viewModel.modelContext,
                   let recommend = CrossSceneLinkService.recommendCard(target: target, context: context) {
                    CrossSceneBanner(
                        sourceScene: .photo,
                        targetScene: target,
                        suggestedCardTitle: recommend.title,
                        suggestedCardEmoji: recommend.emoji,
                        onTap: { onLinkRequest(recommend) }
                    )
                }
            } else if let error = viewModel.error {
                PhotoDrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                PhotoEmptyStateView()
            }

            Spacer()

            // 次按钮
            if viewModel.showsSecondaryActions {
                HStack(spacing: ThemeSpacing.md) {
                    PhotoSecondaryButton(title: "换姿势 🔁", action: { Task { await viewModel.redraw() } })
                    PhotoSecondaryButton(title: "算了", action: { viewModel.reject() })
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
        // 主按钮 sticky bottom — 永远可见不被 TabBar 遮挡
        .safeAreaInset(edge: .bottom) {
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
            .padding(.bottom, ThemeSpacing.sm)
            .background(.thinMaterial)
        }
        // Pattern 2：点击抽签结果放大详情
        .sheet(item: $detailCard) { wrapper in
            let cardID = wrapper.id
            let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
            if let card = try? detailContext.fetch(descriptor).first {
                CardDetailSheet(card: card, sceneType: .photo)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        // D037 · 分享卡 sheet
        .sheet(item: $shareCard) { card in
            ShareCardSheet(card: card)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // Pattern 6：今日组合
        .sheet(isPresented: $showComboSheet) {
            TodayComboSheet()
                .presentationDetents([.height(360), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func lookupCard(id: UUID) -> Card? {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        return try? detailContext.fetch(descriptor).first
    }
}

private struct PhotoDrawResultView: View {
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
                        .fill(LinearGradient(
                            colors: [Color.theme.accentSubtle, Color.theme.accent.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 360)
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
                    Text(result.card.emoji ?? "📸").font(.system(size: 96))
                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)
                    if let category = result.card.category {
                        Text("·\(category)·")
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    Spacer()
                }
                .padding()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("拍啥姿势：\(result.card.title)")
        }
    }
}

private struct PhotoDrawErrorView: View {
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

private struct PhotoEmptyStateView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text("🦊").font(.system(size: 96))
            Text("准备拍点啥")
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
            Text("v1 用 emoji + 文字描述，v1.1+ 上真实图")
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct PhotoSecondaryButton: View {
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

private struct PhotoEmojiRatingRow: View {
    let currentRating: EmojiRating?
    let onRate: (EmojiRating) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text("想拍吗？")
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

private struct PhotoFeedbackBubble: View {
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
    PhotoView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}

/// 辅助：UUID 用于 sheet(item:) 的 Identifiable 包装
private struct PhotoIdentifiableUUID: Identifiable, Equatable {
    let id: UUID
}