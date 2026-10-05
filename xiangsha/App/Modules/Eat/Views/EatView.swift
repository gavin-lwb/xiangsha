//
//  EatView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 A · 吃啥 Tab（v1 真实 ViewModel + DrawEngine 集成）
//

import SwiftUI
import SwiftData

/// 模块 A · 吃啥 Tab 根视图
///
/// v1 集成：
/// - @Query 读 4 个场景的吃啥 + 全部 CardPool
/// - ViewModel 调用 DrawEngine
/// - DrawResult 展示 + 接受/拒绝/换一签 按钮
struct EatView: View {
    // MARK: - 数据查询（02-AGENTS §A.7 View 可 @Query 只读）

    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "eat" })
    private var eatScenes: [DecisionScene]

    @Query(sort: \CardPool.sortOrder)
    private var allPools: [CardPool]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    // MARK: - ViewModel

    @State private var viewModel: EatViewModel = .init()

    // MARK: - 弹出页面状态

    @State private var showSettings: Bool = false
    @State private var showFavorites: Bool = false
    @State private var showHistory: Bool = false

    // MARK: - 成就解锁 Toast（D097）

    @State private var pendingAchievements: [Achievement] = []

    // MARK: - 天气（D137）

    @StateObject private var weatherService = WeatherService.shared
    @State private var weatherLoaded = false

    // MARK: - 跨场景联动回调（D121）

    let onLinkRequest: (Card) -> Void

    @Environment(\.modelContext) private var modelContext

    init(onLinkRequest: @escaping (Card) -> Void = { _ in }) {
        self.onLinkRequest = onLinkRequest
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = eatScenes.first {
                    EatContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel,
                        weather: weatherService.currentWeather,
                        weatherText: WeatherService.recommendationText(for: weatherService.currentWeather),
                        onAcceptComplete: { checkAchievements() },
                        onFavoriteToggle: { checkAchievements() },
                        onLinkRequest: { card in
                            // 跨场景联动：推荐玩啥
                            requestLink(to: .play, card: card)
                        }
                    )
                } else {
                    EmptyStateView(
                        icon: "fork.knife",
                        title: "正在加载吃啥场景…",
                        message: "小狐狸🦊 第一次启动会准备卡片"
                    )
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.eat.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showHistory = true
                        } label: {
                            Label("历史", systemImage: "clock.arrow.circlepath")
                        }
                        Button {
                            showFavorites = true
                        } label: {
                            Label("收藏", systemImage: "heart.fill")
                        }
                        Divider()
                        Button {
                            showSettings = true
                        } label: {
                            Label("设置", systemImage: "gearshape.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.theme.accent)
                    }
                    .accessibilityLabel("更多")
                }
            }
            .overlay(alignment: .top) {
                CelebrationToastStack(pendingAchievements: $pendingAchievements)
                    .padding(.top, ThemeSpacing.md)
            }
        }
        .sheet(isPresented: $showSettings) {
            AppSettingsView()
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .task {
            // D137 天气感知（v1 stub：首次进入 Tab 拉一次）
            if !weatherLoaded {
                await weatherService.fetchCurrentWeather()
                weatherLoaded = true
            }
        }
        .task {
            // D137 天气感知（v1 stub：首次进入 Tab 拉一次）
            if !weatherLoaded {
                await weatherService.fetchCurrentWeather()
                weatherLoaded = true
            }

            // ⚠️ SwiftData @Query 首次 fetch 是异步，task 触发时数据可能还没回来
            // 直接用 modelContext.fetch 主动拉（同步 + 可靠）
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

    /// D097 成就检查（accept / toggleFavorite 后调用）
    private func checkAchievements() {
        guard let profile = profiles.first else { return }
        let unlocked = AchievementService.checkAndUnlock(context: modelContext, profile: profile)
        if !unlocked.isEmpty {
            pendingAchievements.append(contentsOf: unlocked)
        }
    }

    /// D121 跨场景联动请求
    private func requestLink(to target: DecisionSceneType, card: Card) {
        if let recommend = CrossSceneLinkService.recommendCard(target: target, context: modelContext) {
            onLinkRequest(recommend)
        } else {
            onLinkRequest(card) // fallback
        }
    }
}

// MARK: - 内容子视图（按场景拆开便于测试）

private struct EatContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: EatViewModel
    let weather: CurrentWeather?
    let weatherText: String?
    let onAcceptComplete: () -> Void
    let onFavoriteToggle: () -> Void
    let onLinkRequest: (Card) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.lg) {
                // 场景头部
                SceneHeaderView(
                    title: scene.title,
                    icon: scene.icon,
                    greeting: viewModel.greetingText
                )
                .padding(.top, ThemeSpacing.md)

                // D137 天气 banner（🦊 推荐）
                WeatherBanner(weather: weather, bodyText: weatherText)

                // 卡池选择器（如有多个）
                if pools.count > 1 {
                    PoolPickerView(pools: pools, selectedPoolId: $viewModel.selectedPool)
                }

                // 主展示区
                if let result = viewModel.lastResult {
                    DrawResultView(
                        result: result,
                        isFavorite: viewModel.isCurrentFavorite,
                        onToggleFavorite: { viewModel.toggleFavorite() }
                    )

                    // D135 3 emoji 评分
                    EmojiRatingRow(
                        currentRating: viewModel.currentRating,
                        onRate: { emoji in viewModel.rate(emoji: emoji) }
                    )

                    // 评分反馈气泡
                    if let feedback = viewModel.ratingFeedback {
                        RatingFeedbackBubble(
                            text: feedback,
                            onDismiss: { viewModel.clearRatingFeedback() }
                        )
                    }

                    // D121 跨场景联动 banner
                    if let target = CrossSceneLinkService.recommendedTarget(for: .eat),
                       let context = viewModel.modelContext,
                       let recommend = CrossSceneLinkService.recommendCard(target: target, context: context) {
                        CrossSceneBanner(
                            sourceScene: .eat,
                            targetScene: target,
                            suggestedCardTitle: recommend.title,
                            suggestedCardEmoji: recommend.emoji,
                            onTap: { onLinkRequest(recommend) }
                        )
                    }

                    // L2 过敏警告 banner（D088）
                    if viewModel.showingAllergenWarning {
                        AllergenWarningBanner(
                            onAccept: { viewModel.accept() },
                            onRedraw: { Task { await viewModel.redraw() } }
                        )
                    }
                } else if viewModel.showingNoDecisionPanel {
                    // D134 不决策模式面板
                    NoDecisionPanel(
                        onAction: { action in
                            switch action {
                            case .skip: viewModel.performNoDecisionAction(.skip)
                            case .changeCategory: viewModel.performNoDecisionAction(.changeCategory)
                            case .decideMyself: viewModel.performNoDecisionAction(.decideMyself)
                            }
                        }
                    )
                } else if let error = viewModel.error {
                    DrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
                } else {
                    EmptyDrawStateView()
                }

                // 主按钮
                PrimaryActionButton(
                    title: viewModel.primaryButtonText,
                    isLoading: viewModel.isLoading,
                    action: {
                        if viewModel.lastResult != nil {
                            viewModel.accept()
                            onAcceptComplete()
                        } else {
                            Task { await viewModel.draw() }
                        }
                    }
                )

                // 次按钮（结果存在时显示）
                if viewModel.showsSecondaryActions {
                    HStack(spacing: ThemeSpacing.md) {
                        SecondaryActionButton(
                            title: "换一签 🔁",
                            action: { Task { await viewModel.redraw() } }
                        )
                        SecondaryActionButton(
                            title: "拒绝 🙅",
                            action: { viewModel.reject() }
                        )
                    }
                    .padding(.horizontal)

                    // D052 破例按钮（L2 过敏警告时显示：含过敏原也要）
                    if viewModel.showingAllergenWarning {
                        Button {
                            viewModel.accept()
                            onAcceptComplete()
                        } label: {
                            HStack(spacing: ThemeSpacing.xs) {
                                Image(systemName: "exclamationmark.shield.fill")
                                Text("💪 我就要这个（破例）")
                            }
                            .font(Font.theme.bodyEmphasis)
                            .foregroundStyle(Color.theme.warning)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ThemeSpacing.sm)
                            .background(
                                Color.theme.warning.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: ThemeRadius.md)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ThemeRadius.md)
                                    .stroke(Color.theme.warning.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.top, ThemeSpacing.xs)
                    }
                }

                // 底部留白
                Color.clear.frame(height: ThemeSpacing.lg)
            }
            .padding(.horizontal, ThemeSpacing.md)
            .padding(.bottom, ThemeSpacing.lg)
        }
    }
}

