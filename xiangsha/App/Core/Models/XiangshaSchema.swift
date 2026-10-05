//
//  XiangshaSchema.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D138（Schema 迁移规范 · VersionedSchema + SchemaMigrationPlan）+ SPEC §10.5
//

import Foundation
import SwiftData

/// v1.0 Schema（D138 + SPEC §10.5）
///
/// 当前活跃版本。新增字段时：
/// 1. 加新 VersionedSchema（v1_1 / v1_2 ...）
/// 2. 在 xiangshaMigrationPlan.stages 加 MigrationStage
/// 3. App 启动时 SwiftData 自动检测 versioned 升级并迁移
enum SchemaVersion: Int, CaseIterable {
    case v1_0 = 1
    case v1_1 = 2   // Card 加 7 字段（scenario / availableTimes / seasonWeights / cuisine / priceRange / recipe / serves）+ 新增 UserCookedRecord
    // v1.2+ 占位
    // case v1_2 = 3  // 加 DecisionJournalEntry + CardSnapshot + Routine
}

/// v1.0 Schema 定义
enum xiangshaSchemaV1_0: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            DecisionScene.self,
            CardPool.self,
            Card.self,
            DrawRecord.self,
            UserProfile.self,
            Favorite.self,
            UserTaskRecord.self
        ]
    }
}

/// v1.1 Schema 定义（D138 · 吃啥模块补全）
///
/// 新增：
/// - Card 7 字段（scenario / availableTimes / seasonWeights / cuisine / priceRange / recipe / serves）
/// - UserCookedRecord 实体（D045/D046）
///
/// 迁移方式：lightweight migration（所有新字段都是 optional 或有默认值，新 model 由 SwiftData 自动建表）。
/// 无需显式 MigrationStage closure。
enum xiangshaSchemaV1_1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }

    static var models: [any PersistentModel.Type] {
        [
            DecisionScene.self,
            CardPool.self,
            Card.self,
            DrawRecord.self,
            UserProfile.self,
            Favorite.self,
            UserTaskRecord.self,
            UserCookedRecord.self
        ]
    }
}

/// Schema 迁移计划（D138）
///
/// 当前：v1_0 → v1_1（lightweight migration）
/// v1.2+：增加 stages 描述迁移逻辑
///
/// 迁移策略（SPEC §10.5）：
/// - v1.x 小版本：lightweight migration（新增 optional / 带默认值字段 + 新 model）
/// - v1 → v2 大版本：写 VersionedSchema + SchemaMigrationPlan + 显式闭包
enum xiangshaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [xiangshaSchemaV1_0.self, xiangshaSchemaV1_1.self]
    }

    /// 迁移阶段（D138 规范）
    ///
    /// v1_0 → v1_1 由 SwiftData 自动 lightweight migration（无显式闭包）。
    /// 后续 v1.x → v1.y 大改动时在此加 .migration(fromVersion:toVersion:) { context in ... } 闭包。
    static var stages: [MigrationStage] {
        []
    }
}

/// MARK: - 迁移检查（D138 描述）

extension xiangshaMigrationPlan {
    /// 检查当前数据库版本是否需要迁移
    ///
    /// v1.0 始终为 false；v1.1+ 增加时返回 true
    static var needsMigration: Bool {
        // 实际逻辑由 SwiftData 内部处理；这里仅占位
        false
    }
}