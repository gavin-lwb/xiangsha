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

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = eatScenes.first {
                    EatContentView(
                        scene: scene,
                        pools: scene.cardPools,
                        profile: profiles.first,
                        viewModel: viewModel
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
        .onAppear {
            // 初始化 ViewModel 数据
            viewModel.scene = eatScenes.first
            viewModel.selectedPool = eatScenes.first?.cardPools.first
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
}

// MARK: - 内容子视图（按场景拆开便于测试）

private struct EatContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: EatViewModel

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            // 场景头部
            SceneHeaderView(
                title: scene.title,
                icon: scene.icon,
                greeting: viewModel.greetingText
            )
            .padding(.top, ThemeSpacing.md)

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

                // L2 过敏警告 banner（D088）
                if viewModel.showingAllergenWarning {
                    AllergenWarningBanner(
                        onAccept: { viewModel.accept() },
                        onRedraw: { Task { await viewModel.redraw() } }
                    )
                }
            } else if let error = viewModel.error {
                DrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                EmptyDrawStateView()
            }

            Spacer()

            // 主按钮
            PrimaryActionButton(
                title: viewModel.primaryButtonText,
                isLoading: viewModel.isLoading,
                action: {
                    if viewModel.lastResult != nil {
                        viewModel.accept()
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
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
    }
}

// MARK: - 子组件

private struct SceneHeaderView: View {
    let title: String
    let icon: String
    let greeting: String

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text(icon)
                .font(.system(size: 56))
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