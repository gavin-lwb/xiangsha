//
//  AppSettingsView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D087-D094（设置）+ D088（过敏原再编辑）+ D099（DEBUG 围栏）+ fox-persona §13
//

import SwiftUI
import SwiftData

/// 设置主视图（sheet 弹出）
///
/// 4 大分组（02-AGENTS 约定）：
/// - 隐私（allergens）
/// - 推荐（v1.1+）
/// - 关于（visibly over + debug unlock）
/// - 链接（收藏 / 历史 / 隐私政策）
struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var debugTapCount: Int = 0
    @State private var showAllergenEditor: Bool = false
    @State private var showOnboardingReplay: Bool = false
    @State private var showRoadmap: Bool = false

    // D091 外观偏好（@AppStorage 持久化）
    @AppStorage("appearance.useDarkMode") private var useDarkMode: Bool = false
    @AppStorage("appearance.showWeatherBanner") private var showWeatherBanner: Bool = true

    // D092 反馈偏好
    @AppStorage("feedback.showRatingTooltip") private var showRatingTooltip: Bool = true

    private static let debugUnlockTapsRequired: Int = 5

    var body: some View {
        NavigationStack {
            List {
                allergensSection
                appearanceSection
                feedbackSection
                onboardingSection
                dataSection
                aboutSection
                debugSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color.theme.accent)
                }
            }
            // ⚠️ sheet 必须挂在稳定的视图上（如 NavigationStack）
            // 不能挂在条件渲染的 Section，否则视图销毁/重建会让 sheet 立即关闭
            .sheet(isPresented: $showAllergenEditor) {
                if let profile = profiles.first {
                    AllergenEditorSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showDebugPanel) {
                DebugPanelView()
            }
            .sheet(isPresented: $showOnboardingReplay) {
                OnboardingView()
            }
            .sheet(isPresented: $showRoadmap) {
                V1RoadmapSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 隐私 / 过敏原

    private var allergensSection: some View {
        Section {
            if let profile = profiles.first {
                HStack {
                    Text("过敏原")
                    Spacer()
                    Text(profile.allergens
                            .map { $0 == UserProfile.noAllergenSentinel ? "无" : $0 }
                            .joined(separator: "、"))
                        .font(Font.theme.callout)
                        .foregroundStyle(Color.theme.textSecondary)
                        .lineLimit(2)
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showAllergenEditor = true
                }
            }
        } header: {
            Text("隐私")
        } footer: {
            Text("勾选过敏原后，含有这些成分的菜会被硬屏排除")
                .font(Font.theme.caption)
        }
    }

    // MARK: - 推荐（D091 外观）

    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $useDarkMode) {
                Label {
                    Text("深色模式")
                } icon: {
                    Image(systemName: useDarkMode ? "moon.fill" : "sun.max.fill")
                }
            }
            Toggle(isOn: $showWeatherBanner) {
                Label {
                    Text("天气 banner")
                } icon: {
                    Image(systemName: "cloud.sun.fill")
                }
            }
        } header: {
            Text("外观")
        } footer: {
            Text("v1 浅色固定；v1.1+ 支持系统/浅/深切换")
                .font(Font.theme.caption)
        }
    }

    // MARK: - 反馈（D092）

    private var feedbackSection: some View {
        Section {
            Toggle(isOn: $showRatingTooltip) {
                Label {
                    Text("评分气泡提示")
                } icon: {
                    Image(systemName: "hand.tap.fill")
                }
            }
        } header: {
            Text("反馈")
        } footer: {
            Text("评分时弹出解释气泡（长按 emoji 0.5s 触发）")
                .font(Font.theme.caption)
        }
    }

    // MARK: - 重看引导（D089）

    private var onboardingSection: some View {
        Section {
            Button {
                showOnboardingReplay = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Color.theme.accent)
                    Text("再看一次启动引导")
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
        } header: {
            Text("引导")
        } footer: {
            Text("第一次启动时显示的 3 屏引导，可随时再回看")
                .font(Font.theme.caption)
        }
    }

    // MARK: - 数据（D093）

    private var dataSection: some View {
        Section {
            Button {
                showRoadmap = true
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color.theme.accent)
                    Text("v1.1 Roadmap")
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    Text("\(v1FutureFeatures.count) 项在路上")
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
        } header: {
            Text("数据")
        } footer: {
            Text("v1 之后的规划：食材反向查询 / 营养均衡 / 附近活动 / 决策日记 / Routine")
                .font(Font.theme.caption)
        }
    }

    private var v1FutureFeatures: [String] { ["食材查询", "营养均衡", "附近活动", "决策日记", "Routine"] }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            // 版本行（D099 5-tap 解锁入口）
            HStack {
                Text("版本")
                Spacer()
                Text(versionString)
                    .font(Font.theme.callout)
                    .foregroundStyle(Color.theme.textSecondary)
                if debugTapCount > 0 && debugTapCount < Self.debugUnlockTapsRequired {
                    Text("再点 \(Self.debugUnlockTapsRequired - debugTapCount) 下")
                        .font(Font.theme.caption2)
                        .foregroundStyle(Color.theme.warning)
                        .padding(.leading, ThemeSpacing.xs)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleVersionTap()
            }
            HStack {
                Text("小狐狸🦊")
                Spacer()
                Text("谢谢你喜欢")
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            if let url = URL(string: "https://github.com/fengxiaohai/xiangsha/blob/main/xiangsha/Resources/privacy-policy.md") {
                Link(destination: url) {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }
            // D096 反馈入口
            if let url = URL(string: "https://github.com/fengxiaohai/xiangsha/issues") {
                Link(destination: url) {
                    HStack {
                        Label("反馈 / 建议", systemImage: "exclamationmark.bubble.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }
        } header: {
            Text("关于")
        }
    }

    // MARK: - DEBUG（D099 5-tap 解锁）

    @State private var showDebugPanel: Bool = false

    @ViewBuilder
    private var debugSection: some View {
        if let profile = profiles.first, profile.debugModeEnabled {
            Section {
                Toggle("DEBUG 模式", isOn: Binding(
                    get: { profile.debugModeEnabled },
                    set: { newValue in
                        profile.debugModeEnabled = newValue
                        profile.updatedAt = Date()
                        try? modelContext.save()
                    }
                ))
                .tint(Color.theme.warning)
                Button {
                    showDebugPanel = true
                } label: {
                    Label("打开 DEBUG 面板", systemImage: "wrench.and.screwdriver.fill")
                }
            } header: {
                Text("DEBUG")
            } footer: {
                Text("D099：仅 DEBUG 构建可见，release 无痕迹")
                    .font(Font.theme.caption)
            }
            // ⚠️ sheet 不再挂这里（移到外层 NavigationStack）
        } else {
            // 隐藏入口：连续点 5 下版本行解锁（D099）
            EmptyView()
                .onAppear { debugTapCount = 0 }
        }
    }

    private var versionString: String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    /// D099 5-tap 解锁：连续点击版本行 5 次开启 DEBUG 模式
    private func handleVersionTap() {
        debugTapCount += 1
        guard debugTapCount >= Self.debugUnlockTapsRequired,
              let profile = profiles.first else { return }

        profile.debugModeEnabled = true
        profile.updatedAt = Date()
        try? modelContext.save()
        debugTapCount = 0 // 重置，下次再点
    }
}

// MARK: - 过敏原编辑器（用于设置再编辑）

private struct AllergenEditorSheet: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedAllergens: Set<String>

    init(profile: UserProfile) {
        self.profile = profile
        _selectedAllergens = State(initialValue: Set(profile.allergens))
    }

    private static let commonAllergens: [String] = [
        "花生", "大豆", "奶", "小麦", "鸡蛋", "虾", "蟹", "坚果", "鱼", "贝"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: ThemeSpacing.lg) {
                VStack(spacing: ThemeSpacing.xs) {
                    Text("过敏原变了？告诉小狐狸一声 🦊")
                        .font(Font.theme.title3)
                        .multilineTextAlignment(.center)
                    Text("哪怕要过夜也行")
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.top, ThemeSpacing.md)

                VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                    HStack {
                        ForEach(Self.commonAllergens, id: \.self) { allergen in
                            AllergenChipButton(
                                title: allergen,
                                isSelected: selectedAllergens.contains(allergen)
                            ) {
                                toggle(allergen)
                            }
                        }
                    }
                    HStack {
                        AllergenChipButton(
                            title: "无",
                            isSelected: selectedAllergens.contains(UserProfile.noAllergenSentinel),
                            isNone: true
                        ) {
                            toggle(UserProfile.noAllergenSentinel)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.theme.background)
            .navigationTitle("过敏原")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Color.theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        profile.allergens = selectedAllergens.isEmpty
                            ? [UserProfile.noAllergenSentinel]
                            : Array(selectedAllergens)
                        profile.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundStyle(Color.theme.accent)
                    .disabled(selectedAllergens.isEmpty)
                }
            }
        }
    }

    private func toggle(_ allergen: String) {
        if selectedAllergens.contains(allergen) {
            selectedAllergens.remove(allergen)
        } else {
            selectedAllergens.insert(allergen)
        }
    }
}

private struct AllergenChipButton: View {
    let title: String
    let isSelected: Bool
    var isNone: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.theme.caption)
                .padding(.horizontal, ThemeSpacing.sm)
                .padding(.vertical, ThemeSpacing.xxs)
                .background(
                    isSelected
                        ? (isNone ? Color.theme.success : Color.theme.accent)
                        : Color.theme.surface,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.theme.textOnPrimary : Color.theme.textPrimary)
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppSettingsView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}