//
//  DrawAnimationView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  UX 改进：抽取动画全屏页 + 揭幕效果（TimelineView 时间驱动）
//
//  架构：用 TimelineView 每帧重算 + 时间派生 stage
//  - 不依赖任何 Task / DispatchQueue
//  - 多次抽取无 race condition（重置 animationStart 即可）
//  - card 变化触发新动画序列（reset start）
//

import SwiftUI
import SwiftData

/// 抽取动画全屏页（吃啥 Tab 用）
///
/// 3 阶段（时间驱动）：
/// 1. **loading**（0~800ms）：🦊 旋转 + "让小狐狸想想…🦊"
/// 2. **reveal**（800~1600ms）：emoji scale 0.6→1.0 + opacity 0→1
/// 3. **result**（1600ms 后）：完整卡片 + 评分 + 我做过 + 分享 + 主/次按钮
///
/// 多次抽取：仅重置 animationStart，旧 timeline 自动停止，无需手动 cancel。
struct DrawAnimationView: View {
    let card: Card?
    let isLoading: Bool
    let isCooked: Bool
    /// 抽签错误（如全被拒导致 .noCandidates）；error != nil 且 card == nil 时显示错误页
    let error: DrawEngineError?
    let onAccept: () -> Void
    let onReject: () -> Void
    let onRate: (EmojiRating) -> Void
    let onMarkCooked: () -> Void
    let onShare: () -> Void
    let onCookRecipe: () -> Void
    let onDismiss: () -> Void

    /// 动画起点（多次抽取时重置即可，时间驱动 stage）
    @State private var animationStart: Date?
    /// 评分选择
    @State private var selectedRating: EmojiRating?

    /// 阶段时长常量
    private let loadingDuration: TimeInterval = 0.8
    private let revealDuration: TimeInterval = 0.8
    private var totalDuration: TimeInterval { loadingDuration + revealDuration }

    enum Stage: Comparable {
        case loading, reveal, result

        /// 从 elapsed 时间推导当前阶段
        static func from(elapsed: TimeInterval, loading: TimeInterval, reveal: TimeInterval) -> Stage {
            if elapsed < loading { return .loading }
            if elapsed < loading + reveal { return .reveal }
            return .result
        }
    }

