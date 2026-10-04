//
//  FavoritesView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D019（收藏夹组织 · 按场景分组）+ D036（收藏权重）+ D016（不喜欢此卡）
//

import SwiftUI
import SwiftData

/// 收藏列表视图（A5 · 按场景分组 + 按时间倒序）
///
/// D019：按场景分组（吃啥 / 玩啥 / 做啥 / 拍啥），组内按 favoritedAt 倒序
struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Favorite.favoritedAt, order: .reverse)
    private var favorites: [Favorite]

    @State private var groupByScene: Bool = true

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    EmptyFavoritesView()
                } else if groupByScene {
                    groupedList
                } else {
                    flatList
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !favorites.isEmpty {
                        Button {
                            groupByScene.toggle()
                        } label: {
                            Image(systemName: groupByScene ? "list.bullet" : "rectangle.grid.2x2")
                        }
                        .accessibilityLabel(groupByScene ? "切换为平铺视图" : "切换为分组视图")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }

    /// 平铺列表
    private var flatList: some View {
        List {
            ForEach(favorites) { favorite in
                FavoriteRowView(favorite: favorite)
            }
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(.plain)
    }

    /// 按场景分组
    private var groupedList: some View {
        List {
            ForEach(groupedFavorites(), id: \.sceneType) { group in
                Section {
                    ForEach(group.favorites, id: \.id) { favorite in
                        FavoriteRowView(favorite: favorite)
                    }
                    .onDelete { offsets in
                        deleteFavorites(at: offsets, in: group.favorites)
                    }
                } header: {
                    HStack {
                        Image(systemName: group.sceneType.icon)
                            .foregroundStyle(Color.theme.accent)
                        Text(group.sceneType.title)
                            .font(Font.theme.title3)
                            .foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Text("\(group.favorites.count)")
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// 按场景分组
    private func groupedFavorites() -> [FavoriteGroup] {
        let groups = Dictionary(grouping: favorites) { fav -> DecisionSceneType in
            fav.card?.scene?.type ?? .eat
        }
        // 按 v1Scenes 顺序排序
        return DecisionSceneType.v1Scenes.compactMap { sceneType in
            guard let favs = groups[sceneType], !favs.isEmpty else { return nil }
            return FavoriteGroup(sceneType: sceneType, favorites: favs)
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        deleteFavorites(at: offsets, in: favorites)
    }

    private func deleteFavorites(at offsets: IndexSet, in source: [Favorite]) {
        for index in offsets {
            let fav = source[index]
            // 实际删除需要 modelContext，这里留待 v1.1+ 接 ModelContext
            _ = fav
        }
    }
}

/// 收藏分组（按场景）
private struct FavoriteGroup {
    let sceneType: DecisionSceneType
    let favorites: [Favorite]
}

private struct FavoriteRowView: View {
    let favorite: Favorite

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            if let emoji = favorite.card?.emoji {
                Text(emoji)
                    .font(.system(size: 32))
            } else {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.theme.accent)
            }

            VStack(alignment: .leading, spacing: ThemeSpacing.xxs) {
                Text(favorite.card?.displayTitle ?? "(已删除)")
                    .font(Font.theme.body)
                    .foregroundStyle(Color.theme.textPrimary)

                Text(favoritedAtText)
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, ThemeSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("收藏：\(favorite.card?.displayTitle ?? "")")
    }

    private var favoritedAtText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: favorite.favoritedAt, relativeTo: Date())
    }
}

private struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Text("🦊")
                .font(.system(size: 80))
            Text("还没有收藏")
                .font(Font.theme.title3)
            Text("抽到心头好后点「⭐ 收藏」")
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
            Text("按场景分组 · 按时间倒序")
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)
                .padding(.top, ThemeSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}