// MARK: - 子组件

private struct SceneHeaderView: View {
    let title: String
    let icon: String
    let greeting: String

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.accent)
                .accessibilityHidden(true)

            Text(greeting)
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct PoolPickerView: View {
    let pools: [CardPool]
    @Binding var selectedPoolId: CardPool?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ThemeSpacing.xs) {
                ForEach(pools) { pool in
                    Button(action: { selectedPoolId = pool }) {
                        Text(pool.name)
                            .font(Font.theme.caption)
                            .padding(.horizontal, ThemeSpacing.sm)
                            .padding(.vertical, ThemeSpacing.xxs)
                            .background(
                                    selectedPoolId?.id == pool.id
                                        ? Color.theme.accent
                                        : Color.theme.surface,
                                    in: Capsule()
                                )
                                .foregroundStyle(
                                    selectedPoolId?.id == pool.id
                                        ? Color.theme.textOnPrimary
                                        : Color.theme.textPrimary
                                )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct DrawResultView: View {
    let result: DrawResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            // 大占位（D140 v1 占位：色块 + 大 emoji + 菜名）
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: ThemeRadius.lg)
                    .fill(Color.theme.accentSubtle)
                    .frame(height: 240)
                    .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md, x: 0, y: 2)

                // 收藏按钮（⭐）
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(isFavorite ? Color.theme.danger : Color.theme.textSecondary)
                        .padding(ThemeSpacing.sm)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
                .padding(ThemeSpacing.sm)

                VStack(spacing: ThemeSpacing.md) {
                    Spacer()
                    if let emoji = result.card.emoji {
                        Text(emoji)
                            .font(.system(size: 80))
                    } else {
                        Text("🍜")
                            .font(.system(size: 80))
                    }

                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .foregroundStyle(Color.theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            }
            .padding(.horizontal)

            // 元信息
            HStack(spacing: ThemeSpacing.md) {
                MetaPill(label: "候选", value: "\(result.candidatesAfterFilter)")
                if !result.appliedFactors.isEmpty {
                    MetaPill(label: "应用因子", value: "\(result.appliedFactors.count)")
                }
                if let brand = result.card.brand {
                    MetaPill(label: "品牌", value: brand)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("抽签结果：\(result.card.title)")
    }
}

private struct MetaPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(Color.theme.textSecondary)
            Text(value).foregroundStyle(Color.theme.textPrimary)
        }
        .font(Font.theme.caption)
        .padding(.horizontal, ThemeSpacing.sm)
        .padding(.vertical, ThemeSpacing.xxs)
        .background(Color.theme.surface, in: Capsule())
    }
}

