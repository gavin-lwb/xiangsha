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
            Button(action: clearAllData) {
                Label("清空所有数据", systemImage: "trash.fill")
                    .foregroundStyle(Color.theme.danger)
            }
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
            Text("清空数据后下次启动会重新播种 180 张卡")
                .font(Font.theme.caption)
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

    private func clearAllData() {
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
            profile.drawsToday = 0
            profile.earnedAchievements = []
            profile.debugModeEnabled = false
            profile.updatedAt = Date()
        }
        try? modelContext.save()
        // 重新播种
        SeedService.seedIfNeeded(context: modelContext)
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