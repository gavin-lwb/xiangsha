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

    // Pattern 2：点击卡片放大详情
    @State private var detailCard: IdentifiableUUID?
    // D044：进入做菜模式（全屏 RecipeTaskRunner）
    @State private var cookingCard: Card?
    // Pattern 6：今日组合底部抽屉
    @State private var showComboSheet: Bool = false
    // D037：分享卡 sheet
    @State private var shareCard: Card?
    // D043：二级筛选条件
    @State private var timeFilter: SecondaryFilter = .any
    @State private var difficultyFilter: SecondaryFilter = .any

    @Environment(\.modelContext) private var detailContext

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
                    PoolPickerView(
                        pools: pools,
                        selectedPoolId: $viewModel.selectedPool,
                        timeFilter: $timeFilter,
                        difficultyFilter: $difficultyFilter
                    )
                }

                // D046 已解锁进度条
                CookedProgressView(
                    cookedCount: viewModel.cookedCount,
                    totalCount: viewModel.totalCardsCount
                )

                // 主展示区
                if let result = viewModel.lastResult {
                    DrawResultView(
                        result: result,
                        isFavorite: viewModel.isCurrentFavorite,
                        onToggleFavorite: { viewModel.toggleFavorite() },
                        onTap: { cardID in
                            detailCard = IdentifiableUUID(id: cardID)
                        }
                    )

                    // D135 3 emoji 评分
                    EmojiRatingRow(
                        currentRating: viewModel.currentRating,
                        onRate: { emoji in viewModel.rate(emoji: emoji) }
                    )

                    // D044/D045 · 在家做菜动作区（仅 hasRecipe 时显示「看菜谱」）
                    if result.card.hasRecipe {
                        Button {
                            cookingCard = lookupCard(id: result.card.id)
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                Text("🍳 看菜谱 / 开始做")
                            }
                            .font(Font.theme.bodyEmphasis)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ThemeSpacing.sm)
                            .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                            .foregroundStyle(Color.theme.accent)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    // D045 · 「✅ 我做过」按钮
                    if !viewModel.cookedCardIDs.contains(result.card.id) {
                        Button {
                            if let card = lookupCard(id: result.card.id) {
                                viewModel.markCooked(card: card)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("✅ 我做过")
                            }
                            .font(Font.theme.bodyEmphasis)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ThemeSpacing.sm)
                            .background(Color.theme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                            .foregroundStyle(Color.theme.success)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    } else {
                        HStack(spacing: ThemeSpacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.theme.success)
                            Text("已做过")
                                .font(Font.theme.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.sm)
                    }

                    // D037/D038 · 「📤 分享」按钮
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
        // Pattern 2：点击抽签结果放大详情
        .sheet(item: $detailCard) { wrapper in
            let cardID = wrapper.id
            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardID }
            )
            if let card = try? detailContext.fetch(descriptor).first {
                CardDetailSheet(
                    card: card,
                    sceneType: scene.type,
                    onStartCooking: { card in
                        detailCard = nil  // 关闭详情 sheet
                        cookingCard = card
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        // D044：全屏 RecipeTaskRunner 做菜模式
        .fullScreenCover(item: $cookingCard) { card in
            RecipeTaskRunner(
                card: card,
                onComplete: { completedCard in
                    viewModel.markCooked(card: completedCard)
                    cookingCard = nil
                },
                onDismiss: { cookingCard = nil }
            )
        }
        // Pattern 6：今日组合底部抽屉
        .sheet(isPresented: $showComboSheet) {
            TodayComboSheet()
                .presentationDetents([.height(360), .medium])
                .presentationDragIndicator(.visible)
        }
        // D037：分享卡 sheet
        .sheet(item: $shareCard) { card in
            ShareCardSheet(card: card)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.refreshCookedProgress()
        }
    }

    /// D044 · 从 modelContext 查询完整 Card（RecipeTaskRunner 需要 Card 实例，非 DrawnCardRef）
    private func lookupCard(id: UUID) -> Card? {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        return try? detailContext.fetch(descriptor).first
    }
}

/// 辅助：UUID 用于 sheet(item:) 的 Identifiable 包装
private struct IdentifiableUUID: Identifiable, Equatable {
    let id: UUID
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
    @Binding var timeFilter: SecondaryFilter
    @Binding var difficultyFilter: SecondaryFilter
    @State private var longPressedPool: CardPool?
    @State private var showAdvancedSheet: Bool = false

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            // 时段 chip 行（D034 长按手势 · 单击切换）
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
                        // D034 · 长按 0.5s 弹菜单
                        .onLongPressGesture(minimumDuration: 0.5) {
                            longPressedPool = pool
                        }
                    }
                }
                .padding(.horizontal)
            }

            // D043 · 二级筛选 chip 行（时间 + 难度）
            HStack(spacing: ThemeSpacing.xs) {
                SecondaryFilterChip(
                    icon: "clock.fill",
                    label: "时间",
                    filter: $timeFilter,
                    options: [("不限", nil), ("快", .fast(15)), ("中", .medium(30)), ("慢", .slow(60))]
                )
                SecondaryFilterChip(
                    icon: "chart.bar.fill",
                    label: "难度",
                    filter: $difficultyFilter,
                    options: [("不限", nil), ("简单", .easy(1)), ("中等", .medium(3)), ("挑战", .hard(5))]
                )
                Button {
                    showAdvancedSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        Text("更多筛选")
                            .font(Font.theme.caption)
                    }
                    .padding(.horizontal, ThemeSpacing.sm)
                    .padding(.vertical, ThemeSpacing.xxs)
                    .background(Color.theme.surface, in: Capsule())
                    .foregroundStyle(Color.theme.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal)
        }
        // D034 · 长按弹菜单
        .confirmationDialog(
            longPressedPool?.name ?? "",
            isPresented: Binding(
                get: { longPressedPool != nil },
                set: { if !$0 { longPressedPool = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("切换到「\(longPressedPool?.name ?? "")」") {
                if let pool = longPressedPool { selectedPoolId = pool }
            }
            Button("设为最爱时段", role: nil) {
                // TODO: 后续接 UserProfile.favoriteTimeOfDay
            }
            Button("隐藏此池", role: .destructive) {
                // v1 不支持卡池级隐藏（D016 仅 Card 级）
                // 保留入口，后续可加 CardPool.isHidden 字段
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("长按时段 chip 可切换 / 设为最爱 / 隐藏")
        }
        // D040 · 半屏 Sheet 更多筛选
        .sheet(isPresented: $showAdvancedSheet) {
            AdvancedFilterSheet(
                timeFilter: $timeFilter,
                difficultyFilter: $difficultyFilter,
                pools: pools,
                selectedPoolId: $selectedPoolId
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

/// 二级筛选条件
enum SecondaryFilter: Equatable, Hashable {
    case any
    case fast(Int)     // 时间 ≤ N 分钟
    case medium(Int)
    case slow(Int)
    case easy(Int)     // 难度 = N
    case mediumLevel(Int)
    case hard(Int)

    var displayName: String {
        switch self {
        case .any: return "不限"
        case .fast: return "快"
        case .medium: return "中"
        case .slow: return "慢"
        case .easy: return "简单"
        case .mediumLevel: return "中等"
        case .hard: return "挑战"
        }
    }

    var value: Int? {
        switch self {
        case .any: return nil
        case let .fast(v), let .medium(v), let .slow(v),
             let .easy(v), let .mediumLevel(v), let .hard(v):
            return v
        }
    }
}

/// 二级筛选 chip
private struct SecondaryFilterChip: View {
    let icon: String
    let label: String
    @Binding var filter: SecondaryFilter
    let options: [(String, SecondaryFilter?)]

    var body: some View {
        Menu {
            ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                Button(opt.0) {
                    filter = opt.1 ?? .any
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(Font.theme.caption)
                if filter != .any {
                    Text("· \(filter.displayName)")
                        .font(Font.theme.caption2)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, ThemeSpacing.sm)
            .padding(.vertical, ThemeSpacing.xxs)
            .background(
                filter == .any ? Color.theme.surface : Color.theme.accentSubtle,
                in: Capsule()
            )
            .foregroundStyle(
                filter == .any ? Color.theme.textSecondary : Color.theme.accent
            )
        }
    }
}

/// D040 · 更多筛选半屏 Sheet
private struct AdvancedFilterSheet: View {
    @Binding var timeFilter: SecondaryFilter
    @Binding var difficultyFilter: SecondaryFilter
    let pools: [CardPool]
    @Binding var selectedPoolId: CardPool?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("时段卡池") {
                    ForEach(pools) { pool in
                        Button {
                            selectedPoolId = pool
                        } label: {
                            HStack {
                                Image(systemName: pool.icon)
                                    .foregroundStyle(Color.theme.accent)
                                Text(pool.name)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Spacer()
                                if selectedPoolId?.id == pool.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.theme.accent)
                                }
                            }
                        }
                    }
                }

                Section("时间") {
                    Picker("时间", selection: $timeFilter) {
                        Text("不限").tag(SecondaryFilter.any)
                        Text("快 ≤ 15 分钟").tag(SecondaryFilter.fast(15))
                        Text("中 ≤ 30 分钟").tag(SecondaryFilter.medium(30))
                        Text("慢 ≤ 60 分钟").tag(SecondaryFilter.slow(60))
                    }
                }

                Section("难度") {
                    Picker("难度", selection: $difficultyFilter) {
                        Text("不限").tag(SecondaryFilter.any)
                        Text("简单 ⭐").tag(SecondaryFilter.easy(1))
                        Text("中等 ⭐⭐⭐").tag(SecondaryFilter.mediumLevel(3))
                        Text("挑战 ⭐⭐⭐⭐⭐").tag(SecondaryFilter.hard(5))
                    }
                }
            }
            .navigationTitle("更多筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct DrawResultView: View {
    let result: DrawResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onTap: (UUID) -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            // 大占位（D140 v1 占位：色块 + 大 emoji + 菜名）
            ZStack(alignment: .topTrailing) {
                // Pattern 2：整张卡片可点击放大
                Button {
                    onTap(result.card.id)
                } label: {
                    RoundedRectangle(cornerRadius: ThemeRadius.lg)
                        .fill(Color.theme.accentSubtle)
                        .frame(height: 240)
                        .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md, x: 0, y: 2)
                }
                .buttonStyle(.plain)

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