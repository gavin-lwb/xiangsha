//
//  HistoryView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D020-D024（历史）+ SPEC §10.6（最近 1000 滚动）
//

import SwiftUI
import SwiftData

/// 历史记录视图（基础版）
///
/// D020：按 createdAt 倒序，最近 1000 条（§10.6）
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \DrawRecord.createdAt, order: .reverse)
    private var records: [DrawRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(records) { record in
                            HistoryRowView(record: record)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }
}

private struct HistoryRowView: View {
    let record: DrawRecord

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            actionIcon
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: ThemeSpacing.xxs) {
                Text(record.card?.displayTitle ?? "(已删除)")
                    .font(Font.theme.body)
                    .foregroundStyle(Color.theme.textPrimary)

                HStack(spacing: ThemeSpacing.xs) {
                    Text(record.action.title)
                        .font(Font.theme.caption)
                        .foregroundStyle(actionColor)
                    Text("·")
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(relativeTime)
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, ThemeSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.action.title)：\(record.card?.displayTitle ?? "")")
    }

    private var actionIcon: some View {
        Group {
            switch record.action {
            case .accept:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.theme.success)
            case .reject:
                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.theme.danger)
            case .redraw:
                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Color.theme.textSecondary)
            case .skip:
                Image(systemName: "moon.zzz.fill").foregroundStyle(Color.theme.textSecondary)
            }
        }
    }

    private var actionColor: Color {
        switch record.action {
        case .accept: return Color.theme.success
        case .reject: return Color.theme.danger
        default: return Color.theme.textSecondary
        }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: record.createdAt, relativeTo: Date())
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Text("🦊")
                .font(.system(size: 80))
            Text("还没有历史")
                .font(Font.theme.title3)
            Text("抽签后会自动记录")
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}