//
//  CookedProgressView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D046（进度数字「已解锁 X/80」）
//

import SwiftUI

/// 已解锁进度（D046）
///
/// 显示用户已"做过"的卡片数 / 当前 Eat Scene 的卡片总数。
/// 计算方式：UserCookedRecord 去重后的 cardID 数量。
struct CookedProgressView: View {
    let cookedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xxs) {
            HStack(spacing: ThemeSpacing.xs) {
                Image(systemName: "rosette")
                    .foregroundStyle(Color.theme.accent)
                Text("已解锁")
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text("\(cookedCount) / \(totalCount)")
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textPrimary)
            }

            ProgressView(value: Double(cookedCount), total: Double(max(totalCount, 1)))
                .tint(Color.theme.accent)
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.vertical, ThemeSpacing.xs)
        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }
}
