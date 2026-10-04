//
//  CelebrationToast.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D097（成就系统）+ fox-persona §12
//

import SwiftUI

/// 成就解锁庆祝 Toast（D097）
///
/// 顶部滑入 + 抖动 + 自动消失
struct CelebrationToast: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundStyle(Color.theme.warning)
                .symbolEffect(.bounce, value: isVisible)

            VStack(alignment: .leading, spacing: 2) {
                Text("🎉 \(achievement.title)")
                    .font(Font.theme.button)
                    .foregroundStyle(Color.theme.textPrimary)
                Text(achievement.unlockText)
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.md)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: ThemeShadow.lg, y: 4)
        )
        .padding(.horizontal, ThemeSpacing.md)
        .offset(y: isVisible ? 0 : -120)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            // 3 秒后自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
}

/// 通用顶部 Toast 列表展示器
struct CelebrationToastStack: View {
    @Binding var pendingAchievements: [Achievement]

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            ForEach(pendingAchievements) { achievement in
                CelebrationToast(achievement: achievement) {
                    pendingAchievements.removeAll { $0.id == achievement.id }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(!pendingAchievements.isEmpty)
    }
}