private struct DrawErrorView: View {
    let error: DrawEngineError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.warning)
                .accessibilityHidden(true)

            Text(headlineText)
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)

            if let detail = error.errorDescription {
                Text(detail)
                    .font(Font.theme.body)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onDismiss) {
                Text("知道了")
                    .font(Font.theme.button)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }

    private var headlineText: String {
        switch error {
        case .noCandidates: return "歇够了？加点新内容吧"
        case .invalidContext: return "暂时没法抽"
        case .notImplemented: return "小狐狸还在准备"
        }
    }
}

private struct EmptyDrawStateView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text("🦊")
                .font(.system(size: 96))
                .accessibilityHidden(true)

            Text("准备好就开始吧")
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.textSecondary)
            Text(title)
                .font(Font.theme.title3)
            Text(message)
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct AllergenWarningBanner: View {
    let onAccept: () -> Void
    let onRedraw: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.theme.warning)
            Text("⚠️ 含过敏原，确认接受？")
                .font(Font.theme.callout)
                .foregroundStyle(Color.theme.textPrimary)
            Spacer()
            Button("确认", action: onAccept)
                .font(Font.theme.button)
                .foregroundStyle(Color.theme.accent)
            Button("换一个", action: onRedraw)
                .font(Font.theme.button)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding()
        .background(Color.theme.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }
}

