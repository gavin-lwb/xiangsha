//
//  CardDetailSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D140 v1 占位方案 + D041 菜谱字段 + D044 TaskRunner
//

import SwiftUI

/// 卡片详情底部抽屉（D041 · 含菜谱概览）
///
/// 点击抽签结果时弹出，展示：
/// - 大 emoji + 标题
/// - 场景 / 品牌 / 时间 / 难度等元数据
/// - 过敏原清单
/// - 菜谱概览（食材 + 步骤摘要）
/// - 「🍳 看菜谱」按钮（仅 recipe != nil 时显示）→ 跳转 RecipeTaskRunner
struct CardDetailSheet: View {
    let card: Card
    let sceneType: DecisionSceneType
    let onStartCooking: ((Card) -> Void)?
    let onDelete: ((Card) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm: Bool = false

    init(
        card: Card,
        sceneType: DecisionSceneType,
        onStartCooking: ((Card) -> Void)? = nil,
        onDelete: ((Card) -> Void)? = nil
    ) {
        self.card = card
        self.sceneType = sceneType
        self.onStartCooking = onStartCooking
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // 拖动指示条
            Capsule()
                .fill(Color.theme.textSecondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, ThemeSpacing.sm)
                .padding(.bottom, ThemeSpacing.md)

            ScrollView {
                VStack(spacing: ThemeSpacing.lg) {
                    // 大 emoji
                    Text(card.emoji ?? "🎴")
                        .font(.system(size: 96))
                        .padding(.top, ThemeSpacing.md)

                    // 标题
                    Text(card.displayTitle)
                        .font(Font.theme.heroTitle)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)

                    // 场景标签
                    HStack(spacing: ThemeSpacing.xs) {
                        Image(systemName: sceneType.icon)
                            .foregroundStyle(Color.theme.accent)
                        Text(sceneType.title)
                            .font(Font.theme.callout)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .padding(.horizontal, ThemeSpacing.md)
                    .padding(.vertical, ThemeSpacing.xs)
                    .background(Color.theme.accentSubtle, in: Capsule())

                    Divider()
                        .padding(.horizontal, ThemeSpacing.lg)

                    // 元信息（D055 serves / D028 priceRange / D027 cuisine）
                    VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                        DetailRow(icon: "tag.fill", label: "类别", value: card.category ?? "—")
                        if let cuisine = card.cuisine {
                            DetailRow(icon: "fork.knife", label: "菜系", value: cuisine.title)
                        }
                        if let brand = card.brand {
                            DetailRow(icon: "building.2.fill", label: "品牌", value: brand)
                        }
                        if let price = card.priceRange {
                            DetailRow(icon: price.icon, label: "价位", value: price.title)
                        }
                        DetailRow(icon: "clock.fill", label: "预计时间", value: "\(card.timeMinutes) 分钟")
                        DetailRow(icon: "chart.bar.fill", label: "难度", value: difficultyText(card.difficulty))
                        if let serves = card.serves {
                            DetailRow(icon: "person.2.fill", label: "适合人数", value: "\(serves) 人")
                        }
                        DetailRow(icon: "calendar", label: "加入日期", value: card.createdAt.formatted(date: .abbreviated, time: .omitted))
                        if let cost = card.costLevel {
                            DetailRow(icon: "creditcard.fill", label: "费用", value: "\(cost.emoji) \(cost.title)")
                        }
                    }
                    .padding(.horizontal, ThemeSpacing.lg)

                    // 过敏原清单
                    if !card.allergens.isEmpty {
                        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.theme.warning)
                                Text("过敏原")
                                    .font(Font.theme.bodyEmphasis)
                                    .foregroundStyle(Color.theme.textPrimary)
                            }

                            FlowLayout(spacing: ThemeSpacing.xs) {
                                ForEach(card.allergens, id: \.self) { allergen in
                                    Text(allergen == "__none__" ? "无" : allergen)
                                        .font(Font.theme.caption)
                                        .padding(.horizontal, ThemeSpacing.sm)
                                        .padding(.vertical, ThemeSpacing.xxs)
                                        .background(Color.theme.warning.opacity(0.1), in: Capsule())
                                        .foregroundStyle(Color.theme.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal, ThemeSpacing.lg)
                    }

                    // 菜谱概览（D041 · 仅 recipe != nil 时显示）
                    if let recipe = card.recipe {
                        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(Color.theme.accent)
                                Text("菜谱")
                                    .font(Font.theme.bodyEmphasis)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Spacer()
                                Text("\(recipe.ingredients.count) 食材 · \(recipe.steps.count) 步")
                                    .font(Font.theme.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            // 食材前 3 个预览
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(recipe.ingredients.prefix(3).enumerated()), id: \.offset) { _, ing in
                                    HStack {
                                        Text("•")
                                            .foregroundStyle(Color.theme.accent)
                                        Text(ing)
                                            .font(Font.theme.caption)
                                            .foregroundStyle(Color.theme.textPrimary)
                                        Spacer()
                                    }
                                }
                                if recipe.ingredients.count > 3 {
                                    Text("…等 \(recipe.ingredients.count - 3) 项")
                                        .font(Font.theme.caption2)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }
                            }
                            .padding(.vertical, ThemeSpacing.xs)

                            // 「🍳 开始做」按钮（D044 → RecipeTaskRunner）
                            if let onStartCooking {
                                Button {
                                    onStartCooking(card)
                                } label: {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                        Text("🍳 开始做")
                                    }
                                    .font(Font.theme.buttonLarge)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ThemeSpacing.sm)
                                    .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                                    .foregroundStyle(Color.theme.textOnPrimary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.theme.accentSubtle.opacity(0.5), in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .padding(.horizontal, ThemeSpacing.lg)
                    }

                    Spacer().frame(height: ThemeSpacing.xl)
                }
            }

            // 底部关闭按钮
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

            // 用户自定义卡删除按钮
            if card.isUserCreated, let onDelete {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("🗑️ 删除这张卡")
                        .font(Font.theme.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.sm)
                        .background(Color.theme.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.danger)
                }
                .padding(.horizontal, ThemeSpacing.lg)
                .padding(.bottom, ThemeSpacing.lg)
                .confirmationDialog(
                    "删除「\(card.displayTitle)」？",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("删除", role: .destructive) {
                        onDelete(card)
                        dismiss()
                    }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("此操作不可撤销")
                }
            }
        }
        .background(Color.theme.background)
    }

    private func difficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "⭐ 简单"
        case 2: return "⭐⭐ 一般"
        case 3: return "⭐⭐⭐ 中等"
        case 4: return "⭐⭐⭐⭐ 困难"
        case 5: return "⭐⭐⭐⭐⭐ 极难"
        default: return "未指定"
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.accent)
                .frame(width: 20)
            Text(label)
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .font(Font.theme.bodyEmphasis)
                .foregroundStyle(Color.theme.textPrimary)
        }
    }
}

/// 简单 Flow 布局（chip 自动换行）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
