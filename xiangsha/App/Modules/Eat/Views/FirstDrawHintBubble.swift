//
//  FirstDrawHintBubble.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D092（引导式首抽气泡「🦊 喜欢吗？不满意点换一签，或长按标记不喜欢」）
//

import SwiftUI

/// 首抽引导气泡（D092）
///
/// 用户首次抽到结果时显示，文案：
/// "🦊 喜欢吗？不满意点换一签，或长按标记不喜欢"
///
/// 点击「✓ 知道了」→ dismiss + 持久化（UserDefaults）
struct FirstDrawHintBubble: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            HStack(spacing: ThemeSpacing.xs) {
                Text("🦊")
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 4) {
                    Text("喜欢吗？")
                        .font(Font.theme.bodyEmphasis)
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("不满意点换一签，或长按标记不喜欢")
                        .font(Font.theme.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                Spacer()
            }

            Button {
                onDismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("知道了")
                }
                .font(Font.theme.bodyEmphasis)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ThemeSpacing.sm)
                .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.sm))
                .foregroundStyle(Color.theme.textOnPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.md)
                    .fill(Color.theme.surface)
                RoundedRectangle(cornerRadius: ThemeRadius.md)
                    .stroke(Color.theme.accent, lineWidth: 2)
            }
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .padding(.horizontal)
    }
}

/// 首抽气泡持久化辅助（D092）
enum FirstDrawHintStore {
    private static let key = "hasSeenFirstDrawHint_eat"

    static var hasSeen: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