// MARK: - D135 3 emoji 评分

private struct EmojiRatingRow: View {
    let currentRating: EmojiRating?
    let onRate: (EmojiRating) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text("怎么样，这次选得还行吗？")
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)

            HStack(spacing: ThemeSpacing.md) {
                ForEach(EmojiRating.allCases, id: \.self) { rating in
                    EmojiRatingButton(
                        rating: rating,
                        isSelected: currentRating == rating,
                        onTap: { onRate(rating) }
                    )
                }
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("评分")
    }
}

private struct EmojiRatingButton: View {
    let rating: EmojiRating
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(rating.rawValue)
                .font(.system(size: 40))
                .padding(ThemeSpacing.xs)
                .background(
                    isSelected ? Color.theme.accentSubtle : Color.clear,
                    in: Circle()
                )
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        switch rating {
        case .like: return "喜欢"
        case .neutral: return "一般"
        case .dislike: return "不喜欢"
        }
    }
}

private struct RatingFeedbackBubble: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "bubble.left.fill")
                .foregroundStyle(Color.theme.accent)
            Text(text)
                .font(Font.theme.callout)
                .foregroundStyle(Color.theme.textPrimary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
        .padding()
        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - D134 不决策模式面板

private struct NoDecisionPanel: View {
    let onAction: (NoDecisionAction) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Text("🦊")
                .font(.system(size: 80))

            Text("今天看起来都不太对胃口呢……")
                .font(Font.theme.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.theme.textPrimary)

            Text("要不要换个玩法？")
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)

            VStack(spacing: ThemeSpacing.sm) {
                NoDecisionButton(
                    emoji: "🛌",
                    title: "算了，今天就不抽了",
                    action: { onAction(.skip) }
                )
                NoDecisionButton(
                    emoji: "🔄",
                    title: "换到「\(eatOtherScene)」看看",
                    action: { onAction(.changeCategory) }
                )
                NoDecisionButton(
                    emoji: "💡",
                    title: "我心里有答案",
                    action: { onAction(.decideMyself) }
                )
            }
            .padding(.top, ThemeSpacing.sm)
        }
        .padding(.horizontal, ThemeSpacing.xl)
    }

    private var eatOtherScene: String {
        // 推荐切换到「玩啥」
        "玩啥"
    }
}

private struct NoDecisionButton: View {
    let emoji: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ThemeSpacing.sm) {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(Font.theme.body)
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.md)
                    .stroke(Color.theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NoDecisionAction 共享枚举

enum NoDecisionAction {
    case skip
    case changeCategory
    case decideMyself
}

private struct PrimaryActionButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.theme.textOnPrimary)
                }
                Text(title)
                    .font(Font.theme.buttonLarge)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
            .foregroundStyle(Color.theme.textOnPrimary)
        }
        .disabled(isLoading)
        .padding(.horizontal)
        .accessibilityLabel(title)
    }
}

private struct SecondaryActionButton: View {
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
    EatView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}