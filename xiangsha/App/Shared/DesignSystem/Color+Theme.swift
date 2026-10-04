//
//  Color+Theme.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D138（设计 token 规范）+ SPEC §11.2（暗色模式）+ fox-persona（米咖奶油色系）
//

import SwiftUI

/// 设计系统色板（02-AGENTS §A.7 禁写硬编码色值）
///
/// 设计基线：米咖奶油色系（warm cream / coffee tone），融合小狐狸🦊 amber 主色。
/// 所有色值通过 semantic token 暴露，**禁止 View 直接写 Color(.systemRed)** 等硬编码。
///
/// v1 实现：直接使用 ThemeTokens 中定义的颜色值（light 主用）。
/// v1.1+ 加暗色模式自动适配（D138）。
extension Color {
    /// 主题色板命名空间
    enum theme {
        // MARK: 背景

        /// 主背景（暖奶油色）
        static let background: Color = ThemeTokens.backgroundLight

        /// 卡片/容器背景
        static let surface: Color = ThemeTokens.surfaceLight

        /// 浮层背景（半透明遮罩）
        static let overlay: Color = Color.black.opacity(0.4)

        // MARK: 文字

        /// 主文字（标题、正文）
        static let textPrimary: Color = ThemeTokens.textPrimaryLight

        /// 次要文字（说明、注释）
        static let textSecondary: Color = ThemeTokens.textSecondaryLight

        /// 禁用文字
        static let textDisabled: Color = ThemeTokens.textDisabledLight

        /// 文字在浅色背景上的颜色（用于主按钮等）
        static let textOnPrimary: Color = ThemeTokens.textOnPrimaryLight

        // MARK: 主色 / 强调

        /// 小狐狸🦊 主色（amber / 蜂蜜色）
        static let accent: Color = ThemeTokens.accentLight

        /// 主色高亮态（按下）
        static let accentPressed: Color = ThemeTokens.accentPressedLight

        /// 主色淡化（背景用）
        static let accentSubtle: Color = ThemeTokens.accentSubtleLight

        // MARK: 语义色

        /// 成功 / OK（如 D097 成就解锁）
        static let success: Color = ThemeTokens.successLight

        /// 警告（如 D088 过敏警告 / D006 冷却中）
        static let warning: Color = ThemeTokens.warningLight

        /// 危险 / 错误
        static let danger: Color = ThemeTokens.dangerLight

        // MARK: 边框 / 分隔

        /// 卡片描边
        static let border: Color = ThemeTokens.borderLight

        /// 列表分隔线
        static let divider: Color = ThemeTokens.dividerLight

        // MARK: 兜底（标准系统色）

        /// 兜底背景色
        static let fallbackBackground: Color = Color(.systemBackground)
        /// 兜底强调色
        static let fallbackAccent: Color = Color.accentColor
    }
}

// MARK: - 设计常量

/// 设计 token 色值（v1 light 主用，v1.1+ 加 dark）
///
/// 在代码中集中管理，避免 Assets.xcassets 颜色资源缺失导致的渲染失败。
enum ThemeTokens {
    // 主色（米咖奶油 + 小狐狸 amber）

    /// 暖奶油背景
    static let backgroundLight = Color(red: 0.99, green: 0.97, blue: 0.94)

    /// 卡片 / 容器背景（亮色）
    static let surfaceLight = Color.white

    // 文字色

    /// 主文字（亮）
    static let textPrimaryLight = Color(red: 0.13, green: 0.11, blue: 0.08)

    /// 次要文字（亮）
    static let textSecondaryLight = Color(red: 0.45, green: 0.41, blue: 0.36)

    /// 禁用文字（亮）
    static let textDisabledLight = Color(red: 0.75, green: 0.72, blue: 0.68)

    /// 主按钮文字（亮 = 白）
    static let textOnPrimaryLight = Color.white

    // 主色 / 强调

    /// 小狐狸 amber（亮）
    static let accentLight = Color(red: 0.86, green: 0.51, blue: 0.20)

    /// 主色按下态（亮）
    static let accentPressedLight = Color(red: 0.75, green: 0.42, blue: 0.15)

    /// 主色淡化（亮）
    static let accentSubtleLight = Color(red: 0.98, green: 0.92, blue: 0.82)

    // 语义色

    /// 成功（亮）
    static let successLight = Color(red: 0.30, green: 0.65, blue: 0.40)

    /// 警告（亮）
    static let warningLight = Color(red: 0.95, green: 0.65, blue: 0.20)

    /// 危险（亮）
    static let dangerLight = Color(red: 0.85, green: 0.32, blue: 0.28)

    // 边框 / 分隔

    /// 卡片描边（亮）
    static let borderLight = Color(red: 0.88, green: 0.84, blue: 0.78)

    /// 列表分隔线（亮）
    static let dividerLight = Color(red: 0.92, green: 0.90, blue: 0.85)

    // MARK: - 暗色模式预留（v1.1+ 启用）

    // 主色
    static let backgroundDark = Color(red: 0.11, green: 0.10, blue: 0.09)
    static let surfaceDark = Color(red: 0.18, green: 0.16, blue: 0.14)

    // 文字
    static let textPrimaryDark = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let textSecondaryDark = Color(red: 0.70, green: 0.66, blue: 0.60)
    static let textDisabledDark = Color(red: 0.40, green: 0.38, blue: 0.34)
    static let textOnPrimaryDark = Color(red: 0.13, green: 0.11, blue: 0.08)

    // 主色
    static let accentDark = Color(red: 0.95, green: 0.65, blue: 0.32)
    static let accentPressedDark = Color(red: 0.85, green: 0.55, blue: 0.25)
    static let accentSubtleDark = Color(red: 0.30, green: 0.22, blue: 0.12)

    // 语义色
    static let successDark = Color(red: 0.40, green: 0.75, blue: 0.50)
    static let warningDark = Color(red: 1.00, green: 0.75, blue: 0.30)
    static let dangerDark = Color(red: 0.95, green: 0.42, blue: 0.38)

    // 边框
    static let borderDark = Color(red: 0.30, green: 0.28, blue: 0.24)
    static let dividerDark = Color(red: 0.25, green: 0.23, blue: 0.20)
}