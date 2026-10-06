//
//  DrawAnimationView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  UX 改进：抽取动画全屏页 + 揭幕效果
//

import SwiftUI
import SwiftData

/// 抽取动画全屏页（吃啥 Tab 用）
///
/// 3 阶段：
/// 1. **loading**（0.8s）：🦊 旋转 + "让小狐狸想想…🦊"
/// 2. **reveal**（scale 0.6→1.0 + opacity 0→1）：emoji + 标题揭幕
/// 3. **result**：完整卡片 + 评分 + 我做过 + 分享 + 主/次按钮
///
/// 承接所有 action：
/// - 评分（D135）：emoji 3 选 1
/// - 我做过（D045）：写 UserCookedRecord
/// - 分享（D037）：打开 ShareCardSheet
/// - 接受：accept + dismiss
/// - 拒绝：reject + dismiss
struct DrawAnimationView: View {
    let card: Card?       // 抽取结果（nil = 还在抽）
    let isLoading: Bool    // 是否还在 loading
    let isCooked: Bool     // 是否已做过
    let onAccept: () -> Void
    let onReject: () -> Void
    let onRate: (EmojiRating) -> Void
    let onMarkCooked: () -> Void
    let onShare: () -> Void
    let onCookRecipe: () -> Void
    let onDismiss: () -> Void

    @State private var stage: Stage = .loading
    @State private var emojiScale: CGFloat = 0.6
    @State private var emojiOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var selectedRating: EmojiRating?
    /// 动画序列 Task（多次抽取时 cancel 上一个避免 race）
    @State private var animTask: Task<Void, Never>?

    enum Stage { case loading, reveal, result }

