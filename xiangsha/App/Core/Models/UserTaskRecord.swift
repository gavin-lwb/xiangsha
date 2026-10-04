//
//  UserTaskRecord.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：SPEC §10.1 实体 #7 + D076（做啥任务完成）+ §14.4（历史滚动 > 1000 删除最旧）
//

import Foundation
import SwiftData

/// 任务执行记录实体（SPEC §10.1 实体 #7）
///
/// 用户每次执行一个做啥任务时记录一条。status 表示完成情况。
/// 保留最近 1000 条滚动（SPEC §14.4）。
@Model
final class UserTaskRecord {
    /// 记录唯一标识
    @Attribute(.unique) var id: UUID

    /// 任务 ID（denormalized，给 #Index 用）
    ///
    /// 对应做啥模块任务模板 ID（v1.1+ 任务模板实体；v1 用 CardPool 间接引用）。
    var taskID: UUID

    /// 记录创建时间（任务开始）
    var createdAt: Date

    /// 任务完成时间（如未完成则为 nil）
    var completedAt: Date?

    /// 任务状态
    var statusRaw: String

    /// 备注（用户完成时填的）
    var noteText: String?

    init(taskID: UUID, status: UserTaskStatus = .inProgress, noteText: String? = nil) {
        self.id = UUID()
        self.taskID = taskID
        self.createdAt = Date()
        self.completedAt = nil
        self.statusRaw = status.rawValue
        self.noteText = noteText
    }

    /// 计算属性：强类型状态
    var status: UserTaskStatus {
        get { UserTaskStatus(rawValue: statusRaw) ?? .inProgress }
        set {
            statusRaw = newValue.rawValue
            if newValue == .completed {
                completedAt = Date()
            }
        }
    }

    /// 是否已完成
    var isCompleted: Bool {
        status == .completed
    }

    /// 任务持续时长（如已完成）
    var duration: TimeInterval? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(createdAt)
    }
}

/// 任务状态枚举
enum UserTaskStatus: String, CaseIterable, Codable {
    /// 进行中
    case inProgress
    /// 已完成（D076 全屏庆祝）
    case completed
    /// 已放弃（用户主动跳过）
    case abandoned

    var title: String {
        switch self {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .abandoned: return "已放弃"
        }
    }

    /// 庆祝文案（fox-persona.md §11）
    var celebrationText: String {
        switch self {
        case .inProgress: return "加油进行中"
        case .completed: return "你居然真的做了！🦊👏"
        case .abandoned: return "下次再说吧"
        }
    }
}