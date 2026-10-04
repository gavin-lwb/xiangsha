//
//  SeedService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：M0 内容生产（v1 lite）+ D094（设置导入/导出）
//

import Foundation
import SwiftData

/// 种子数据服务（M0 v1 lite 内嵌版）
///
/// v1 上线策略：内嵌 24 张吃啥卡 + 12 张玩啥卡 + 8 张做啥关键词 + 10 张拍啥姿势，
/// 首次启动自动播种（一次性）。后续 v1.1+ 改 JSON 文件加载。
///
/// 占位说明：完整 M0 内容生产（274+ 张）按用户拍板 v1 不启动（DEVELOPMENT.md §4 决策 4）。
/// 当前 SeedData 为"够 demo"最小集合。
@MainActor
enum SeedService {
    /// App 启动时调用：检查并执行一次性种子
    static func seedIfNeeded(context: ModelContext) {
        // 已种过则跳过（用 UserProfile 存在与否判断）
        let existingProfiles = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        guard existingProfiles == 0 else { return }

        seedDecisionScenes(context: context)
        seedEatCards(context: context)
        seedPlayCards(context: context)
        seedDoTasks(context: context)
        seedPhotoCards(context: context)
        seedUserProfile(context: context)

        try? context.save()
    }

    // MARK: - 场景

    private static func seedDecisionScenes(context: ModelContext) {
        for type in DecisionSceneType.v1Scenes {
            let scene = DecisionScene(type: type, sortOrder: type.defaultSortOrder)
            context.insert(scene)
        }
    }

    // MARK: - 吃啥（24 张 / 4 卡池）

    private static func seedEatCards(context: ModelContext) {
        let eatScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "eat" })
        ).first
        guard let eatScene else { return }

        for poolSpec in SeedData.eatPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: eatScene
            )
            context.insert(pool)
            for cardSpec in poolSpec.cards {
                let card = Card(
                    title: cardSpec.title,
                    scene: eatScene,
                    pool: pool,
                    emoji: cardSpec.emoji,
                    category: poolSpec.category,
                    brand: cardSpec.brand,
                    allergens: cardSpec.allergens,
                    difficulty: cardSpec.difficulty,
                    timeMinutes: cardSpec.timeMinutes,
                    metadata: cardSpec.metadata
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 玩啥（12 张 / 4 卡池）

    private static func seedPlayCards(context: ModelContext) {
        let playScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "play" })
        ).first
        guard let playScene else { return }

        for poolSpec in SeedData.playPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: playScene
            )
            context.insert(pool)
            for cardSpec in poolSpec.cards {
                let card = Card(
                    title: cardSpec.title,
                    scene: playScene,
                    pool: pool,
                    emoji: cardSpec.emoji,
                    category: poolSpec.category,
                    allergens: [],
                    difficulty: cardSpec.difficulty,
                    timeMinutes: cardSpec.timeMinutes,
                    metadata: cardSpec.metadata
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 做啥（8 张任务）

    private static func seedDoTasks(context: ModelContext) {
        let doScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "task" })
        ).first
        guard let doScene else { return }

        // 做啥只创建一个统一卡池"小任务"
        let pool = CardPool(
            name: "小任务",
            icon: "checkmark.circle",
            sortOrder: 0,
            scene: doScene
        )
        context.insert(pool)

        for spec in SeedData.doTasks {
            let card = Card(
                title: spec.title,
                scene: doScene,
                pool: pool,
                emoji: spec.emoji,
                category: spec.category,
                allergens: [],
                difficulty: spec.difficulty,
                timeMinutes: spec.timeMinutes,
                metadata: spec.metadata
            )
            context.insert(card)
        }
    }

    // MARK: - 拍啥（10 张姿势）

    private static func seedPhotoCards(context: ModelContext) {
        let photoScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "photo" })
        ).first
        guard let photoScene else { return }

        let pool = CardPool(
            name: "通用姿势",
            icon: "camera.viewfinder",
            sortOrder: 0,
            scene: photoScene
        )
        context.insert(pool)

        for spec in SeedData.photoCards {
            let card = Card(
                title: spec.title,
                scene: photoScene,
                pool: pool,
                emoji: spec.emoji,
                category: spec.category,
                allergens: [],
                difficulty: 1,
                timeMinutes: 5,
                metadata: spec.metadata
            )
            context.insert(card)
        }
    }

    // MARK: - 用户画像（默认）

    private static func seedUserProfile(context: ModelContext) {
        let profile = UserProfile(
            allergens: [UserProfile.noAllergenSentinel],
            preferredStyles: [],
            preferredCategories: [],
            preferredBrands: []
        )
        context.insert(profile)
    }
}

