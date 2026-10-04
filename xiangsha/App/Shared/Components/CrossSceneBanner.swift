//
//  CrossSceneBanner.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D121（v1 基础联动）
//

import SwiftUI

/// 跨场景联动 Banner（D121 v1 基础）
///
/// 在抽签结果下方显示一条"今天也可以..."的推荐，点击切换到目标 Tab。
struct CrossSceneBanner: View {
    let sourceScene: DecisionSceneType
    let targetScene: DecisionSceneType
    let suggestedCardTitle: String
    let suggestedCardEmoji: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ThemeSpacing.sm) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title3)
                    .foregroundStyle(Color.theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(CrossSceneLinkService.suggestionText(
                        from: sourceScene,
                        to: targetScene,
                        cardTitle: suggestedCardTitle
                    ))
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)

                    HStack(spacing: 4) {
                        if let emoji = suggestedCardEmoji {
                            Text(emoji)
                        }
                        Text(suggestedCardTitle)
                            .font(Font.theme.bodyEmphasis)
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding()
            .background(
                Color.theme.accentSubtle,
                in: RoundedRectangle(cornerRadius: ThemeRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.md)
                    .stroke(Color.theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityLabel("\(targetScene.title)：\(suggestedCardTitle)")
        .accessibilityHint("点击切换到\(targetScene.title)")
    }
}

/// 跨场景联动请求（用于跨 Tab 切换 + 预填推荐）
struct CrossSceneLinkRequest: Identifiable, Equatable {
    let id: UUID = UUID()
    let targetScene: DecisionSceneType
    let suggestedCard: Card
    let timestamp: Date = Date()

    static func == (lhs: CrossSceneLinkRequest, rhs: CrossSceneLinkRequest) -> Bool {
        lhs.id == rhs.id
    }
}