    var body: some View {
        ZStack {
            // 背景渐变（按结果 emoji 切换冷暖色）
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: ThemeSpacing.xl) {
                Spacer()

                // 顶部标题
                Text(stageTitle)
                    .font(Font.theme.title1)
                    .foregroundStyle(Color.theme.textPrimary)
                    .padding(.top, ThemeSpacing.huge)

                Spacer()

                // emoji 区域
                emojiArea

                // 标题 / 文案
                if stage != .loading, let card {
                    Text(card.displayTitle)
                        .font(Font.theme.heroTitle)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)
                        .padding(.horizontal, ThemeSpacing.xl)
                        .opacity(titleOpacity)
                        .animation(.easeIn(duration: 0.4).delay(0.3), value: titleOpacity)

                    // 元数据
                    HStack(spacing: ThemeSpacing.md) {
                        Label("\(card.timeMinutes) 分钟", systemImage: "clock.fill")
                        Label(difficultyText(card.difficulty), systemImage: "chart.bar.fill")
                    }
                    .font(Font.theme.callout)
                    .foregroundStyle(Color.theme.textSecondary)
                    .opacity(titleOpacity)
                    .animation(.easeIn(duration: 0.4).delay(0.4), value: titleOpacity)
                }

                Spacer()

                // 底部按钮（按阶段切换）
                bottomButtons
                    .padding(.horizontal, ThemeSpacing.lg)
                    .padding(.bottom, ThemeSpacing.xl)
            }
        }
        // 关键修复：用 .onChange(of: card) 替代 .task(id: card?.id ?? UUID())
        // 原因：之前 card 为 nil 时用 UUID() 兜底，card 后续变化时 .task 不会重启
        // 导致 stage 走完 loading→reveal→result 时 card 仍是 nil，看不到内容
        .onChange(of: card?.id) { _, newID in
            if newID != nil {
                startAnimation()
            }
        }
        .onAppear {
            // 第一次进入时如果 card 已有值，立即启动动画
            if card != nil {
                startAnimation()
            }
        }
    }

    /// 启动完整动画序列（重置 + loading → reveal → result）
    private func startAnimation() {
        // 关键：cancel 上一个未完成的 task，避免多次抽取时 Task race
        // 导致 stage 永远卡 loading（之前的 sleep 跑到一半被新 task 覆盖）
        animTask?.cancel()

        // 重置所有 stage 状态
        emojiScale = 0.6
        emojiOpacity = 0
        titleOpacity = 0
        stage = .loading

        // 启动 loading 动画（旋转 + 呼吸）
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            loadingScale = 1.15
        }
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            spinAngle = 360
        }

        // 顺序推进 stage（用 Task 异步 sleep）
        animTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            if Task.isCancelled { return }
            stage = .reveal
            emojiScale = 1.0
            emojiOpacity = 1.0
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                emojiScale = 1.0
                emojiOpacity = 1.0
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            if Task.isCancelled { return }
            stage = .result
            withAnimation(.easeIn(duration: 0.3)) {
                titleOpacity = 1.0
            }
        }
    }

    // MARK: - 子视图

    @ViewBuilder
    private var emojiArea: some View {
        ZStack {
            if stage == .loading {
                // Loading 动画：🦊 旋转 + 呼吸（repeatForever 通过 .animation + 自身值递增）
                Text("🦊")
                    .font(.system(size: 120))
                    .rotationEffect(.degrees(spinAngle))
                    .scaleEffect(loadingScale)
                    .onAppear {
                        // 启动持续旋转
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            loadingScale = 1.15
                        }
                    }
            } else if let card {
                // 结果 emoji：揭幕 scale + opacity（用 .animation(value:) 自动动画）
                Text(card.emoji ?? "🎴")
                    .font(.system(size: 180))
                    .scaleEffect(emojiScale)
                    .opacity(emojiOpacity)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65), value: emojiScale)
                    .animation(.easeIn(duration: 0.3), value: emojiOpacity)
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        switch stage {
        case .loading:
            EmptyView()
        case .reveal:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.theme.accent)
        case .result:
            VStack(spacing: ThemeSpacing.sm) {
                // D135 · emoji 评分
                HStack(spacing: ThemeSpacing.md) {
                    ForEach([EmojiRating.like, .neutral, .dislike], id: \.self) { rating in
                        Button {
                            selectedRating = rating
                            onRate(rating)
                        } label: {
                            Text(rating.rawValue)
                                .font(.system(size: 36))
                                .scaleEffect(selectedRating == rating ? 1.25 : 1.0)
                                .opacity(selectedRating == nil || selectedRating == rating ? 1.0 : 0.4)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ThemeSpacing.sm)
                                .background(
                                    selectedRating == rating ? Color.theme.accentSubtle : Color.theme.surface,
                                    in: RoundedRectangle(cornerRadius: ThemeRadius.md)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ThemeSpacing.sm)

                // D044 · 看菜谱按钮（仅 hasRecipe 时）
                if let card, card.recipe != nil {
                    Button(action: {
                        onCookRecipe()
                    }) {
                        HStack {
                            Image(systemName: "book.closed.fill")
                            Text("🍳 看菜谱 / 开始做")
                        }
                        .font(Font.theme.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.sm)
                        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // D045 · 我做过 / D037 · 分享
                HStack(spacing: ThemeSpacing.md) {
                    Button(action: {
                        onMarkCooked()
                    }) {
                        HStack {
                            Image(systemName: isCooked ? "checkmark.seal.fill" : "checkmark.circle")
                            Text(isCooked ? "已做过" : "✅ 我做过")
                        }
                        .font(Font.theme.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.sm)
                        .background(Color.theme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(isCooked ? Color.theme.textSecondary : Color.theme.success)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCooked)

                    Button(action: {
                        onShare()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("📤 分享")
                        }
                        .font(Font.theme.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.sm)
                        .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                        .foregroundStyle(Color.theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // 主接受
                Button(action: {
                    onAccept()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("就这个了 ✅")
                    }
                    .font(Font.theme.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.textOnPrimary)
                }
                .padding(.horizontal)

                // 次按钮
                Button(action: {
                    onReject()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("换一个 🔁")
                    }
                    .font(Font.theme.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ThemeSpacing.sm)
                    .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.textPrimary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - 状态

    @State private var loadingScale: CGFloat = 1.0
    @State private var spinAngle: Double = 0

    private var stageTitle: String {
        switch stage {
        case .loading: return "让小狐狸想想…🦊"
        case .reveal: return "惊喜来了！"
        case .result:
            if let card {
                return "今天就吃「\(card.displayTitle)」"
            }
            return "完成！"
        }
    }

    private var backgroundColors: [Color] {
        switch stage {
        case .loading:
            return [Color.theme.accentSubtle.opacity(0.5), Color.theme.background]
        case .reveal, .result:
            return [Color.theme.accent.opacity(0.2), Color.theme.accentSubtle]
        }
    }

    private func difficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "⭐"
        case 2: return "⭐⭐"
        case 3: return "⭐⭐⭐"
        case 4: return "⭐⭐⭐⭐"
        case 5: return "⭐⭐⭐⭐⭐"
        default: return ""
        }
    }

    // MARK: - 动画推进

    // advanceToReveal 不再用（stage 推进在 .task 里直接赋值）
    private func advanceToReveal() {
        // 保留作 fallback（如果有代码还在调用）
        stage = .reveal
        emojiScale = 1.0
        emojiOpacity = 1.0
    }
}
