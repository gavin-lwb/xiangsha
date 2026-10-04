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
    // v1.1+ 占位（未来加字段时启用）
    // case v1_1 = 2  // 加 nutritionFacts（D-spec）
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

/// Schema 迁移计划（D138）
///
/// 当前：v1_0 → v1_0（无迁移）
/// v1.1+：增加 stages 描述迁移逻辑
///
/// 迁移策略（SPEC §10.5）：
/// - v1.x 小版本：用 @Attribute(.transformable) + 懒加载
/// - v1 → v2 大版本：写 VersionedSchema + SchemaMigrationPlan
enum xiangshaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [xiangshaSchemaV1_0.self]
    }

    /// 迁移阶段（D138 规范）
    ///
    /// 当前 v1_0 单版本无迁移；v1.1+ 在此加 stages。
    static var stages: [MigrationStage] {
        // 示例（v1.1 加 nutritionFacts 时启用）：
        // .migration(
        //     fromVersion: xiangshaSchemaV1_0.self,
        //     toVersion: xiangshaSchemaV1_1.self
        // ) { context in
        //     // 数据迁移代码：用 v1.0 数据填充 v1.1 新增字段
        //     // 例：Card 新增 nutritionFacts（transformable），从 metadata 提取
        // }
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

/// MARK: - v1.1+ Schema 占位（示例）

// v1.1+ Schema 占位（DEBUG 时编译，避免影响 v1.0 production）
#if DEBUG
// v1.1 占位：等 v1.1+ 启动时填入完整 schema
// enum xiangshaSchemaV1_1: VersionedSchema {
//     static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }
//     static var models: [any PersistentModel.Type] { [...] }
// }
#endif