// MARK: - 内嵌种子数据（v1 lite）

private enum SeedData {
    // 吃啥 4 卡池
    static let eatPools: [EatPoolSpec] = [
        EatPoolSpec(
            name: "快手菜",
            icon: "bolt.fill",
            sortOrder: 0,
            category: "dish",
            cards: [
                EatCardSpec(title: "蛋炒饭", emoji: "🍳", brand: nil, allergens: ["鸡蛋"], difficulty: 1, timeMinutes: 10, metadata: ["mainIngredient": "米饭"]),
                EatCardSpec(title: "番茄炒蛋", emoji: "🍅", brand: nil, allergens: ["鸡蛋"], difficulty: 1, timeMinutes: 8, metadata: ["mainIngredient": "番茄"]),
                EatCardSpec(title: "煮泡面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 5, metadata: ["mainIngredient": "面条"]),
                EatCardSpec(title: "煎饺", emoji: "🥟", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 15, metadata: ["mainIngredient": "猪肉"]),
                EatCardSpec(title: "拌面", emoji: "🍝", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 12, metadata: ["mainIngredient": "面条"]),
                EatCardSpec(title: "三明治", emoji: "🥪", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 8, metadata: ["mainIngredient": "面包"])
            ]
        ),
        EatPoolSpec(
            name: "川菜",
            icon: "flame.fill",
            sortOrder: 1,
            category: "dish",
            cards: [
                EatCardSpec(title: "麻婆豆腐", emoji: "🌶️", brand: nil, allergens: ["大豆"], difficulty: 3, timeMinutes: 20, metadata: ["mainIngredient": "豆腐", "spicyLevel": "3"]),
                EatCardSpec(title: "回锅肉", emoji: "🥩", brand: nil, allergens: ["大豆"], difficulty: 3, timeMinutes: 25, metadata: ["mainIngredient": "猪肉", "spicyLevel": "2"]),
                EatCardSpec(title: "水煮鱼", emoji: "🐟", brand: nil, allergens: ["大豆"], difficulty: 4, timeMinutes: 30, metadata: ["mainIngredient": "鱼", "spicyLevel": "3"]),
                EatCardSpec(title: "夫妻肺片", emoji: "🥗", brand: nil, allergens: ["大豆"], difficulty: 4, timeMinutes: 30, metadata: ["mainIngredient": "牛肉", "spicyLevel": "3"]),
                EatCardSpec(title: "宫保鸡丁", emoji: "🍗", brand: nil, allergens: ["花生", "大豆"], difficulty: 3, timeMinutes: 25, metadata: ["mainIngredient": "鸡肉", "spicyLevel": "2"]),
                EatCardSpec(title: "酸辣粉", emoji: "🍜", brand: nil, allergens: ["花生"], difficulty: 2, timeMinutes: 15, metadata: ["mainIngredient": "粉丝", "spicyLevel": "2"])
            ]
        ),
        EatPoolSpec(
            name: "粤菜",
            icon: "leaf.fill",
            sortOrder: 2,
            category: "dish",
            cards: [
                EatCardSpec(title: "白切鸡", emoji: "🍗", brand: nil, allergens: [], difficulty: 3, timeMinutes: 45, metadata: ["mainIngredient": "鸡肉"]),
                EatCardSpec(title: "蒸蛋", emoji: "🥚", brand: nil, allergens: ["鸡蛋"], difficulty: 2, timeMinutes: 15, metadata: ["mainIngredient": "鸡蛋"]),
                EatCardSpec(title: "叉烧", emoji: "🥩", brand: nil, allergens: [], difficulty: 3, timeMinutes: 60, metadata: ["mainIngredient": "猪肉"]),
                EatCardSpec(title: "肠粉", emoji: "🌯", brand: nil, allergens: ["大豆", "鸡蛋"], difficulty: 3, timeMinutes: 20, metadata: ["mainIngredient": "米浆"]),
                EatCardSpec(title: "艇仔粥", emoji: "🍲", brand: nil, allergens: [], difficulty: 3, timeMinutes: 30, metadata: ["mainIngredient": "米"]),
                EatCardSpec(title: "蜜汁叉烧包", emoji: "🍞", brand: nil, allergens: ["小麦"], difficulty: 3, timeMinutes: 40, metadata: ["mainIngredient": "面粉"])
            ]
        ),
        EatPoolSpec(
            name: "夜宵",
            icon: "moon.stars.fill",
            sortOrder: 3,
            category: "dish",
            cards: [
                EatCardSpec(title: "烧烤", emoji: "🍢", brand: nil, allergens: [], difficulty: 2, timeMinutes: 30, metadata: ["mainIngredient": "肉串"]),
                EatCardSpec(title: "麻辣烫", emoji: "🌶️", brand: nil, allergens: [], difficulty: 1, timeMinutes: 15, metadata: ["mainIngredient": "蔬菜"]),
                EatCardSpec(title: "小龙虾", emoji: "🦐", brand: nil, allergens: [], difficulty: 2, timeMinutes: 30, metadata: ["mainIngredient": "虾", "spicyLevel": "2"]),
                EatCardSpec(title: "炸鸡", emoji: "🍗", brand: "麦当劳", allergens: ["小麦"], difficulty: 1, timeMinutes: 5, metadata: ["mainIngredient": "鸡肉"]),
                EatCardSpec(title: "披萨", emoji: "🍕", brand: nil, allergens: ["小麦", "奶"], difficulty: 1, timeMinutes: 25, metadata: ["mainIngredient": "面粉"]),
                EatCardSpec(title: "关东煮", emoji: "🍢", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10, metadata: ["mainIngredient": "鱼丸"])
            ]
        )
    ]

    // 玩啥 4 卡池
    static let playPools: [PlayPoolSpec] = [
        PlayPoolSpec(name: "室内单人", icon: "house.fill", sortOrder: 0, category: "solo_indoor", cards: [
            PlayCardSpec(title: "看一部电影", emoji: "🎬", difficulty: 1, timeMinutes: 120, metadata: ["style": "passive"]),
            PlayCardSpec(title: "读一本书", emoji: "📚", difficulty: 2, timeMinutes: 60, metadata: ["style": "calm"]),
            PlayCardSpec(title: "玩电子游戏", emoji: "🎮", difficulty: 1, timeMinutes: 90, metadata: ["style": "fun"]),
            PlayCardSpec(title: "做手账", emoji: "✏️", difficulty: 2, timeMinutes: 60, metadata: ["style": "creative"])
        ]),
        PlayPoolSpec(name: "室内多人", icon: "person.3.fill", sortOrder: 1, category: "group_indoor", cards: [
            PlayCardSpec(title: "桌游之夜", emoji: "🎲", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "火锅聚会", emoji: "🍲", difficulty: 2, timeMinutes: 90, metadata: ["style": "social"])
        ]),
        PlayPoolSpec(name: "室外单人", icon: "figure.walk", sortOrder: 2, category: "solo_outdoor", cards: [
            PlayCardSpec(title: "公园散步", emoji: "🌳", difficulty: 1, timeMinutes: 30, metadata: ["style": "calm"]),
            PlayCardSpec(title: "City Walk", emoji: "🚶", difficulty: 2, timeMinutes: 90, metadata: ["style": "explore"]),
            PlayCardSpec(title: "骑自行车", emoji: "🚴", difficulty: 3, timeMinutes: 60, metadata: ["style": "active"])
        ]),
        PlayPoolSpec(name: "室外多人", icon: "figure.run", sortOrder: 3, category: "group_outdoor", cards: [
            PlayCardSpec(title: "爬山", emoji: "⛰️", difficulty: 4, timeMinutes: 240, metadata: ["style": "active"]),
            PlayCardSpec(title: "野餐", emoji: "🧺", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "飞盘", emoji: "🥏", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"])
        ])
    ]

    // 做啥 8 任务
    static let doTasks: [DoTaskSpec] = [
        DoTaskSpec(title: "整理桌面", emoji: "🗂️", category: "整理", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
        DoTaskSpec(title: "洗杯子", emoji: "🥤", category: "清洁", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
        DoTaskSpec(title: "回一条信息", emoji: "💬", category: "沟通", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"]),
        DoTaskSpec(title: "喝一杯水", emoji: "💧", category: "健康", difficulty: 1, timeMinutes: 1, metadata: ["type": "micro"]),
        DoTaskSpec(title: "站起来伸展", emoji: "🤸", category: "健康", difficulty: 1, timeMinutes: 3, metadata: ["type": "rescue"]),
        DoTaskSpec(title: "写 3 件事", emoji: "📝", category: "整理", difficulty: 2, timeMinutes: 5, metadata: ["type": "rescue"]),
        DoTaskSpec(title: "深呼吸 5 次", emoji: "🌬️", category: "急救", difficulty: 1, timeMinutes: 2, metadata: ["type": "rescue"]),
        DoTaskSpec(title: "放下手机 5 分钟", emoji: "📵", category: "急救", difficulty: 2, timeMinutes: 5, metadata: ["type": "rescue"])
    ]

    // 拍啥 10 姿势
    static let photoCards: [PhotoCardSpec] = [
        PhotoCardSpec(title: "半身微笑", emoji: "🙂", category: "solo", metadata: ["pose": "upper_body"]),
        PhotoCardSpec(title: "侧面剪影", emoji: "🌅", category: "solo", metadata: ["pose": "side"]),
        PhotoCardSpec(title: "背影照", emoji: "🚶", category: "solo", metadata: ["pose": "back"]),
        PhotoCardSpec(title: "回眸一笑", emoji: "😊", category: "solo", metadata: ["pose": "look_back"]),
        PhotoCardSpec(title: "双手比心", emoji: "🫶", category: "solo", metadata: ["pose": "heart_hands"]),
        PhotoCardSpec(title: "情侣对视", emoji: "💑", category: "couple", metadata: ["pose": "face_to_face"]),
        PhotoCardSpec(title: "情侣背影", emoji: "👫", category: "couple", metadata: ["pose": "back_together"]),
        PhotoCardSpec(title: "朋友搞怪", emoji: "🤪", category: "friend", metadata: ["pose": "funny"]),
        PhotoCardSpec(title: "朋友合影", emoji: "📸", category: "friend", metadata: ["pose": "group"]),
        PhotoCardSpec(title: "全身站立", emoji: "🧍", category: "solo", metadata: ["pose": "full_body"])
    ]
}

// MARK: - 内嵌数据 spec 类型

private struct EatPoolSpec {
    let name: String
    let icon: String
    let sortOrder: Int
    let category: String
    let cards: [EatCardSpec]
}

private struct EatCardSpec {
    let title: String
    let emoji: String?
    let brand: String?
    let allergens: [String]
    let difficulty: Int
    let timeMinutes: Int
    let metadata: [String: String]?
}

private struct PlayPoolSpec {
    let name: String
    let icon: String
    let sortOrder: Int
    let category: String
    let cards: [PlayCardSpec]
}

private struct PlayCardSpec {
    let title: String
    let emoji: String?
    let difficulty: Int
    let timeMinutes: Int
    let metadata: [String: String]?
}

private struct DoTaskSpec {
    let title: String
    let emoji: String?
    let category: String
    let difficulty: Int
    let timeMinutes: Int
    let metadata: [String: String]?
}

private struct PhotoCardSpec {
    let title: String
    let emoji: String?
    let category: String
    let metadata: [String: String]?
}