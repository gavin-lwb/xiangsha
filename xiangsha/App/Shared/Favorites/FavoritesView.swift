//
//  FavoritesView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D019（收藏夹组织）+ D036（收藏权重）+ D016（不喜欢此卡）
//

import SwiftUI
import SwiftData

/// 收藏列表视图（基础版）
///
/// D019：按 favoritedAt 倒序；v1.1+ 加分组 / 搜索 / 备注
struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Favorite.favoritedAt, order: .reverse)
    private var favorites: [Favorite]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    EmptyFavoritesView()
                } else {
                    List {
                        ForEach(favorites) { favorite in
                            FavoriteRowView(favorite: favorite)
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        // v1 占位：v1.1+ 接 @Environment(\.modelContext) 删除
    }
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