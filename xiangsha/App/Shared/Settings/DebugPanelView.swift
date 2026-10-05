//
//  DebugPanelView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D099（DEBUG 围栏 · 5-tap 解锁）
//

import SwiftUI
import SwiftData

/// DEBUG 面板（D099）
///
/// 5-tap 解锁后显示：
/// - 数据统计：抽签次数 / 收藏数 / 任务完成数 / 成就数
/// - 数据操作：清空所有数据 + 重置 onboarding
/// - 调试信息：构建号 / SwiftData 路径 / schema 版本
struct DebugPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showClearUsageConfirm: Bool = false

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @Query private var allCards: [Card]
    @Query private var allFavorites: [Favorite]
    @Query private var allDrawRecords: [DrawRecord]
    @Query private var allTaskRecords: [UserTaskRecord]
    @Query private var allScenes: [DecisionScene]

    var body: some View {
        NavigationStack {
            List {
                statsSection
                actionsSection
                buildInfoSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("DEBUG 面板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }

    // MARK: - 数据统计

    private var statsSection: some View {
        Section {
            DebugStatRow(label: "Scene 数", value: "\(allScenes.count)")
            DebugStatRow(label: "卡池数", value: "\(allScenes.flatMap { $0.cardPools }.count)")
            DebugStatRow(label: "卡片数", value: "\(allCards.count)")
            DebugStatRow(label: "收藏数", value: "\(allFavorites.count)")
            DebugStatRow(label: "抽签历史数", value: "\(allDrawRecords.count)")
            DebugStatRow(label: "任务记录数", value: "\(allTaskRecords.count)")
            DebugStatRow(
                label: "已解锁成就",
                value: "\(profiles.first?.earnedAchievements.count ?? 0) / \(Achievement.v1Achievements.count)"
            )
            if let profile = profiles.first {
                DebugStatRow(
                    label: "今日抽签次数",
                    value: "\(profile.drawsToday) / 3"
                )
                DebugStatRow(
                    label: "过敏原",
                    value: profile.allergens
                        .map { $0 == UserProfile.noAllergenSentinel ? "无" : $0 }
                        .joined(separator: "、")
                )
            }
        } header: {
            Text("数据统计")
        }
    }

    // MARK: - 数据操作

    private var actionsSection: some View {
        Section {
            Button(action: resetDrawsToday) {
                Label("重置今日抽签次数（D132 调试用）", systemImage: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(Color.theme.accent)
            }
            // 用户向：保留内置数据（291 张卡 + 4 个场景），只清使用记录
            Button(role: .destructive) {
                showClearUsageConfirm = true
            } label: {
                Label("清空使用记录", systemImage: "sparkles")
                    .foregroundStyle(Color.theme.warning)
            }
#if DEBUG
            // 仅 DEBUG 可见：硬重置（删全部 + 重新种 291 张卡）
            Button(action: clearAllData) {
                Label("[DEV] 重置出厂数据", systemImage: "trash.fill")
                    .foregroundStyle(Color.theme.danger)
            }
#endif
            Button(action: resetOnboarding) {
                Label("重置启动引导", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Color.theme.accent)
            }
            Button(action: closeDebugMode) {
                Label("退出 DEBUG 模式", systemImage: "lock.fill")
                    .foregroundStyle(Color.theme.textSecondary)
            }
        } header: {
            Text("数据操作")
        } footer: {
            VStack(alignment: .leading, spacing: ThemeSpacing.xxs) {
                Text("清空使用记录：保留内置卡与过敏原设置；DEBUG 模式与已解锁成就不会被重置")
                Text("[DEV] 重置出厂：删除全部数据并重新种 291 张卡")
            }
            .font(Font.theme.caption)
            .foregroundStyle(Color.theme.textSecondary)
        }
        .confirmationDialog(
            "清空使用记录？",
            isPresented: $showClearUsageConfirm,
            titleVisibility: .visible
        ) {
            Button("清空", role: .destructive, action: clearUsageData)
            Button("取消", role: .cancel) {}
        } message: {
            Text("将清掉：收藏、抽签记录、任务记录、偏好（风格 / 分类 / 品牌）。\n将保留：291 张内置卡与 4 个场景、你的过敏原设置、已解锁的成就。")
        }
    }

    // MARK: - 构建信息

    private var buildInfoSection: some View {
        Section {
            DebugStatRow(label: "版本", value: appVersion)
            DebugStatRow(label: "构建号", value: buildNumber)
            DebugStatRow(label: "Schema 版本", value: "v1.0")
            DebugStatRow(label: "成就系统", value: "v1 上线（3 个）")
        } header: {
            Text("构建信息")
        }
    }

    // MARK: - Actions

    /// 清空使用记录（保留内置数据 + 过敏原 + 已解锁成就）
    ///
    /// 删除：
    /// - Favorite / DrawRecord / UserTaskRecord（全部用户产生的记录）
    /// - UserProfile 累积统计：drawsToday / lastDrawDate / lastResetDate
    /// - UserProfile 偏好：preferredStyles / preferredCategories / preferredBrands
    ///
    /// 保留：
    /// - Card / CardPool / DecisionScene（App 内置，由 SeedService 种入；isUserCreated == false）
    /// - UserProfile.allergens（D088 安全相关，绝不动）
    /// - UserProfile.id / createdAt / debugModeEnabled / earnedAchievements（壳子 + 状态）
    ///
    /// 不触发 SeedService（profile 仍在，seedIfNeeded 因 `existingProfiles == 0` 不满足而跳过）。
    private func clearUsageData() {
        for fav in allFavorites { modelContext.delete(fav) }
        for rec in allDrawRecords { modelContext.delete(rec) }
        for rec in allTaskRecords { modelContext.delete(rec) }

        for profile in profiles {
            profile.drawsToday = 0
            profile.lastDrawDate = nil
            profile.lastResetDate = Date()
            profile.preferredStyles = []
            profile.preferredCuisines = []
            profile.preferredCategories = []
            profile.preferredBrands = []
            profile.updatedAt = Date()
        }

        try? modelContext.save()
    }

    private func clearAllData() {
        // 删除所有数据（含 profile），让 SeedService.seedIfNeeded 触发（它检查 profile count == 0）
        for card in allCards { modelContext.delete(card) }
        for fav in allFavorites { modelContext.delete(fav) }
        for rec in allDrawRecords { modelContext.delete(rec) }
        for rec in allTaskRecords { modelContext.delete(rec) }
        for scene in allScenes {
            for pool in scene.cardPools {
                modelContext.delete(pool)
            }
            modelContext.delete(scene)
        }
        for profile in profiles {
            modelContext.delete(profile)
        }
        try? modelContext.save()
        // 重新播种（异步，避免阻塞）
        Task { @MainActor in
            SeedService.seedIfNeeded(context: modelContext)
        }
    }

    /// 重置今日抽签次数（D132 跨午夜）—— 调试快捷按钮
    private func resetDrawsToday() {
        for profile in profiles {
            profile.drawsToday = 0
            profile.lastDrawDate = nil
            profile.updatedAt = Date()
        }
        try? modelContext.save()
    }

    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "onboardingCompleted")
    }

    private func closeDebugMode() {
        for profile in profiles {
            profile.debugModeEnabled = false
            profile.updatedAt = Date()
        }
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Build info

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - 子组件

private struct DebugStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(Font.theme.callout)
                .foregroundStyle(Color.theme.textSecondary)
        }
    }
}

#Preview {
    DebugPanelView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}