    var body: some View {
        // 关键：用 TimelineView 每帧重算 body
        // - stage 完全从 time 派生（不是 @State，无 race condition）
        // - card 变化只重置 animationStart → TimelineView 自动重新推进
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let elapsed = animationStart.map { timeline.date.timeIntervalSince($0) } ?? 0
            let stage = animationStart.map {
                Stage.from(elapsed: timeline.date.timeIntervalSince($0),
                           loading: loadingDuration,
                           reveal: revealDuration)
            } ?? .loading

            content(stage: stage, timeline: timeline.date)
        }
        // 关键触发：card 变化时重置 animationStart（时间驱动新动画）
        .onChange(of: card?.id) { _, newID in
            if newID != nil {
                animationStart = Date()
            }
        }
        // 第一次进入时如果 card 已有值也启动
        .onAppear {
            if card != nil, animationStart == nil {
                animationStart = Date()
            }
        }
    }

    /// 实际内容（每帧重算）
    @ViewBuilder
    private func content(stage: Stage, timeline: Date) -> some View {
        let elapsed = animationStart.map { timeline.timeIntervalSince($0) } ?? 0
        // emoji 动画进度（reveal 阶段从 0→1）
        let revealProgress = min(1.0, max(0.0, (elapsed - loadingDuration) / revealDuration))
        // 标题淡入进度（result 阶段从 0→1）
        let titleProgress = min(1.0, max(0.0, (elapsed - loadingDuration - revealDuration) / 0.3))
        // 旋转进度（loading 阶段连续旋转）
        let spinAngle = (elapsed * 360).truncatingRemainder(dividingBy: 360)
        let loadingScale = 1.0 + 0.15 * sin(elapsed * .pi * 1.25)

        ZStack {
            // 背景渐变
            LinearGradient(
                colors: error != nil && card == nil ? [Color.theme.danger.opacity(0.15), Color.theme.background] : backgroundColors(for: stage),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: ThemeSpacing.xl) {
                Spacer()

                // error 状态：显示错误页（0.8s 后自动 dismiss）
                if let error, card == nil {
                    VStack(spacing: ThemeSpacing.lg) {
                        Text("🦊")
                            .font(.system(size: 80))
                            .opacity(0.6)
                        Text(errorMessage(for: error))
                            .font(Font.theme.title1)
                            .foregroundStyle(Color.theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ThemeSpacing.xl)
                        Button(action: onDismiss) {
                            Text("知道了")
                                .font(Font.theme.buttonLarge)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                                .foregroundStyle(Color.theme.textOnPrimary)
                        }
                        .padding(.horizontal, ThemeSpacing.xl)
                        .padding(.top, ThemeSpacing.md)
                    }
                    .padding(.top, ThemeSpacing.huge)
                } else {
                    // 正常流程
                    Text(stageTitle(for: stage))
                        .font(Font.theme.title1)
                        .foregroundStyle(Color.theme.textPrimary)
                        .padding(.top, ThemeSpacing.huge)

                    Spacer()

                    // emoji 区域
                    emojiArea(stage: stage, revealProgress: revealProgress, spinAngle: spinAngle, loadingScale: loadingScale)

                    // 标题 / 文案
                    if stage != .loading, let card {
                        Text(card.displayTitle)
                            .font(Font.theme.heroTitle)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.theme.textPrimary)
                            .padding(.horizontal, ThemeSpacing.xl)
                            .opacity(titleProgress)

                        HStack(spacing: ThemeSpacing.md) {
                            Label("\(card.timeMinutes) 分钟", systemImage: "clock.fill")
                            Label(difficultyText(card.difficulty), systemImage: "chart.bar.fill")
                        }
                        .font(Font.theme.callout)
                        .foregroundStyle(Color.theme.textSecondary)
                        .padding(.top, ThemeSpacing.xs)
                        .opacity(titleProgress)
                    }

                    Spacer()

                    // 底部按钮（只在 result 阶段显示）
                    if stage == .result {
                        bottomButtons
                            .padding(.horizontal, ThemeSpacing.lg)
                    }
                }
            }
            .padding(.bottom, ThemeSpacing.xl)
        }
        // error != nil && card == nil → 0.8s 后自动 dismiss
        .onAppear {
            if error != nil && card == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onDismiss()
                }
            }
        }
    }

    // MARK: - 子视图

    @ViewBuilder
    private func emojiArea(stage: Stage, revealProgress: Double, spinAngle: Double, loadingScale: Double) -> some View {
        ZStack {
            if stage == .loading {
                // Loading 阶段：旋转 + 呼吸
                Text("🦊")
                    .font(.system(size: 120))
                    .rotationEffect(.degrees(spinAngle))
                    .scaleEffect(loadingScale)
            } else if let card {
                // 结果阶段：emoji 揭幕（scale 0.6→1.0, opacity 0→1）
                Text(card.emoji ?? "🎴")
                    .font(.system(size: 180))
                    .scaleEffect(0.6 + 0.4 * revealProgress)
                    .opacity(revealProgress)
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    private var bottomButtons: some View {
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
                Button(action: onCookRecipe) {
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
                Button(action: onMarkCooked) {
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

                Button(action: onShare) {
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

            // 主接受按钮
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

    // MARK: - 计算属性

    private func stageTitle(for stage: Stage) -> String {
        switch stage {
        case .loading: return "让小狐狸想想…🦊"
        case .reveal: return "惊喜来了！"
        case .result:
            if let card { return "今天就吃「\(card.displayTitle)」" }
            return "完成！"
        }
    }

    private func backgroundColors(for stage: Stage) -> [Color] {
        switch stage {
        case .loading:
            return [Color.theme.accentSubtle.opacity(0.5), Color.theme.background]
        case .reveal, .result:
            return [Color.theme.accent.opacity(0.2), Color.theme.accentSubtle]
        }
    }

    private func errorMessage(for error: DrawEngineError) -> String {
        switch error {
        case .noCandidates:
            return "今天候选都试过啦\n明天再来问问小狐狸吧 🦊"
        case .invalidContext(let reason):
            return "小狐狸迷路了…\n\(reason)"
        case .notImplemented:
            return "功能还在准备中\n稍后再试试 🦊"
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
}
