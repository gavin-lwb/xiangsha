//
//  ShareCardSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D037（分享卡 UI 入口）+ D038（5 套预设文案选择器）
//

import SwiftUI

/// 分享卡 sheet（D037 + D038）
///
/// 用户点「📤 分享」按钮后弹出：
/// - 分享卡预览（1024×1024 PNG ImageRenderer 输出）
/// - 文案选择器（5 套 D038）
/// - 「保存到相册」按钮
/// - 「系统分享」按钮（UIActivityViewController）
struct ShareCardSheet: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStyle: ShareCardStyle = .random()
    @State private var previewImage: UIImage?
    @State private var shareItems: [Any]? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: ThemeSpacing.md) {
                // 分享卡预览
                ZStack {
                    RoundedRectangle(cornerRadius: ThemeRadius.lg)
                        .fill(Color.theme.background)
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)

                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.lg))
                    } else {
                        ProgressView()
                    }
                }
                .padding(.horizontal)

                // 文案选择器（D038 5 套）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ThemeSpacing.xs) {
                        ForEach(ShareCardStyle.allCases, id: \.self) { style in
                            Button {
                                selectedStyle = style
                            } label: {
                                VStack(spacing: 4) {
                                    Text(styleCaption(style))
                                        .font(Font.theme.caption2)
                                        .multilineTextAlignment(.center)
                                    Text(styleName(style))
                                        .font(Font.theme.caption2)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }
                                .padding(.horizontal, ThemeSpacing.sm)
                                .padding(.vertical, ThemeSpacing.xs)
                                .background(
                                    selectedStyle == style ? Color.theme.accent : Color.theme.surface,
                                    in: RoundedRectangle(cornerRadius: ThemeRadius.sm)
                                )
                                .foregroundStyle(
                                    selectedStyle == style ? Color.theme.textOnPrimary : Color.theme.textPrimary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // 操作按钮
                VStack(spacing: ThemeSpacing.sm) {
                    Button {
                        renderForSharing()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("📤 系统分享")
                        }
                        .font(Font.theme.buttonLarge)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.textOnPrimary)
                    }

                    Button {
                        renderForSaving()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("💾 保存到相册")
                        }
                        .font(Font.theme.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.accent)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("分享")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                refreshPreview()
            }
            .onChange(of: selectedStyle) { _, _ in
                refreshPreview()
            }
            .sheet(isPresented: Binding(
                get: { shareItems != nil },
                set: { if !$0 { shareItems = nil } }
            )) {
                if let items = shareItems {
                    ActivityViewControllerWrapper(items: items)
                }
            }
        }
    }

    private func refreshPreview() {
        let renderer = ShareCardRenderer(card: card, style: selectedStyle)
        previewImage = renderer.renderImage()
    }

    private func renderForSharing() {
        let renderer = ShareCardRenderer(card: card, style: selectedStyle)
        guard let image = renderer.render() else { return }
        shareItems = [image]
    }

    private func renderForSaving() {
        let renderer = ShareCardRenderer(card: card, style: selectedStyle)
        guard let image = renderer.renderImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func styleCaption(_ style: ShareCardStyle) -> String {
        switch style {
        case .healing: return "今天的小确幸"
        case .funny: return "🦊 替小脑袋做决定"
        case .concise: return "今天吃这个。"
        case .antiChickenSoup: return "别问为什么"
        case .blank: return "（留空）"
        }
    }

    private func styleName(_ style: ShareCardStyle) -> String {
        switch style {
        case .healing: return "治愈"
        case .funny: return "幽默"
        case .concise: return "简洁"
        case .antiChickenSoup: return "反鸡汤"
        case .blank: return "无"
        }
    }
}

/// UIActivityViewController SwiftUI 包装
struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
