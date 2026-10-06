//
//  PhotoCaptureService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/6.
//  关联决策：D077-D086（拍啥姿势 · v1.1 真实图接入点）
//
//  ⚠️ 注意：本文档为 **v1.1 占位骨架**，v1 阶段 PhotoViewModel 仍走 emoji + 文字引导（D140）。
//  v1.1 时接入真实图（实拍 + AI 生图，D141），届时本文件将承载：
//    - 姿势图加载
//    - 拍照引导（位置/光线/构图）
//    - 实拍示例图管理
//

import Foundation
import SwiftUI

// MARK: - 协议

/// 拍照姿势服务协议（v1.1 接入点）
///
/// v1 阶段：返回 emoji + 文字引导（实现见 `EmojiPhotoCaptureService`）
/// v1.1 阶段：返回真实姿势图（实现见 `LivePhotoCaptureService`，待 v1.1 接入）
protocol PhotoCaptureService: Sendable {
    /// 获取姿势的视觉资源（v1: emoji 字符 / v1.1: 图片 URL）
    func visualResource(for card: Card) async -> PhotoVisualResource

    /// 获取姿势的拍摄引导（文字）
    func guidanceText(for card: Card) async -> String

    /// 验证姿势所需权限（如相机权限，v1.1+）
    func requestPermission() async -> Bool
}

/// 视觉资源枚举（v1 / v1.1 双兼容）
enum PhotoVisualResource: Sendable {
    /// v1 占位：emoji 字符 + 背景色
    case placeholder(emoji: String, backgroundColor: Color)

    /// v1.1 真实图：本地路径或 URL（待接入）
    case liveImage(url: URL, thumbnail: Data?)

    /// AI 生图（D141 · v1.1）
    case generatedImage(prompt: String, seed: UInt64)
}

// MARK: - v1 占位实现

/// v1 占位实现：纯 emoji + 背景色，无相机权限需求
///
/// 与 `Card.emoji` 字段直接对应（D140），保证 v1 阶段 Photo 模块可独立运行。
struct EmojiPhotoCaptureService: PhotoCaptureService {

    func visualResource(for card: Card) async -> PhotoVisualResource {
        // v1 占位策略：emoji + 主题色块（D139 沉浸式大图）
        let bgColor: Color
        switch card.category {
        case "single":     bgColor = .blue.opacity(0.3)
        case "couple":     bgColor = .pink.opacity(0.3)
        case "friends":    bgColor = .orange.opacity(0.3)
        case "family":     bgColor = .green.opacity(0.3)
        case "pet":        bgColor = .yellow.opacity(0.3)
        default:           bgColor = .gray.opacity(0.2)
        }
        return .placeholder(emoji: card.emoji ?? "📸", backgroundColor: bgColor)
    }

    func guidanceText(for card: Card) async -> String {
        // D082-D084 位置引导：从 metadata 取「positionGuide」字段
        if let positionGuide = card.metadata?["positionGuide"] {
            return positionGuide
        }
        // 默认通用引导
        switch card.category {
        case "single":     return "自然站立，面带微笑，看向镜头"
        case "couple":     return "靠近对方，肩膀相依，氛围自然"
        case "friends":    return "比心/勾肩，动作自然有活力"
        case "family":     return "全员入镜，排列有序，表情自然"
        case "pet":        return "与宠物同框，视线平齐"
        default:           return "放松自然，享受当下"
        }
    }

    func requestPermission() async -> Bool {
        // v1 不需要相机权限，直接返回 true
        true
    }
}

// MARK: - v1.1 真实图实现占位

/// v1.1 真实图实现（**待接入 · 不要在 v1 阶段引用**）
///
/// 接入时机：D077-D086 全部决策敲定 + 真实姿势图库准备就绪后。
/// 接入步骤：
///   1. 在 `App/Modules/Photo/Services/` 下创建 `LivePhotoCaptureService.swift`
///   2. 实现姿势图下载/缓存（基于 `URLCache` 或自建磁盘缓存）
///   3. 接入 AI 生图（D141 · minimax/image-01）
///   4. 在 `PhotoView.swift` 中按 `card.metadata["imageSource"]` 切换实现
///   5. 加入单元测试 `LivePhotoCaptureServiceTests.swift`
struct LivePhotoCaptureService: PhotoCaptureService {

    func visualResource(for card: Card) async -> PhotoVisualResource {
        // ⚠️ 占位：v1.1 接入前会触发 fatalError，提醒开发者这是 v1.1 实现
        fatalError("LivePhotoCaptureService 待 v1.1 接入（D141）")
    }

    func guidanceText(for card: Card) async -> String {
        fatalError("LivePhotoCaptureService 待 v1.1 接入（D141）")
    }

    func requestPermission() async -> Bool {
        // v1.1 需要相机权限（NSCameraUsageDescription）
        // 接入时需在 Info.plist 添加权限说明
        false
    }
}

// MARK: - 服务工厂

/// PhotoCaptureService 工厂（v1 / v1.1 自动切换）
///
/// v1 阶段默认返回 `EmojiPhotoCaptureService`。
/// v1.1 阶段改为根据构建标志 / 远程开关切换到 `LivePhotoCaptureService`。
enum PhotoCaptureServiceFactory {
    static func make() -> PhotoCaptureService {
        // TODO: v1.1 接入时改为：
        // #if DEBUG
        // return LivePhotoCaptureService()
        // #else
        // return EmojiPhotoCaptureService()
        // #endif
        return EmojiPhotoCaptureService()
    }
}
