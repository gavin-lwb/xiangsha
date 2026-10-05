//
//  V1RoadmapSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D047（食材反向查询 v1.1）+ D056（营养均衡 v1.1）+ 整体 v1 占位 Toast 集合
//

import SwiftUI

/// v1.1 Roadmap Sheet
///
/// 列出 v1 还没实现、计划在 v1.1 上线的功能（D047 / D056 等）
/// 现状是占位卡片，点击不响应，仅展示 + 让用户知道"我们在做"
struct V1RoadmapSheet: View {
    @Environment(\.dismiss) private var dismiss

    private static let items: [RoadmapItem] = [
        RoadmapItem(
            decision: "D047",
            icon: "🔍",
            title: "食材反向查询",
            description: "「我家有鸡蛋 + 青椒 + 豆腐」 → 推荐能做啥",
            status: "v1.1 规划"
        ),
        RoadmapItem(
            decision: "D056",
            icon: "🥗",
            title: "营养均衡推荐",
            description: "今日已摄入的营养 vs 建议值 → 推荐补啥",
            status: "v1.1 规划"
        ),
        RoadmapItem(
            decision: "D063",
            icon: "📍",
            title: "附近活动 / 餐厅",
            description: "基于位置的活动推荐（玩啥/吃啥 联动）",
            status: "v1.1 规划"
        ),
        RoadmapItem(
            decision: "D047 / D092",
            icon: "📓",
            title: "决策日记",
            description: "记录每次抽签 + 心情，长期看自己的偏好变化",
            status: "v1.1 规划"
        ),
        RoadmapItem(
            decision: "v1.x",
            icon: "🔁",
            title: "Routine（每日固定 + 偶尔变化）",
            description: "区分「今天想吃新东西」 vs 「就那个老样子」",
            status: "v1.2+ 调研"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ThemeSpacing.md) {
                    // 头部说明
                    VStack(spacing: ThemeSpacing.xs) {
                        Text("🦊")
                            .font(.system(size: 48))
                        Text("v1 之后的规划")
                            .font(Font.theme.title1)
                            .foregroundStyle(Color.theme.textPrimary)
                        Text("下面是 v1 没来得及做、准备在 v1.1 上线的功能")
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, ThemeSpacing.md)
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Roadmap items
                    ForEach(Self.items) { item in
                        RoadmapItemRow(item: item)
                    }
                    .padding(.horizontal)

                    Spacer().frame(height: ThemeSpacing.lg)
                }
            }
            .background(Color.theme.background)
            .navigationTitle("v1.1 Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

private struct RoadmapItem: Identifiable {
    let id = UUID()
    let decision: String
    let icon: String
    let title: String
    let description: String
    let status: String
}

private struct RoadmapItemRow: View {
    let item: RoadmapItem

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            HStack(spacing: ThemeSpacing.sm) {
                Text(item.icon)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.title)
                            .font(Font.theme.bodyEmphasis)
                            .foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Text(item.status)
                            .font(Font.theme.caption2)
                            .padding(.horizontal, ThemeSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.theme.accentSubtle, in: Capsule())
                            .foregroundStyle(Color.theme.accent)
                    }
                    Text(item.decision)
                        .font(Font.theme.caption2)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }

            Text(item.description)
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)
                .padding(.leading, ThemeSpacing.lg)
        }
        .padding()
        .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.md)
                .stroke(Color.theme.border.opacity(0.5), lineWidth: 1)
        )
    }
}
