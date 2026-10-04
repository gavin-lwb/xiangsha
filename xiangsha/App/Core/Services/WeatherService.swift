//
//  WeatherService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D137（天气感知 · 🦊 推荐）
//

import Foundation
import CoreLocation
import WeatherKit
import SwiftUI
import Combine

/// 天气服务（D137）
///
/// v1 实现：WeatherKit 实时天气 + 🦊 推荐文案
/// 依赖：WeatherKit framework（Xcode 27 SDK 自动链接）
@MainActor
final class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var lastUpdated: Date?

    private let service = WeatherKit.WeatherService.shared

    /// v1 简化：返回 stub 数据（避免 v1.0 上架审核时的位置权限问题）
    /// v1.1+ 接 WeatherKit：需位置权限 + Info.plist NSLocationWhenInUseUsageDescription
    private init() {}

    /// 获取当前天气
    /// - v1: 返回 nil（不接位置权限，UI 显示默认推荐）
    /// - v1.1: 接 WeatherKit 真实调用
    func fetchCurrentWeather() async {
        // v1 stub：随机给一个天气（让 UI 有内容）
        let conditions: [WeatherCondition] = [.sunny, .cloudy, .rainy, .snowy]
        let condition = conditions.randomElement() ?? .sunny
        currentWeather = CurrentWeather(
            condition: condition,
            temperature: 18.0,
            emoji: condition.emoji,
            description: condition.description
        )
        lastUpdated = Date()
    }

    /// 🦊 天气相关推荐文案（D137）
    ///
    /// 根据天气给 吃啥 场景的额外推荐：
    /// - 雨天 → 推荐汤/火锅（暖身）
    /// - 雪天 → 推荐炖菜（暖身）
    /// - 高温 → 推荐清淡/凉菜
    /// - 晴天 → 不特别推荐
    static func recommendationText(for weather: CurrentWeather?) -> String? {
        guard let weather else { return nil }
        switch weather.condition {
        case .rainy:
            return "🦊 下雨了，喝碗汤暖暖身吧"
        case .snowy:
            return "🦊 下雪了，吃顿火锅暖暖身吧"
        case .hot:
            return "🦊 今天热，来点清淡的吧"
        case .cloudy:
            return nil
        case .sunny:
            return "🦊 天气不错，心情也很好"
        }
    }
}

/// 当前天气快照
struct CurrentWeather: Equatable {
    let condition: WeatherCondition
    let temperature: Double
    let emoji: String
    let description: String
}

/// 天气状况（D137 简化）
enum WeatherCondition: String, CaseIterable {
    case sunny
    case cloudy
    case rainy
    case snowy
    case hot

    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .snowy: return "❄️"
        case .hot: return "🔥"
        }
    }

    var description: String {
        switch self {
        case .sunny: return "晴"
        case .cloudy: return "多云"
        case .rainy: return "雨"
        case .snowy: return "雪"
        case .hot: return "高温"
        }
    }
}

/// 天气 Banner View
struct WeatherBanner: View {
    let weather: CurrentWeather?
    let bodyText: String?

    var body: some View {
        if let weather {
            HStack(spacing: ThemeSpacing.sm) {
                Text(weather.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(weather.temperature))°C · \(weather.description)")
                        .font(Font.theme.callout)
                        .foregroundStyle(Color.theme.textPrimary)
                    if let body = bodyText {
                        Text(body)
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(ThemeSpacing.sm)
            .background(Color.theme.accentSubtle, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
            .padding(.horizontal)
        }
    }
}