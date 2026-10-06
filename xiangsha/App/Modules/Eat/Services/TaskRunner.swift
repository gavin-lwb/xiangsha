//
//  TaskRunner.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D044（接受自动进入做菜模式 · TaskRunner / RecipeTaskRunner 全屏）
//

import Foundation
import SwiftUI

/// 任务执行器协议（D044）
///
/// 用户接受抽签结果后，进入"做"模式（做菜 / 完成任务 / 拍照）。
/// 不同的 card.type 对应不同的 TaskRunner 实现。
///
/// 注：协议只规定 card 属性，body 由 View 协议自动提供（避免重复声明警告）。
protocol TaskRunner: View {
    var card: Card { get }
}

/// 菜谱执行器（D044 · 在家做专用）
///
/// 全屏展示菜谱步骤：
/// - 食材清单
/// - 步骤（顺序）
/// - 当前步骤高亮
/// - 「✅ 我做完了」按钮 → 触发 onComplete callback
struct RecipeTaskRunner: TaskRunner {
    let card: Card
    let onComplete: (Card) -> Void
    let onDismiss: () -> Void

    @State private var currentStepIndex: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpacing.lg) {
                    // 标题 + emoji
                    HStack(spacing: ThemeSpacing.md) {
                        Text(card.emoji ?? "🍳")
                            .font(.system(size: 64))
                        VStack(alignment: .leading) {
                            Text(card.displayTitle)
                                .font(Font.theme.title1)
                            if let recipe = card.recipe {
                                Text(recipeSummary(recipe))
                                    .font(Font.theme.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, ThemeSpacing.md)

                    // 食材清单
                    if let recipe = card.recipe, !recipe.ingredients.isEmpty {
                        sectionView(title: "食材", icon: "cart.fill") {
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ing in
                                HStack {
                                    Text("•")
                                        .foregroundStyle(Color.theme.accent)
                                    Text(ing)
                                        .font(Font.theme.body)
                                    Spacer()
                                }
                            }
                        }
                    }

                    // 步骤
                    if let recipe = card.recipe, !recipe.steps.isEmpty {
                        sectionView(title: "步骤", icon: "list.number") {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                                StepRow(
                                    index: idx + 1,
                                    text: step,
                                    isCurrent: idx == currentStepIndex,
                                    isDone: idx < currentStepIndex
                                )
                                .onTapGesture {
                                    currentStepIndex = idx
                                }
                            }
                        }
                    } else {
                        Text("这道菜暂无详细步骤，请凭经验或自行搜索做法")
                            .font(Font.theme.body)
                            .foregroundStyle(Color.theme.textSecondary)
                            .padding(.horizontal)
                    }

                    Spacer().frame(height: ThemeSpacing.huge)
                }
            }
            .background(Color.theme.background)
            .navigationTitle("做菜模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { onDismiss() }
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: ThemeSpacing.sm) {
                    // 步骤导航
                    if let recipe = card.recipe, !recipe.steps.isEmpty {
                        HStack(spacing: ThemeSpacing.md) {
                            Button("上一步") {
                                if currentStepIndex > 0 { currentStepIndex -= 1 }
                            }
                            .disabled(currentStepIndex == 0)

                            Spacer()

                            Text("\(currentStepIndex + 1) / \(recipe.steps.count)")
                                .font(Font.theme.callout)
                                .foregroundStyle(Color.theme.textSecondary)

                            Spacer()

                            Button("下一步") {
                                if currentStepIndex < recipe.steps.count - 1 {
                                    currentStepIndex += 1
                                }
                            }
                            .disabled(currentStepIndex >= recipe.steps.count - 1)
                        }
                        .padding(.horizontal)
                    }

                    // 「✅ 我做完了」按钮
                    Button {
                        onComplete(card)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("✅ 我做完了")
                        }
                        .font(Font.theme.buttonLarge)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.success, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.textOnPrimary)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, ThemeSpacing.lg)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func recipeSummary(_ recipe: Recipe) -> String {
        var parts: [String] = []
        if let prep = recipe.prepTimeMinutes { parts.append("备料 \(prep) 分钟") }
        if let cook = recipe.cookTimeMinutes { parts.append("烹饪 \(cook) 分钟") }
        if let diff = recipe.difficulty { parts.append("难度 \(diff)/5") }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func sectionView<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack(spacing: ThemeSpacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(Color.theme.accent)
                Text(title)
                    .font(Font.theme.bodyEmphasis)
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                content()
            }
            .padding()
            .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
            .padding(.horizontal)
        }
    }
}

/// 步骤行
private struct StepRow: View {
    let index: Int
    let text: String
    let isCurrent: Bool
    let isDone: Bool

    var body: some View {
        HStack(alignment: .top, spacing: ThemeSpacing.sm) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 28, height: 28)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textOnPrimary)
                } else {
                    Text("\(index)")
                        .font(.caption)
                        .foregroundStyle(textColor)
                }
            }

            Text(text)
                .font(Font.theme.body)
                .foregroundStyle(isCurrent ? Color.theme.textPrimary : Color.theme.textSecondary)
                .strikethrough(isDone, color: Color.theme.textSecondary)
        }
    }

    private var backgroundColor: Color {
        if isDone { return Color.theme.success }
        if isCurrent { return Color.theme.accent }
        return Color.theme.accentSubtle
    }

    private var textColor: Color {
        if isCurrent { return Color.theme.textOnPrimary }
        return Color.theme.textPrimary
    }
}
