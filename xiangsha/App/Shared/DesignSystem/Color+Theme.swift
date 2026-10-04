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
extension Color {
    /// 主题色板命名空间
    enum theme {
        // MARK: 背景
        /// 主背景（暖奶油色，自动深色模式适配）
        static let background = Color("ThemeBackground", bundle: .main)
        /// 卡片/容器背景
        static let surface = Color("ThemeSurface", bundle: .main)
        /// 浮层背景（半透明遮罩）
        static let overlay = Color("ThemeOverlay", bundle: .main)

        // MARK: 文字
        /// 主文字（标题、正文）
        static let textPrimary = Color("ThemeTextPrimary", bundle: .main)
        /// 次要文字（说明、注释）
        static let textSecondary = Color("ThemeTextSecondary", bundle: .main)
        /// 禁用文字
        static let textDisabled = Color("ThemeTextDisabled", bundle: .main)
        /// 文字在浅色背景上的颜色（用于主按钮等）
        static let textOnPrimary = Color("ThemeTextOnPrimary", bundle: .main)

        // MARK: 主色 / 强调
        /// 小狐狸🦊 主色（amber / 蜂蜜色）
        static let accent = Color("ThemeAccent", bundle: .main)
        /// 主色高亮态（按下）
        static let accentPressed = Color("ThemeAccentPressed", bundle: .main)
        /// 主色淡化（背景用）
        static let accentSubtle = Color("ThemeAccentSubtle", bundle: .main)

        // MARK: 语义色
        /// 成功 / OK（如 D097 成就解锁）
        static let success = Color("ThemeSuccess", bundle: .main)
        /// 警告（如 D088 过敏警告 / D006 冷却中）
        static let warning = Color("ThemeWarning", bundle: .main)
        /// 危险 / 错误
        static let danger = Color("ThemeDanger", bundle: .main)

        // MARK: 边框 / 分隔
        /// 卡片描边
        static let border = Color("ThemeBorder", bundle: .main)
        /// 列表分隔线
        static let divider = Color("ThemeDivider", bundle: .main)

        // MARK: 兜底（Assets 中无对应资源时用）
        /// 兜底背景色（Assets 未配置时的 fallback）
        static let fallbackBackground = Color(.systemBackground)
        /// 兜底强调色
        static let fallbackAccent = Color.accentColor
    }
}

// MARK: - 设计常量（保留为 fallback）

/// 在 xcassets 资源未配置时使用的兜底色值（仅 DesignSystem 内部使用）
///
/// 注：理想的命名状态是中间色值在 Assets.xcassets/AccentColor.colorset 中配置，
/// 然后通过 Color("ThemeAccent") 引用。当前 v1.0 用 SwiftUI 标准 semantic 色作兜底，
/// 设计资源就位后即可自动切换。
enum ThemeTokens {
    // 主色（米咖奶油 + 小狐狸 amber）
    static let accentLight = Color(red: 0.86, green: 0.51, blue: 0.20) // 小狐狸 amber
    static let accentDark = Color(red: 0.95, green: 0.65, blue: 0.32)
    static let backgroundLight = Color(red: 0.99, green: 0.97, blue: 0.94) // 暖奶油
    static let backgroundDark = Color(red: 0.11, green: 0.10, blue: 0.09)   // 深咖

    // 语义色
    static let success = Color(red: 0.30, green: 0.65, blue: 0.40)
    static let warning = Color(red: 0.95, green: 0.65, blue: 0.20)
    static let danger = Color(red: 0.85, green: 0.32, blue: 0.28)
}