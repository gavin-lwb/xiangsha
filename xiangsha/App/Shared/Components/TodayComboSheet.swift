//
//  TodayComboSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D121 跨场景联动 + UX Pattern 6 底部抽屉
//

import SwiftUI
import SwiftData

/// 今日组合底部抽屉（Pattern 6）
///
/// 显示今天 3 个场景的随机推荐：
/// - 吃啥（推荐一餐）
/// - 玩啥（推荐一个活动）
/// - 拍啥（推荐一个姿势）
struct TodayComboSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var eatCard: Card?
    @State private var playCard: Card?
    @State private var photoCard: Card?

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.theme.textSecondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, ThemeSpacing.sm)
                .padding(.bottom, ThemeSpacing.md)

            VStack(spacing: ThemeSpacing.xxs) {
                Text("🦊")
                    .font(.system(size: 36))
                Text("今日组合")
                    .font(Font.theme.title1)
                    .foregroundStyle(Color.theme.textPrimary)
                Text("吃啥 + 玩啥 + 拍啥 一套")
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(.bottom, ThemeSpacing.md)

            Divider()
                .padding(.horizontal, ThemeSpacing.lg)

            ScrollView {
                VStack(spacing: ThemeSpacing.sm) {
                    ComboCardRow(sceneType: .eat, card: eatCard, onTap: { dismiss() })
                    ComboCardRow(sceneType: .play, card: playCard, onTap: { dismiss() })
                    ComboCardRow(sceneType: .photo, card: photoCard, onTap: { dismiss() })
                }
                .padding(.horizontal, ThemeSpacing.lg)
                .padding(.vertical, ThemeSpacing.md)
            }

            Button {
                dismiss()
            } label: {
                Text("关闭")
                    .font(Font.theme.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.textOnPrimary)
            }
            .padding(.horizontal, ThemeSpacing.lg)
            .padding(.bottom, ThemeSpacing.lg)
        }
        .background(Color.theme.background)
        .task {
            eatCard = randomCard(for: .eat)
            playCard = randomCard(for: .play)
            photoCard = randomCard(for: .photo)
        }
    }

    private func randomCard(for sceneType: DecisionSceneType) -> Card? {
        let rawValue = sceneType.rawValue
        let descriptor = FetchDescriptor<DecisionScene>(
            predicate: #Predicate { $0.typeRaw == rawValue }
        )
        guard let scene = try? modelContext.fetch(descriptor).first else { return nil }
        let cards = scene.cardPools.flatMap { $0.cards }.filter { !$0.isHidden }
        return cards.randomElement()
    }
}

private struct ComboCardRow: View {
    let sceneType: DecisionSceneType
    let card: Card?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ThemeSpacing.sm) {
                Image(systemName: sceneType.icon)
                    .font(.title2)
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ThemeSpacing.xs) {
                        Text(sceneType.title)
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.accent)
                        Text("·")
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                        Text("今天试试")
                            .font(Font.theme.caption2)
                            .foregroundStyle(Color.theme.textSecondary)
                    }

                    if let card {
                        HStack(spacing: 4) {
                            if let emoji = card.emoji {
                                Text(emoji).font(.title3)
                            }
                            Text(card.displayTitle)
                                .font(Font.theme.bodyEmphasis)
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                    } else {
                        Text("加载中…")
                            .font(Font.theme.body)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding()
            .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.md)
                    .stroke(Color.theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
