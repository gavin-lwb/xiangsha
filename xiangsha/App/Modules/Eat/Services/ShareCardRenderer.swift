//
//  ShareCardRenderer.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D037（1024×1024 分享卡 · ImageRenderer）+ D038（预设文案 5 套）
//

import SwiftUI
import UIKit

/// 分享卡渲染器（D037 · D038）
///
/// 用 SwiftUI ImageRenderer 把分享卡视图渲染成 PNG（1024×1024）。
/// 文案从 5 套预设（D038 治愈/幽默/简洁/反鸡汤/留空）里随机选一套。
@MainActor
struct ShareCardRenderer {
    let card: Card
    let style: ShareCardStyle

    /// 渲染成 PNG Data
    func render() -> Data? {
        let view = ShareCardView(card: card, style: style)
            .frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage?.pngData()
    }

    /// 渲染成 UIImage（用于预览）
    func renderImage() -> UIImage? {
        let view = ShareCardView(card: card, style: style)
            .frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

/// D038 · 分享文案风格（5 套）
enum ShareCardStyle: String, CaseIterable {
    case healing    // 治愈
    case funny      // 幽默
    case concise    // 简洁
    case antiChickenSoup  // 反鸡汤
    case blank      // 留空

    /// 中文文案
    var caption: String {
        switch self {
        case .healing: return "今天的小确幸，就从这一口开始 🦊"
        case .funny: return "🦊 替本狐狸的小脑袋做了个艰难的决定"
        case .concise: return "今天吃这个。"
        case .antiChickenSoup: return "别问为什么，问就是小狐狸随机选的"
        case .blank: return ""
        }
    }

    /// 随机选一个（不包含 blank 的概率更高）
    static func random(includeBlank: Bool = false) -> ShareCardStyle {
        let pool: [ShareCardStyle] = includeBlank ? ShareCardStyle.allCases : ShareCardStyle.allCases.filter { $0 != .blank }
        return pool.randomElement() ?? .concise
    }
}

/// 分享卡视图（1024×1024）
private struct ShareCardView: View {
    let card: Card
    let style: ShareCardStyle

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.theme.accent.opacity(0.3), Color.theme.accentSubtle],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                // emoji
                Text(card.emoji ?? "🎴")
                    .font(.system(size: 200))

                // 标题
                Text(card.displayTitle)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)

                // 元数据
                HStack(spacing: 32) {
                    Label("\(card.timeMinutes) 分钟", systemImage: "clock.fill")
                    Label(difficultyText(card.difficulty), systemImage: "chart.bar.fill")
                }
                .font(.system(size: 28))
                .foregroundStyle(Color.theme.textSecondary)

                // 文案
                if !style.caption.isEmpty {
                    Text(style.caption)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)
                        .padding(.top, 40)
                }

                Spacer()

                // 水印
                HStack(spacing: 12) {
                    Text("🦊")
                        .font(.system(size: 40))
                    Text("想吃啥 · 小狐狸替你选")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func difficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "⭐"
        case 2: return "⭐⭐"
        case 3: return "⭐⭐⭐"
        case 4: return "⭐⭐⭐⭐"
        case 5: return "⭐⭐⭐⭐⭐"
        default: return "—"
        }
    }
}
