//
//  OnboardingView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D087（启动引导）+ D088（过敏原硬屏强制）+ fox-persona §1
//

import SwiftUI
import SwiftData

/// 启动引导容器（3 屏 · PageTabView）
///
/// 完成条件：第 3 屏勾选过敏原（至少 1 项含「无」）→ 写入 UserProfile → 切到主 TabView
struct OnboardingView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @State private var pageIndex: Int = 0
    @State private var selectedAllergens: Set<String> = []

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $pageIndex) {
            WelcomeScreen(onNext: { pageIndex = 1 })
                .tag(0)

            FourScenesScreen(onNext: { pageIndex = 2 })
                .tag(1)

            AllergenScreen(
                selectedAllergens: $selectedAllergens,
                onComplete: complete
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color.theme.background)
    }

    /// 完成引导（D088 强制写过敏原）
    private func complete() {
        let allergens = selectedAllergens.isEmpty
            ? [UserProfile.noAllergenSentinel]
            : Array(selectedAllergens)

        // 写入 UserProfile
        if let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
            profile.allergens = allergens
            profile.updatedAt = Date()
            try? modelContext.save()
        }

        onboardingCompleted = true
    }
}

// MARK: - 第 1 屏：欢迎

private struct WelcomeScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            Spacer()

            Text("🦊")
                .font(.system(size: 120))
                .accessibilityHidden(true)

            Text("你好呀，我是小狐狸")
                .font(Font.theme.heroTitle)
                .foregroundStyle(Color.theme.textPrimary)

            Text("拿不定主意的时候，来找我玩吧")
                .font(Font.theme.body)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onNext) {
                Text("开始 →")
                    .font(Font.theme.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.textOnPrimary)
            }
            .padding(.horizontal, ThemeSpacing.xl)
            .padding(.bottom, ThemeSpacing.huge)

            OnboardingPageIndicator(total: 3, current: 0)
                .padding(.bottom, ThemeSpacing.lg)
        }
    }
}

// MARK: - 第 2 屏：4 场景

private struct FourScenesScreen: View {
    let onNext: () -> Void

    private let scenes: [(title: String, icon: String)] = [
        ("吃啥", "fork.knife"),
        ("玩啥", "gamecontroller.fill"),
        ("做啥", "checkmark.circle.fill"),
        ("拍啥", "camera.fill")
    ]

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            Spacer()

            VStack(spacing: ThemeSpacing.sm) {
                Text("4 个场景，都能帮你选")
                    .font(Font.theme.heroTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.theme.textPrimary)

                Text("吃啥 · 玩啥 · 做啥 · 拍啥")
                    .font(Font.theme.body)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)

                Text("你说了算")
                    .font(Font.theme.callout)
                    .foregroundStyle(Color.theme.accent)
            }
            .padding(.horizontal)

            // 4 场景图标网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ThemeSpacing.md) {
                ForEach(scenes, id: \.title) { scene in
                    VStack(spacing: ThemeSpacing.xs) {
                        Image(systemName: scene.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(Color.theme.accent)
                        Text(scene.title)
                            .font(Font.theme.title3)
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                }
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onNext) {
                Text("下一步 →")
                    .font(Font.theme.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                    .foregroundStyle(Color.theme.textOnPrimary)
            }
            .padding(.horizontal, ThemeSpacing.xl)
            .padding(.bottom, ThemeSpacing.huge)

            OnboardingPageIndicator(total: 3, current: 1)
                .padding(.bottom, ThemeSpacing.lg)
        }
    }
}

// MARK: - 第 3 屏：过敏原硬屏（D088 强制勾选）

private struct AllergenScreen: View {
    @Binding var selectedAllergens: Set<String>
    let onComplete: () -> Void

    /// 常见过敏原清单（SPEC §A.2 / D088）
    private static let commonAllergens: [String] = [
        "花生", "大豆", "奶", "小麦", "鸡蛋", "虾", "蟹", "坚果", "鱼", "贝"
    ]

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            VStack(spacing: ThemeSpacing.xs) {
                Text("⚠️")
                    .font(.system(size: 80))
                    .accessibilityHidden(true)

                Text("先告诉我，哪些不能吃？")
                    .font(Font.theme.title1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.theme.textPrimary)

                Text("为了不踩雷，你得至少勾一项（包括「无」）")
                    .font(Font.theme.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(.horizontal)
            .padding(.top, ThemeSpacing.md)

            // 过敏原 chips
            FlowingAllergenChips(
                allergens: Self.commonAllergens + [UserProfile.noAllergenSentinelDisplay],
                selectedAllergens: $selectedAllergens
            )
            .padding(.horizontal)

            // 已选预览
            if !selectedAllergens.isEmpty {
                Text("已选：\(selectedAllergens.sorted().joined(separator: "、"))")
                    .font(Font.theme.caption)
                    .foregroundStyle(Color.theme.accent)
            }

            Spacer()

            Button(action: onComplete) {
                Text(buttonTitle)
                    .font(Font.theme.buttonLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isValid ? Color.theme.accent : Color.theme.textDisabled,
                        in: RoundedRectangle(cornerRadius: ThemeRadius.md)
                    )
                    .foregroundStyle(Color.theme.textOnPrimary)
            }
            .disabled(!isValid)
            .padding(.horizontal, ThemeSpacing.xl)
            .padding(.bottom, ThemeSpacing.huge)

            OnboardingPageIndicator(total: 3, current: 2)
                .padding(.bottom, ThemeSpacing.lg)
        }
    }

    private var isValid: Bool {
        !selectedAllergens.isEmpty
    }

    private var buttonTitle: String {
        if !isValid { return "至少勾一项" }
        return "填好了 →"
    }
}

// MARK: - 辅助组件

private struct OnboardingPageIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: ThemeSpacing.xs) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.theme.accent : Color.theme.border)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

/// 过敏原 chip 选择器（LazyVGrid 自适应换行）
private struct FlowingAllergenChips: View {
    let allergens: [String]
    @Binding var selectedAllergens: Set<String>

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: ThemeSpacing.xs)],
            alignment: .leading,
            spacing: ThemeSpacing.xs
        ) {
            ForEach(allergens, id: \.self) { allergen in
                let isNone = (allergen == UserProfile.noAllergenSentinel)
                AllergenChip(
                    title: allergen,
                    isSelected: selectedAllergens.contains(allergen),
                    isNone: isNone
                ) {
                    toggle(allergen)
                }
            }
        }
    }

    private func toggle(_ allergen: String) {
        if selectedAllergens.contains(allergen) {
            selectedAllergens.remove(allergen)
        } else {
            selectedAllergens.insert(allergen)
        }
    }
}

private struct AllergenChip: View {
    let title: String
    let isSelected: Bool
    let isNone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.theme.callout)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.sm)
                .background(
                    isSelected
                        ? (isNone ? Color.theme.success : Color.theme.accent)
                        : Color.theme.surface,
                    in: Capsule()
                )
                .foregroundStyle(
                    isSelected ? Color.theme.textOnPrimary : Color.theme.textPrimary
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UserProfile 扩展（onboarding 显示用）

extension UserProfile {
    /// 显示名（用于 onboarding chip）
    static var noAllergenSentinelDisplay: String {
        switch noAllergenSentinel {
        case "__none__": return "无"
        default: return noAllergenSentinel
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}