//
//  xiangshaApp.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D133（ModelContainer 启动预热）+ SPEC §10.5（Schema 注册）+ D138（迁移规范）
//

import SwiftUI
import SwiftData

@main
struct xiangshaApp: App {
    /// SwiftData 容器（7 个 v1 实体）
    let container: ModelContainer

    init() {
        // 注册 Schema（SPEC §10.5 v1_0 modelsForSchema）
        let schema = Schema([
            DecisionScene.self,
            CardPool.self,
            Card.self,
            DrawRecord.self,
            UserProfile.self,
            Favorite.self,
            UserTaskRecord.self
        ])
        let modelConfig = ModelConfiguration(schema: schema)

        // R03 缓解：失败兜底到内存模式（v1.1+ 加全量 JSON 备份回滚）
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfig]
            )
        } catch {
            // 兜底：内存模式启动（避免 App 完全崩溃）
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            self.container = try! ModelContainer(
                for: schema,
                configurations: [fallbackConfig]
            )
        }

        // D133 启动预热：触发首次 fetch，避免首 Tab 加载时延迟
        // 1.5s 冷启动预算：ModelContainer 创建 + 预热 fetch < 500ms（D133 验收标准）
        let containerRef = container
        Task { @MainActor in
            let context = containerRef.mainContext
            _ = try? context.fetch(FetchDescriptor<DecisionScene>())
            _ = try? context.fetch(FetchDescriptor<UserProfile>())
        }
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}