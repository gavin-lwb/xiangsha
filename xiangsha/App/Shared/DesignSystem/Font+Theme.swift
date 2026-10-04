//
//  Font+Theme.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D138（设计 token 规范）+ 02-AGENTS §A.7（禁硬编码字号）
//

import SwiftUI

/// 设计系统字号（02-AGENTS §A.7 禁硬编码字号）
///
/// 基于 SwiftUI Dynamic Type，所有 token 自动适配用户字号偏好（D138 + 无障碍 §11.3）。
extension Font {
    /// 主题字号命名空间
    enum theme {
        // MARK: 大标题（首屏 / 启动引导）
        /// 首屏巨标题（如启动引导 1 屏主标题）
        static let heroTitle: Font = .system(.largeTitle, design: .rounded, weight: .bold)
        /// 主标题（Navigation 大标题）
        static let largeTitle: Font = .system(.largeTitle, design: .rounded, weight: .semibold)
        /// 标题 1
        static let title1: Font = .system(.title, design: .rounded, weight: .semibold)
        /// 标题 2
        static let title2: Font = .system(.title2, design: .rounded, weight: .semibold)
        /// 标题 3
        static let title3: Font = .system(.title3, design: .rounded, weight: .medium)

        // MARK: 正文
        /// 正文（默认）
        static let body: Font = .system(.body, design: .default)
        /// 正文加粗
        static let bodyEmphasis: Font = .system(.body, design: .default, weight: .semibold)
        /// 正文 callout
        static let callout: Font = .system(.callout, design: .default)

        // MARK: 辅助
        /// 次要文字（说明）
        static let subheadline: Font = .system(.subheadline, design: .default)
        /// 注脚
        static let footnote: Font = .system(.footnote, design: .default)
        /// caption（小标签 / 计数）
        static let caption: Font = .system(.caption, design: .default)
        /// caption 2（v2 表尾）
        static let caption2: Font = .system(.caption2, design: .default)

        // MARK: 特殊
        /// 主按钮文字
        static let button: Font = .system(.body, design: .rounded, weight: .semibold)
        /// 大按钮文字（CTA）
        static let buttonLarge: Font = .system(.title3, design: .rounded, weight: .semibold)
        /// Tab 标签
        static let tabLabel: Font = .system(.caption, design: .rounded, weight: .medium)

        // MARK: 数字（计时器 / 计数）
        /// 数字等宽
        static let monospacedDigit: Font = .system(.body, design: .monospaced)
    }
}

// MARK: - 间距 / 圆角 token

/// 设计系统间距常量（4pt 基准）
enum ThemeSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let huge: CGFloat = 48
}

/// 设计系统圆角常量
enum ThemeRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let pill: CGFloat = 999
}

/// 设计系统阴影
enum ThemeShadow {
    static let sm: CGFloat = 2
    static let md: CGFloat = 6
    static let lg: CGFloat = 12
}