//
//  SeedService.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：M0 内容生产（v1 full 集：180 张卡）
//

import Foundation
import SwiftData

/// 种子数据服务（M0 v1 full 集：180 张卡）
///
/// 规模分布（按 SPEC §6 / DOC §0）：
/// - 吃啥 80 张（5 卡池 × 16）
/// - 玩啥 40 张（4 卡池 × 10）
/// - 做啥 30 张（5 卡池 × 6）
/// - 拍啥 30 张（5 卡池 × 6）
///
/// 总计 **180 张**（SPEC 目标 274+ 的子集，v1 demo 用；后续 v1.1+ 补全到 274+）
@MainActor
enum SeedService {
    /// App 启动时调用：检查并执行一次性种子
    static func seedIfNeeded(context: ModelContext) {
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

    // MARK: - 吃啥（80 张 / 5 卡池）

    private static func seedEatCards(context: ModelContext) {
        guard let eatScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "eat" })
        ).first else { return }

        for poolSpec in SeedData.eatPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: eatScene
            )
            context.insert(pool)
            for spec in poolSpec.cards {
                // 主料：spec 显式填 > 启发式推断 > nil（nil 表示不参与主料去重）
                let mainIngredient = spec.mainIngredient ?? SeedData.inferMainIngredient(from: spec.title)
                let metadata: [String: String]? = mainIngredient.map { ["mainIngredient": $0] }
                let card = Card(
                    title: spec.title,
                    scene: eatScene,
                    pool: pool,
                    emoji: spec.emoji,
                    category: poolSpec.category,
                    allergens: spec.allergens,
                    difficulty: spec.difficulty,
                    timeMinutes: spec.timeMinutes,
                    metadata: metadata,
                    scenario: spec.scenario,
                    availableTimes: spec.availableTimes,
                    recipe: spec.recipe
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 玩啥（40 张 / 4 卡池）

    private static func seedPlayCards(context: ModelContext) {
        guard let playScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "play" })
        ).first else { return }

        for poolSpec in SeedData.playPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: playScene
            )
            context.insert(pool)
            for spec in poolSpec.cards {
                let card = Card(
                    title: spec.title,
                    scene: playScene,
                    pool: pool,
                    emoji: spec.emoji,
                    category: poolSpec.category,
                    allergens: [],
                    difficulty: spec.difficulty,
                    timeMinutes: spec.timeMinutes,
                    metadata: spec.metadata,
                    costLevel: spec.costLevel
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 做啥（30 张 / 5 卡池）

    private static func seedDoTasks(context: ModelContext) {
        guard let doScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "task" })
        ).first else { return }

        for poolSpec in SeedData.doPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: doScene
            )
            context.insert(pool)
            for spec in poolSpec.cards {
                let card = Card(
                    title: spec.title,
                    scene: doScene,
                    pool: pool,
                    emoji: spec.emoji,
                    category: poolSpec.category,
                    allergens: [],
                    difficulty: spec.difficulty,
                    timeMinutes: spec.timeMinutes,
                    metadata: spec.metadata
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 拍啥（30 张 / 5 卡池）

    private static func seedPhotoCards(context: ModelContext) {
        guard let photoScene = try? context.fetch(
            FetchDescriptor<DecisionScene>(predicate: #Predicate { $0.typeRaw == "photo" })
        ).first else { return }

        for poolSpec in SeedData.photoPools {
            let pool = CardPool(
                name: poolSpec.name,
                icon: poolSpec.icon,
                sortOrder: poolSpec.sortOrder,
                scene: photoScene
            )
            context.insert(pool)
            for spec in poolSpec.cards {
                let card = Card(
                    title: spec.title,
                    scene: photoScene,
                    pool: pool,
                    emoji: spec.emoji,
                    category: poolSpec.category,
                    allergens: [],
                    difficulty: 1,
                    timeMinutes: 5,
                    metadata: spec.metadata
                )
                context.insert(card)
            }
        }
    }

    // MARK: - 用户画像

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

// MARK: - 内嵌种子数据

private enum SeedData {
    // MARK: 吃啥 5 卡池 × 16 张 = 80 张

    static let eatPools: [EatPoolSpec] = [
        EatPoolSpec(
            name: "早餐", icon: "sun.horizon.fill", sortOrder: 0, category: "breakfast",
            cards: breakfastCards
        ),
        EatPoolSpec(
            name: "午餐", icon: "sun.max.fill", sortOrder: 1, category: "lunch",
            cards: lunchCards
        ),
        EatPoolSpec(
            name: "下午茶", icon: "cup.and.saucer.fill", sortOrder: 2, category: "tea",
            cards: teaCards
        ),
        EatPoolSpec(
            name: "晚餐", icon: "moon.fill", sortOrder: 3, category: "dinner",
            cards: dinnerCards
        ),
        EatPoolSpec(
            name: "夜宵", icon: "moon.stars.fill", sortOrder: 4, category: "latenight",
            cards: latenightCards
        ),
        // D029/D032 · 在家做（独立于时段池，覆盖全部 5 个时段）
        EatPoolSpec(
            name: "在家做", icon: "house.fill", sortOrder: 5, category: "homecook",
            cards: homeCookCards
        )
    ]

    private static let breakfastCards: [EatCardSpec] = [
        EatCardSpec(title: "肉包", emoji: "🥟", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "菜包", emoji: "🥬", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "煎饺", emoji: "🥟", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "小笼包", emoji: "🥟", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "豆浆油条", emoji: "🥛", brand: nil, allergens: ["大豆"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "皮蛋瘦肉粥", emoji: "🍲", brand: nil, allergens: [], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "小米粥", emoji: "🥣", brand: nil, allergens: [], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "煎饼果子", emoji: "🥞", brand: nil, allergens: ["小麦", "鸡蛋"], difficulty: 2, timeMinutes: 10),
        EatCardSpec(title: "鸡蛋灌饼", emoji: "🍳", brand: nil, allergens: ["小麦", "鸡蛋"], difficulty: 2, timeMinutes: 10),
        EatCardSpec(title: "三明治", emoji: "🥪", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 8),
        EatCardSpec(title: "燕麦杯", emoji: "🥣", brand: nil, allergens: ["麦"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "酸奶麦片", emoji: "🥛", brand: nil, allergens: ["奶", "麦"], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "茶叶蛋", emoji: "🥚", brand: nil, allergens: ["鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "葱油饼", emoji: "🥞", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 10),
        EatCardSpec(title: "蛋炒饭", emoji: "🍳", brand: nil, allergens: ["鸡蛋"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "白粥 + 咸菜", emoji: "🥣", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10),
        // B1 扩展
        EatCardSpec(title: "汉堡包", emoji: "🍔", brand: nil, allergens: ["小麦", "奶"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "现磨豆浆", emoji: "🥛", brand: nil, allergens: ["大豆"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "鸡蛋汉堡", emoji: "🍳", brand: nil, allergens: ["小麦", "鸡蛋"], difficulty: 2, timeMinutes: 8),
        EatCardSpec(title: "金枪鱼三明治", emoji: "🥪", brand: nil, allergens: ["小麦", "鱼"], difficulty: 2, timeMinutes: 10)
    ]

    private static let lunchCards: [EatCardSpec] = [
        EatCardSpec(title: "黄焖鸡米饭", emoji: "🍗", brand: nil, allergens: [], difficulty: 2, timeMinutes: 25),
        EatCardSpec(title: "沙县小吃", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "兰州拉面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "螺蛳粉", emoji: "🍝", brand: nil, allergens: [], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "麻辣香锅", emoji: "🌶️", brand: nil, allergens: ["花生"], difficulty: 3, timeMinutes: 30),
        EatCardSpec(title: "烤鱼", emoji: "🐟", brand: nil, allergens: [], difficulty: 3, timeMinutes: 35),
        EatCardSpec(title: "烤肉饭", emoji: "🍱", brand: nil, allergens: [], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "炸鸡套餐", emoji: "🍗", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "汉堡", emoji: "🍔", brand: nil, allergens: ["小麦", "奶"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "披萨", emoji: "🍕", brand: nil, allergens: ["小麦", "奶"], difficulty: 2, timeMinutes: 25),
        EatCardSpec(title: "麦当劳", emoji: "🍟", brand: "麦当劳", allergens: ["小麦"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "肯德基", emoji: "🍗", brand: "肯德基", allergens: ["小麦"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "肉夹馍", emoji: "🥙", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 10),
        EatCardSpec(title: "牛肉面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "担担面", emoji: "🍝", brand: nil, allergens: ["小麦", "花生"], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "凉皮", emoji: "🥗", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10),
        // B1 扩展
        EatCardSpec(title: "牛肉面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "火锅", emoji: "🍲", brand: nil, allergens: [], difficulty: 2, timeMinutes: 90),
        EatCardSpec(title: "麻辣烫", emoji: "🌶️", brand: nil, allergens: [], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "三明治套餐", emoji: "🥪", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "日本料理", emoji: "🍣", brand: nil, allergens: ["鱼", "大豆"], difficulty: 3, timeMinutes: 45),
        EatCardSpec(title: "韩式炸鸡", emoji: "🍗", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 25)
    ]

    private static let teaCards: [EatCardSpec] = [
        EatCardSpec(title: "珍珠奶茶", emoji: "🧋", brand: nil, allergens: ["奶"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "美式咖啡", emoji: "☕", brand: nil, allergens: [], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "拿铁", emoji: "☕", brand: nil, allergens: ["奶"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "芝士蛋糕", emoji: "🍰", brand: nil, allergens: ["奶", "小麦", "鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "提拉米苏", emoji: "🍰", brand: nil, allergens: ["奶", "小麦", "鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "曲奇", emoji: "🍪", brand: nil, allergens: ["小麦", "奶"], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "水果拼盘", emoji: "🍓", brand: nil, allergens: [], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "酸奶", emoji: "🥛", brand: nil, allergens: ["奶"], difficulty: 1, timeMinutes: 2),
        EatCardSpec(title: "冰淇淋", emoji: "🍦", brand: nil, allergens: ["奶", "鸡蛋"], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "布丁", emoji: "🍮", brand: nil, allergens: ["奶", "鸡蛋"], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "马卡龙", emoji: "🍬", brand: nil, allergens: ["奶", "小麦"], difficulty: 1, timeMinutes: 3),
        EatCardSpec(title: "可丽饼", emoji: "🥞", brand: nil, allergens: ["小麦", "奶", "鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "华夫饼", emoji: "🧇", brand: nil, allergens: ["小麦", "奶", "鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "草莓蛋糕", emoji: "🍰", brand: nil, allergens: ["奶", "小麦", "鸡蛋"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "巧克力", emoji: "🍫", brand: nil, allergens: ["奶"], difficulty: 1, timeMinutes: 1),
        EatCardSpec(title: "气泡水", emoji: "🥤", brand: nil, allergens: [], difficulty: 1, timeMinutes: 2),
        // B1 扩展
        EatCardSpec(title: "杨枝甘露", emoji: "🥭", brand: nil, allergens: [], difficulty: 2, timeMinutes: 10),
        EatCardSpec(title: "双皮奶", emoji: "🥛", brand: nil, allergens: ["奶"], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "芒果班戟", emoji: "🥞", brand: nil, allergens: ["奶", "小麦", "鸡蛋"], difficulty: 2, timeMinutes: 10)
    ]

    private static let dinnerCards: [EatCardSpec] = [
        EatCardSpec(title: "麻婆豆腐", emoji: "🌶️", brand: nil, allergens: ["大豆"], difficulty: 3, timeMinutes: 20),
        EatCardSpec(title: "回锅肉", emoji: "🥩", brand: nil, allergens: ["大豆"], difficulty: 3, timeMinutes: 25),
        EatCardSpec(title: "水煮鱼", emoji: "🐟", brand: nil, allergens: ["大豆"], difficulty: 4, timeMinutes: 30),
        EatCardSpec(title: "夫妻肺片", emoji: "🥗", brand: nil, allergens: ["大豆"], difficulty: 4, timeMinutes: 30),
        EatCardSpec(title: "宫保鸡丁", emoji: "🍗", brand: nil, allergens: ["花生", "大豆"], difficulty: 3, timeMinutes: 25),
        EatCardSpec(title: "酸菜鱼", emoji: "🐟", brand: nil, allergens: [], difficulty: 3, timeMinutes: 30),
        EatCardSpec(title: "糖醋里脊", emoji: "🥩", brand: nil, allergens: ["小麦", "鸡蛋"], difficulty: 3, timeMinutes: 25),
        EatCardSpec(title: "红烧肉", emoji: "🥩", brand: nil, allergens: [], difficulty: 4, timeMinutes: 60),
        EatCardSpec(title: "番茄牛腩", emoji: "🍅", brand: nil, allergens: [], difficulty: 3, timeMinutes: 40),
        EatCardSpec(title: "东坡肉", emoji: "🥩", brand: nil, allergens: [], difficulty: 4, timeMinutes: 90),
        EatCardSpec(title: "白切鸡", emoji: "🍗", brand: nil, allergens: [], difficulty: 3, timeMinutes: 45),
        EatCardSpec(title: "蒸蛋", emoji: "🥚", brand: nil, allergens: ["鸡蛋"], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "烤鸭", emoji: "🦆", brand: nil, allergens: ["小麦"], difficulty: 4, timeMinutes: 60),
        EatCardSpec(title: "叉烧", emoji: "🥩", brand: nil, allergens: [], difficulty: 3, timeMinutes: 60),
        EatCardSpec(title: "蛋炒饭", emoji: "🍳", brand: nil, allergens: ["鸡蛋"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "皮蛋豆腐", emoji: "🥚", brand: nil, allergens: ["大豆", "鸡蛋"], difficulty: 2, timeMinutes: 10),
        // B1 扩展
        EatCardSpec(title: "葱爆羊肉", emoji: "🥩", brand: nil, allergens: [], difficulty: 4, timeMinutes: 30),
        EatCardSpec(title: "葱油拌面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "三杯鸡", emoji: "🍗", brand: nil, allergens: [], difficulty: 3, timeMinutes: 30),
        EatCardSpec(title: "苦瓜炒蛋", emoji: "🥚", brand: nil, allergens: ["鸡蛋"], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "西芹百合", emoji: "🥬", brand: nil, allergens: [], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "酱牛肉", emoji: "🥩", brand: nil, allergens: [], difficulty: 3, timeMinutes: 60)
    ]

    private static let latenightCards: [EatCardSpec] = [
        EatCardSpec(title: "烧烤", emoji: "🍢", brand: nil, allergens: [], difficulty: 2, timeMinutes: 30),
        EatCardSpec(title: "麻辣烫", emoji: "🌶️", brand: nil, allergens: [], difficulty: 1, timeMinutes: 15),
        EatCardSpec(title: "小龙虾", emoji: "🦐", brand: nil, allergens: [], difficulty: 2, timeMinutes: 30),
        EatCardSpec(title: "炸鸡", emoji: "🍗", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "披萨", emoji: "🍕", brand: nil, allergens: ["小麦", "奶"], difficulty: 1, timeMinutes: 25),
        EatCardSpec(title: "关东煮", emoji: "🍢", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "烤面筋", emoji: "🍢", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "烤冷面", emoji: "🥞", brand: nil, allergens: ["小麦", "鸡蛋"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "烤红薯", emoji: "🍠", brand: nil, allergens: [], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "烤玉米", emoji: "🌽", brand: nil, allergens: [], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "卤味", emoji: "🥚", brand: nil, allergens: [], difficulty: 2, timeMinutes: 15),
        EatCardSpec(title: "凉皮", emoji: "🥗", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "白粥", emoji: "🥣", brand: nil, allergens: [], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "泡面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 1, timeMinutes: 5),
        EatCardSpec(title: "牛肉面", emoji: "🍜", brand: nil, allergens: ["小麦"], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "烤串", emoji: "🍢", brand: nil, allergens: [], difficulty: 2, timeMinutes: 20),
        // B1 扩展
        EatCardSpec(title: "冒菜", emoji: "🌶️", brand: nil, allergens: [], difficulty: 1, timeMinutes: 20),
        EatCardSpec(title: "酸辣粉", emoji: "🍜", brand: nil, allergens: ["花生"], difficulty: 1, timeMinutes: 10),
        EatCardSpec(title: "烤脑花", emoji: "🧠", brand: nil, allergens: [], difficulty: 2, timeMinutes: 20),
        EatCardSpec(title: "麻辣香锅", emoji: "🌶️", brand: nil, allergens: ["花生"], difficulty: 3, timeMinutes: 30)
    ]

    // D029/D032 · 在家做（18 张 · 覆盖全部 5 个时段）
    //
    // 这些卡的 availableTimes 是 TimeOfDay.allCases，意思是任何时段都能抽到。
    // 由用户在偏好设置 / Tab 切换时手动控制是否启用此卡池。
    private static let homeCookCards: [EatCardSpec] = [
        // 早餐 · 5 张
        EatCardSpec(
            title: "煎蛋", emoji: "🍳", brand: nil, allergens: ["鸡蛋"],
            difficulty: 1, timeMinutes: 5,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蛋",
            recipe: Recipe(ingredients: ["鸡蛋 2 个", "盐少许"], steps: ["热锅", "打蛋", "煎至金黄"], cookTimeMinutes: 5, difficulty: 1)
        ),
        EatCardSpec(
            title: "葱油饼", emoji: "🥞", brand: nil, allergens: ["小麦"],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "面"
        ),
        EatCardSpec(
            title: "白粥 + 咸菜", emoji: "🥣", brand: nil, allergens: [],
            difficulty: 1, timeMinutes: 30,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "粥"
        ),
        EatCardSpec(
            title: "蛋炒饭", emoji: "🍳", brand: nil, allergens: ["鸡蛋"],
            difficulty: 1, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "米"
        ),
        EatCardSpec(
            title: "燕麦杯", emoji: "🥣", brand: nil, allergens: ["麦"],
            difficulty: 1, timeMinutes: 5,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "燕麦"
        ),
        // 午餐 · 4 张
        EatCardSpec(
            title: "番茄炒蛋", emoji: "🍅", brand: nil, allergens: ["鸡蛋"],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蛋",
            recipe: Recipe(ingredients: ["番茄 2 个", "鸡蛋 3 个", "盐", "糖"], steps: ["番茄切块", "鸡蛋打散", "先炒蛋盛出", "炒番茄", "合在一起"], cookTimeMinutes: 15, difficulty: 2)
        ),
        EatCardSpec(
            title: "麻婆豆腐（家常版）", emoji: "🌶️", brand: nil, allergens: ["大豆"],
            difficulty: 3, timeMinutes: 25,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "豆"
        ),
        EatCardSpec(
            title: "家常面条", emoji: "🍝", brand: nil, allergens: ["小麦", "鸡蛋"],
            difficulty: 2, timeMinutes: 20,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "面"
        ),
        EatCardSpec(
            title: "扬州炒饭", emoji: "🍚", brand: nil, allergens: ["鸡蛋"],
            difficulty: 2, timeMinutes: 20,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "米"
        ),
        // 下午茶 · 3 张
        EatCardSpec(
            title: "自制水果茶", emoji: "🍓", brand: nil, allergens: [],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "水果"
        ),
        EatCardSpec(
            title: "酸奶水果杯", emoji: "🥛", brand: nil, allergens: ["奶"],
            difficulty: 1, timeMinutes: 5,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "甜品"
        ),
        EatCardSpec(
            title: "蒸蛋", emoji: "🥚", brand: nil, allergens: ["鸡蛋"],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蛋",
            recipe: Recipe(ingredients: ["鸡蛋 2 个", "温水", "盐"], steps: ["蛋液加水 1:1", "过筛去泡", "中小火蒸 12 分钟"], cookTimeMinutes: 15, difficulty: 2)
        ),
        // 晚餐 · 5 张
        EatCardSpec(
            title: "红烧肉（家常版）", emoji: "🥩", brand: nil, allergens: [],
            difficulty: 4, timeMinutes: 90,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "猪"
        ),
        EatCardSpec(
            title: "糖醋里脊（家常版）", emoji: "🥩", brand: nil, allergens: ["小麦", "鸡蛋"],
            difficulty: 3, timeMinutes: 30,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "猪"
        ),
        EatCardSpec(
            title: "宫保鸡丁（家常版）", emoji: "🍗", brand: nil, allergens: ["花生", "大豆"],
            difficulty: 3, timeMinutes: 30,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "鸡"
        ),
        EatCardSpec(
            title: "青椒土豆丝", emoji: "🥔", brand: nil, allergens: [],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蔬"
        ),
        EatCardSpec(
            title: "西红柿炒蛋", emoji: "🍅", brand: nil, allergens: ["鸡蛋"],
            difficulty: 2, timeMinutes: 15,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蛋"
        ),
        // 夜宵 · 3 张
        EatCardSpec(
            title: "泡面", emoji: "🍜", brand: nil, allergens: ["小麦"],
            difficulty: 1, timeMinutes: 5,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "面"
        ),
        EatCardSpec(
            title: "煎蛋夜宵", emoji: "🍳", brand: nil, allergens: ["鸡蛋"],
            difficulty: 1, timeMinutes: 5,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "蛋"
        ),
        EatCardSpec(
            title: "烤红薯（家用烤箱）", emoji: "🍠", brand: nil, allergens: [],
            difficulty: 1, timeMinutes: 60,
            scenario: EatScenario.homeCook, availableTimes: Array(TimeOfDay.allCases),
            mainIngredient: "烤"
        )
    ]

    // MARK: 玩啥 4 卡池 × 10 张 = 40 张

    static let playPools: [PlayPoolSpec] = [
        PlayPoolSpec(name: "室内单人", icon: "house.fill", sortOrder: 0, category: "solo_indoor", cards: [
            PlayCardSpec(title: "看一部电影", emoji: "🎬", difficulty: 1, timeMinutes: 120, metadata: ["style": "passive"]),
            PlayCardSpec(title: "读一本书", emoji: "📚", difficulty: 2, timeMinutes: 60, metadata: ["style": "calm"]),
            PlayCardSpec(title: "玩电子游戏", emoji: "🎮", difficulty: 1, timeMinutes: 90, metadata: ["style": "fun"]),
            PlayCardSpec(title: "做手账", emoji: "✏️", difficulty: 2, timeMinutes: 60, metadata: ["style": "creative"]),
            PlayCardSpec(title: "学做一道菜", emoji: "🍳", difficulty: 3, timeMinutes: 60, metadata: ["style": "creative"]),
            PlayCardSpec(title: "练字", emoji: "✍️", difficulty: 2, timeMinutes: 30, metadata: ["style": "calm"]),
            PlayCardSpec(title: "做冥想", emoji: "🧘", difficulty: 2, timeMinutes: 20, metadata: ["style": "calm"]),
            PlayCardSpec(title: "听播客", emoji: "🎙️", difficulty: 1, timeMinutes: 60, metadata: ["style": "passive"]),
            PlayCardSpec(title: "拼乐高", emoji: "🧱", difficulty: 3, timeMinutes: 90, metadata: ["style": "creative"]),
            PlayCardSpec(title: "练瑜伽", emoji: "🧘‍♀️", difficulty: 2, timeMinutes: 45, metadata: ["style": "calm"]),
            // B1 扩展
            PlayCardSpec(title: "画一幅画", emoji: "🎨", difficulty: 3, timeMinutes: 90, metadata: ["style": "creative"]),
            PlayCardSpec(title: "学一首歌", emoji: "🎵", difficulty: 3, timeMinutes: 60, metadata: ["style": "creative"]),
            PlayCardSpec(title: "泡一杯手冲咖啡", emoji: "☕", difficulty: 2, timeMinutes: 15, metadata: ["style": "calm"]),
            PlayCardSpec(title: "整理相册", emoji: "📸", difficulty: 2, timeMinutes: 30, metadata: ["style": "creative"]),
            PlayCardSpec(title: "学一门外语", emoji: "📚", difficulty: 3, timeMinutes: 60, metadata: ["style": "creative"])
        ]),
        PlayPoolSpec(name: "室内多人", icon: "person.3.fill", sortOrder: 1, category: "group_indoor", cards: [
            PlayCardSpec(title: "桌游之夜", emoji: "🎲", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "火锅聚会", emoji: "🍲", difficulty: 2, timeMinutes: 90, metadata: ["style": "social"]),
            PlayCardSpec(title: "KTV 唱 K", emoji: "🎤", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "打麻将", emoji: "🀄", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "剧本杀", emoji: "🎭", difficulty: 3, timeMinutes: 180, metadata: ["style": "social"]),
            PlayCardSpec(title: "家庭影院", emoji: "📺", difficulty: 1, timeMinutes: 120, metadata: ["style": "passive"]),
            PlayCardSpec(title: "打扑克", emoji: "🃏", difficulty: 2, timeMinutes: 60, metadata: ["style": "social"]),
            PlayCardSpec(title: "密室逃脱", emoji: "🔐", difficulty: 4, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "一起做甜品", emoji: "🍰", difficulty: 3, timeMinutes: 90, metadata: ["style": "creative"]),
            PlayCardSpec(title: "棋牌室", emoji: "♟️", difficulty: 2, timeMinutes: 90, metadata: ["style": "social"]),
            // B1 扩展
            PlayCardSpec(title: "一起做甜品", emoji: "🍰", difficulty: 3, timeMinutes: 90, metadata: ["style": "creative"]),
            PlayCardSpec(title: "包场玩 VR", emoji: "🥽", difficulty: 2, timeMinutes: 90, metadata: ["style": "social"]),
            PlayCardSpec(title: "羽毛球双打", emoji: "🏸", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "一起做陶艺", emoji: "🏺", difficulty: 3, timeMinutes: 120, metadata: ["style": "creative"]),
            PlayCardSpec(title: "桌面足球", emoji: "⚽", difficulty: 2, timeMinutes: 60, metadata: ["style": "social"])
        ]),
        PlayPoolSpec(name: "室外单人", icon: "figure.walk", sortOrder: 2, category: "solo_outdoor", cards: [
            PlayCardSpec(title: "公园散步", emoji: "🌳", difficulty: 1, timeMinutes: 30, metadata: ["style": "calm"]),
            PlayCardSpec(title: "City Walk", emoji: "🚶", difficulty: 2, timeMinutes: 90, metadata: ["style": "explore"]),
            PlayCardSpec(title: "骑自行车", emoji: "🚴", difficulty: 3, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "慢跑", emoji: "🏃", difficulty: 3, timeMinutes: 45, metadata: ["style": "active"]),
            PlayCardSpec(title: "摄影采风", emoji: "📷", difficulty: 2, timeMinutes: 90, metadata: ["style": "explore"]),
            PlayCardSpec(title: "河边钓鱼", emoji: "🎣", difficulty: 2, timeMinutes: 180, metadata: ["style": "calm"]),
            PlayCardSpec(title: "滑板", emoji: "🛹", difficulty: 3, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "轮滑", emoji: "⛸️", difficulty: 3, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "慢跑 5km", emoji: "🏃‍♀️", difficulty: 3, timeMinutes: 40, metadata: ["style": "active"]),
            PlayCardSpec(title: "city 不 walk", emoji: "🚶‍♀️", difficulty: 2, timeMinutes: 60, metadata: ["style": "explore"]),
            // B1 扩展
            PlayCardSpec(title: "探索一座新博物馆", emoji: "🏛️", difficulty: 2, timeMinutes: 120, metadata: ["style": "explore"]),
            PlayCardSpec(title: "公园放风筝", emoji: "🪁", difficulty: 2, timeMinutes: 90, metadata: ["style": "active"]),
            PlayCardSpec(title: "独自露营", emoji: "⛺", difficulty: 4, timeMinutes: 1440, metadata: ["style": "active"]),
            PlayCardSpec(title: "看日出", emoji: "🌅", difficulty: 2, timeMinutes: 180, metadata: ["style": "calm"]),
            PlayCardSpec(title: "踩单车逛公园", emoji: "🚴", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"])
        ]),
        PlayPoolSpec(name: "室外多人", icon: "figure.run", sortOrder: 3, category: "group_outdoor", cards: [
            PlayCardSpec(title: "爬山", emoji: "⛰️", difficulty: 4, timeMinutes: 240, metadata: ["style": "active"]),
            PlayCardSpec(title: "野餐", emoji: "🧺", difficulty: 2, timeMinutes: 120, metadata: ["style": "social"]),
            PlayCardSpec(title: "玩飞盘", emoji: "🥏", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "踢足球", emoji: "⚽", difficulty: 3, timeMinutes: 90, metadata: ["style": "active"]),
            PlayCardSpec(title: "打羽毛球", emoji: "🏸", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "打篮球", emoji: "🏀", difficulty: 3, timeMinutes: 90, metadata: ["style": "active"]),
            PlayCardSpec(title: "打网球", emoji: "🎾", difficulty: 3, timeMinutes: 90, metadata: ["style": "active"]),
            PlayCardSpec(title: "游泳", emoji: "🏊", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "滑雪", emoji: "⛷️", difficulty: 4, timeMinutes: 240, metadata: ["style": "active"]),
            PlayCardSpec(title: "露营", emoji: "⛺", difficulty: 4, timeMinutes: 1440, metadata: ["style": "social"]),
            // B1 扩展
            PlayCardSpec(title: "团队拓展", emoji: "🤝", difficulty: 3, timeMinutes: 240, metadata: ["style": "social"]),
            PlayCardSpec(title: "打排球", emoji: "🏐", difficulty: 2, timeMinutes: 60, metadata: ["style": "active"]),
            PlayCardSpec(title: "海边烧烤", emoji: "🍖", difficulty: 3, timeMinutes: 180, metadata: ["style": "social"]),
            PlayCardSpec(title: "蹦床公园", emoji: "🤸", difficulty: 2, timeMinutes: 90, metadata: ["style": "active"]),
            PlayCardSpec(title: "主题乐园", emoji: "🎢", difficulty: 3, timeMinutes: 240, metadata: ["style": "social"])
        ])
    ]

    // MARK: 做啥 5 卡池 × 6 张 = 30 张

    static let doPools: [DoPoolSpec] = [
        DoPoolSpec(name: "整理", icon: "tray.full.fill", sortOrder: 0, category: "整理", cards: [
            DoCardSpec(title: "整理桌面", emoji: "🗂️", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理衣柜 1 层", emoji: "👕", difficulty: 2, timeMinutes: 20, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理书架", emoji: "📚", difficulty: 2, timeMinutes: 15, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理文件 5 分钟", emoji: "📁", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理手机相册", emoji: "📱", difficulty: 2, timeMinutes: 15, metadata: ["type": "micro"]),
            DoCardSpec(title: "清理邮箱", emoji: "📧", difficulty: 2, timeMinutes: 15, metadata: ["type": "micro"]),
            // B1 扩展
            DoCardSpec(title: "清理购物 App 收藏", emoji: "🛒", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理浏览器书签", emoji: "🔖", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理充电线", emoji: "🔌", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理钱包", emoji: "👛", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "扔过期物品", emoji: "🗑️", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理 App 桌面", emoji: "📱", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"])
        ]),
        DoPoolSpec(name: "清洁", icon: "sparkles", sortOrder: 1, category: "清洁", cards: [
            DoCardSpec(title: "洗碗", emoji: "🍽️", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "洗杯子", emoji: "🥤", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "擦桌子", emoji: "🧽", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "拖 1 个房间", emoji: "🧹", difficulty: 2, timeMinutes: 15, metadata: ["type": "micro"]),
            DoCardSpec(title: "擦窗户 1 面", emoji: "🪟", difficulty: 2, timeMinutes: 15, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理床铺", emoji: "🛏️", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            // B1 扩展
            DoCardSpec(title: "倒垃圾", emoji: "🗑️", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理桌面摆件", emoji: "🖼️", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "擦洗洗手间", emoji: "🚿", difficulty: 2, timeMinutes: 20, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理鞋", emoji: "👟", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "整理化妆品", emoji: "💄", difficulty: 1, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "擦鞋", emoji: "👞", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"])
        ]),
        DoPoolSpec(name: "健康", icon: "heart.fill", sortOrder: 2, category: "健康", cards: [
            DoCardSpec(title: "喝一杯水", emoji: "💧", difficulty: 1, timeMinutes: 1, metadata: ["type": "micro"]),
            DoCardSpec(title: "站起来伸展", emoji: "🤸", difficulty: 1, timeMinutes: 3, metadata: ["type": "rescue"]),
            DoCardSpec(title: "深呼吸 5 次", emoji: "🌬️", difficulty: 1, timeMinutes: 2, metadata: ["type": "rescue"]),
            DoCardSpec(title: "闭眼休息 5 分钟", emoji: "😌", difficulty: 1, timeMinutes: 5, metadata: ["type": "rescue"]),
            DoCardSpec(title: "吃一份水果", emoji: "🍎", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "午睡 20 分钟", emoji: "😴", difficulty: 1, timeMinutes: 20, metadata: ["type": "rescue"]),
            // B1 扩展
            DoCardSpec(title: "吃一份蔬菜", emoji: "🥬", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "吃一份坚果", emoji: "🥜", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"]),
            DoCardSpec(title: "喝一杯牛奶", emoji: "🥛", difficulty: 1, timeMinutes: 2, metadata: ["type": "micro"]),
            DoCardSpec(title: "做眼保健操", emoji: "👀", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"]),
            DoCardSpec(title: "转脖子 5 次", emoji: "🔄", difficulty: 1, timeMinutes: 1, metadata: ["type": "micro"]),
            DoCardSpec(title: "踮脚 10 次", emoji: "🦶", difficulty: 1, timeMinutes: 1, metadata: ["type": "micro"])
        ]),
        DoPoolSpec(name: "急救", icon: "exclamationmark.triangle.fill", sortOrder: 3, category: "急救", cards: [
            DoCardSpec(title: "放下手机 5 分钟", emoji: "📵", difficulty: 2, timeMinutes: 5, metadata: ["type": "rescue"]),
            DoCardSpec(title: "站起来走 2 步", emoji: "🚶", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "喝一杯温水", emoji: "☕", difficulty: 1, timeMinutes: 2, metadata: ["type": "rescue"]),
            DoCardSpec(title: "闭上眼睛 30 秒", emoji: "🙈", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "握拳松开 5 次", emoji: "✊", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "深呼吸 10 次", emoji: "😮‍💨", difficulty: 1, timeMinutes: 2, metadata: ["type": "rescue"]),
            // B1 扩展
            DoCardSpec(title: "捏捏肩膀", emoji: "💆", difficulty: 1, timeMinutes: 2, metadata: ["type": "rescue"]),
            DoCardSpec(title: "闻一下喜欢的味道", emoji: "🌸", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "抱抱自己", emoji: "🤗", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "看看窗外", emoji: "🪟", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "做 5 个开合跳", emoji: "🤸", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"]),
            DoCardSpec(title: "哼一首歌", emoji: "🎵", difficulty: 1, timeMinutes: 1, metadata: ["type": "rescue"])
        ]),
        DoPoolSpec(name: "沟通 + 学习", icon: "bubble.left.and.bubble.right.fill", sortOrder: 4, category: "成长", cards: [
            DoCardSpec(title: "回一条信息", emoji: "💬", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"]),
            DoCardSpec(title: "打一个问候电话", emoji: "📞", difficulty: 2, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "写一张便签", emoji: "📝", difficulty: 2, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "读一篇短文", emoji: "📖", difficulty: 2, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "学一个新词", emoji: "📝", difficulty: 2, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "听一段 5 分钟播客", emoji: "🎧", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            // B1 扩展
            DoCardSpec(title: "回一条工作消息", emoji: "💼", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"]),
            DoCardSpec(title: "看一篇文章", emoji: "📄", difficulty: 2, timeMinutes: 10, metadata: ["type": "micro"]),
            DoCardSpec(title: "练 5 分钟字", emoji: "✍️", difficulty: 1, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "看 5 分钟纪录片", emoji: "🎬", difficulty: 2, timeMinutes: 5, metadata: ["type": "micro"]),
            DoCardSpec(title: "做 5 分钟冥想", emoji: "🧘", difficulty: 2, timeMinutes: 5, metadata: ["type": "rescue"]),
            DoCardSpec(title: "给家人发一条问候", emoji: "💝", difficulty: 1, timeMinutes: 3, metadata: ["type": "micro"])
        ])
    ]

    // MARK: 拍啥 5 卡池 × 6 张 = 30 张

    static let photoPools: [PhotoPoolSpec] = [
        PhotoPoolSpec(name: "单人", icon: "person.fill", sortOrder: 0, category: "solo", cards: [
            PhotoCardSpec(title: "半身微笑", emoji: "🙂", metadata: ["pose": "upper_body"]),
            PhotoCardSpec(title: "侧面剪影", emoji: "🌅", metadata: ["pose": "side"]),
            PhotoCardSpec(title: "背影照", emoji: "🚶", metadata: ["pose": "back"]),
            PhotoCardSpec(title: "回眸一笑", emoji: "😊", metadata: ["pose": "look_back"]),
            PhotoCardSpec(title: "双手比心", emoji: "🫶", metadata: ["pose": "heart_hands"]),
            PhotoCardSpec(title: "全身站立", emoji: "🧍", metadata: ["pose": "full_body"]),
            // B1 扩展
            PhotoCardSpec(title: "低头沉思", emoji: "🤔", metadata: ["pose": "thinking"]),
            PhotoCardSpec(title: "大笑自然", emoji: "😄", metadata: ["pose": "laugh"]),
            PhotoCardSpec(title: "扶帽姿势", emoji: "🎩", metadata: ["pose": "hat"]),
            PhotoCardSpec(title: "手插口袋", emoji: "👖", metadata: ["pose": "pocket"]),
            PhotoCardSpec(title: "远眺", emoji: "🌄", metadata: ["pose": "look_far"]),
            PhotoCardSpec(title: "戴墨镜", emoji: "🕶️", metadata: ["pose": "sunglasses"]),
            PhotoCardSpec(title: "手托下巴", emoji: "🤭", metadata: ["pose": "chin"])
        ]),
        PhotoPoolSpec(name: "情侣", icon: "heart.fill", sortOrder: 1, category: "couple", cards: [
            PhotoCardSpec(title: "情侣对视", emoji: "💑", metadata: ["pose": "face_to_face"]),
            PhotoCardSpec(title: "情侣背影", emoji: "👫", metadata: ["pose": "back_together"]),
            PhotoCardSpec(title: "牵手特写", emoji: "🤝", metadata: ["pose": "hand_hold"]),
            PhotoCardSpec(title: "额头靠", emoji: "💕", metadata: ["pose": "forehead"]),
            PhotoCardSpec(title: "拥抱", emoji: "🤗", metadata: ["pose": "hug"]),
            PhotoCardSpec(title: "亲额头", emoji: "💋", metadata: ["pose": "kiss_forehead"]),
            // B1 扩展
            PhotoCardSpec(title: "亲吻脸颊", emoji: "💋", metadata: ["pose": "kiss_cheek"]),
            PhotoCardSpec(title: "公主抱", emoji: "👸", metadata: ["pose": "carry"]),
            PhotoCardSpec(title: "一起看远方", emoji: "🌅", metadata: ["pose": "look_far"]),
            PhotoCardSpec(title: "背后环抱", emoji: "🤗", metadata: ["pose": "back_hug"]),
            PhotoCardSpec(title: "十指相扣", emoji: "🤞", metadata: ["pose": "fingers"]),
            PhotoCardSpec(title: "额头贴贴", emoji: "💕", metadata: ["pose": "forehead"]),
            PhotoCardSpec(title: "对视微笑", emoji: "😊", metadata: ["pose": "smile"])
        ]),
        PhotoPoolSpec(name: "朋友", icon: "person.2.fill", sortOrder: 2, category: "friend", cards: [
            PhotoCardSpec(title: "朋友合影", emoji: "📸", metadata: ["pose": "group"]),
            PhotoCardSpec(title: "搞怪合影", emoji: "🤪", metadata: ["pose": "funny"]),
            PhotoCardSpec(title: "比心合影", emoji: "🫶", metadata: ["pose": "heart"]),
            PhotoCardSpec(title: "跳跃抓拍", emoji: "🦘", metadata: ["pose": "jump"]),
            PhotoCardSpec(title: "干杯合影", emoji: "🍻", metadata: ["pose": "cheers"]),
            PhotoCardSpec(title: "搞怪表情", emoji: "😜", metadata: ["pose": "expression"]),
            // B1 扩展
            PhotoCardSpec(title: "一起跳舞", emoji: "💃", metadata: ["pose": "dance"]),
            PhotoCardSpec(title: "击掌庆祝", emoji: "🙌", metadata: ["pose": "high_five"]),
            PhotoCardSpec(title: "围圈抱", emoji: "🫂", metadata: ["pose": "group_hug"]),
            PhotoCardSpec(title: "举手欢呼", emoji: "🙋", metadata: ["pose": "cheer"]),
            PhotoCardSpec(title: "并排走", emoji: "🚶‍♀️", metadata: ["pose": "walk"]),
            PhotoCardSpec(title: "坐地上聊天", emoji: "🪑", metadata: ["pose": "sit_chat"]),
            PhotoCardSpec(title: "戴墨镜合照", emoji: "🕶️", metadata: ["pose": "sunglasses_group"])
        ]),
        PhotoPoolSpec(name: "旅行", icon: "airplane", sortOrder: 3, category: "travel", cards: [
            PhotoCardSpec(title: "景点打卡", emoji: "🗽", metadata: ["pose": "landmark"]),
            PhotoCardSpec(title: "地标合影", emoji: "🏛️", metadata: ["pose": "monument"]),
            PhotoCardSpec(title: "风景人像", emoji: "🏞️", metadata: ["pose": "scenic"]),
            PhotoCardSpec(title: "城市全景", emoji: "🌆", metadata: ["pose": "cityscape"]),
            PhotoCardSpec(title: "公路旅行", emoji: "🛣️", metadata: ["pose": "road"]),
            PhotoCardSpec(title: "夕阳剪影", emoji: "🌇", metadata: ["pose": "sunset"]),
            // B1 扩展
            PhotoCardSpec(title: "海边沙滩", emoji: "🏖️", metadata: ["pose": "beach"]),
            PhotoCardSpec(title: "山顶俯瞰", emoji: "⛰️", metadata: ["pose": "mountain"]),
            PhotoCardSpec(title: "古镇小巷", emoji: "🏘️", metadata: ["pose": "old_town"]),
            PhotoCardSpec(title: "夜景霓虹", emoji: "🌃", metadata: ["pose": "neon"]),
            PhotoCardSpec(title: "雨伞下", emoji: "☂️", metadata: ["pose": "umbrella"]),
            PhotoCardSpec(title: "火车窗外", emoji: "🚂", metadata: ["pose": "train_window"]),
            PhotoCardSpec(title: "秋日红叶", emoji: "🍁", metadata: ["pose": "autumn"]),
            PhotoCardSpec(title: "圣诞夜", emoji: "🎄", metadata: ["pose": "christmas"])
        ]),
        PhotoPoolSpec(name: "美食 + 静物", icon: "fork.knife", sortOrder: 4, category: "still", cards: [
            PhotoCardSpec(title: "食物摆盘", emoji: "🍱", metadata: ["pose": "food_plate"]),
            PhotoCardSpec(title: "饮品特写", emoji: "🍹", metadata: ["pose": "drink"]),
            PhotoCardSpec(title: "甜品", emoji: "🍰", metadata: ["pose": "dessert"]),
            PhotoCardSpec(title: "咖啡拉花", emoji: "☕", metadata: ["pose": "coffee"]),
            PhotoCardSpec(title: "水果特写", emoji: "🍓", metadata: ["pose": "fruit"]),
            PhotoCardSpec(title: "桌面一角", emoji: "🪴", metadata: ["pose": "tabletop"]),
            // B1 扩展
            PhotoCardSpec(title: "奶茶拉花", emoji: "🧋", metadata: ["pose": "bubble_tea"]),
            PhotoCardSpec(title: "街边小吃", emoji: "🍢", metadata: ["pose": "street_food"]),
            PhotoCardSpec(title: "家庭聚餐", emoji: "🍽️", metadata: ["pose": "family_meal"]),
            PhotoCardSpec(title: "便当盒", emoji: "🍱", metadata: ["pose": "bento"]),
            PhotoCardSpec(title: "日式寿司", emoji: "🍣", metadata: ["pose": "sushi"]),
            PhotoCardSpec(title: "路边咖啡杯", emoji: "☕", metadata: ["pose": "street_coffee"]),
            PhotoCardSpec(title: "野餐篮", emoji: "🧺", metadata: ["pose": "picnic"]),
            PhotoCardSpec(title: "家居绿植", emoji: "🌿", metadata: ["pose": "plants"])
        ])
    ]
}

// MARK: - 主料启发式推断（D054 修复）

extension SeedData {
    /// 主料关键字表（顺序敏感：长关键字在前，短关键字在后）
    ///
    /// 匹配规则：title.contains(pattern) 命中即返回对应 ingredient。
    /// 例如 title = "黄焖鸡米饭" → 先命中 "黄焖鸡米饭" → "鸡"。
    private static let mainIngredientPatterns: [(pattern: String, ingredient: String)] = [
        // 长关键字（避免被短关键字误匹配）
        ("金枪鱼三明治", "鱼"),
        ("三明治套餐", "西餐"),
        ("鸡蛋汉堡", "鸡"),
        ("韩式炸鸡", "鸡"),
        ("黄焖鸡米饭", "鸡"),
        ("番茄牛腩", "牛"),
        ("宫保鸡丁", "鸡"),
        ("葱爆羊肉", "羊"),
        ("糖醋里脊", "猪"),
        ("皮蛋瘦肉粥", "粥"),
        ("皮蛋豆腐", "豆"),
        ("日式寿司", "鱼"),
        ("珍珠奶茶", "奶茶"),
        ("芒果班戟", "甜品"),
        ("现磨豆浆", "豆"),
        ("杨枝甘露", "甜品"),
        ("双皮奶", "甜品"),
        ("鸡蛋灌饼", "面"),
        ("苦瓜炒蛋", "蔬"),
        ("西芹百合", "蔬"),
        ("葱油拌面", "面"),
        ("酸辣粉", "面"),
        ("烤冷面", "面"),
        ("兰州拉面", "面"),
        ("担担面", "面"),
        ("牛肉面", "牛"),
        ("葱油饼", "面"),
        // 中关键字
        ("麦当劳", "西餐"),
        ("肯德基", "西餐"),
        ("白切鸡", "鸡"),
        ("三杯鸡", "鸡"),
        ("蒸蛋", "蛋"),
        ("茶叶蛋", "蛋"),
        ("蛋炒饭", "米"),
        ("蛋包饭", "米"),
        ("牛排", "牛"),
        ("东坡肉", "猪"),
        ("回锅肉", "猪"),
        ("红烧肉", "猪"),
        ("肉夹馍", "猪"),
        ("肉包", "面"),
        ("卤味", "卤"),
        ("酱牛肉", "牛"),
        ("酸菜鱼", "鱼"),
        ("水煮鱼", "鱼"),
        ("麻婆豆腐", "豆"),
        ("小笼包", "面"),
        ("煎饺", "面"),
        ("煎饼果子", "面"),
        ("凉皮", "面"),
        ("螺蛳粉", "面"),
        ("沙县小吃", "面"),
        ("烤肉饭", "米"),
        ("皮蛋", "蛋"),
        ("芝士蛋糕", "甜品"),
        ("草莓蛋糕", "甜品"),
        ("提拉米苏", "甜品"),
        ("马卡龙", "甜品"),
        ("可丽饼", "甜品"),
        ("华夫饼", "甜品"),
        ("冰淇淋", "甜品"),
        ("燕麦杯", "燕麦"),
        ("酸奶麦片", "燕麦"),
        ("小米粥", "粥"),
        ("白粥", "粥"),
        ("烤鸭", "鸭"),
        ("叉烧", "猪"),
        // 短关键字
        ("鸡", "鸡"),
        ("鸭", "鸭"),
        ("羊", "羊"),
        ("猪", "猪"),
        ("鱼", "鱼"),
        ("虾", "虾"),
        ("蟹", "蟹"),
        ("肉", "猪"),
        ("牛", "牛"),
        ("豆腐", "豆"),
        ("豆浆", "豆"),
        ("面", "面"),
        ("粥", "粥"),
        ("饭", "米"),
        ("蛋糕", "甜品"),
        ("曲奇", "甜品"),
        ("布丁", "甜品"),
        ("巧克力", "甜品"),
        ("酸奶", "甜品"),
        ("烧烤", "烤"),
        ("烤串", "烤"),
        ("烤面筋", "烤"),
        ("烤玉米", "烤"),
        ("烤红薯", "烤"),
        ("烤鱼", "鱼"),
        ("奶茶", "奶茶"),
        ("拿铁", "咖啡"),
        ("咖啡", "咖啡"),
        ("芒果", "水果"),
        ("草莓", "水果"),
        ("水果", "水果"),
        ("坚果", "坚果"),
        ("蔬菜", "蔬"),
        ("披萨", "西餐"),
        ("汉堡", "西餐"),
        ("三明治", "西餐"),
        ("寿司", "鱼"),
        ("燕麦", "燕麦"),
        ("麦片", "燕麦"),
        ("炸鸡", "鸡"),
        ("蛋", "蛋"),
    ]

    /// 启发式推断主料（D054 修复）
    ///
    /// - 返回 nil 时不参与 D054 主料去重（避免误伤主料不明确的菜如"麻辣烫""关东煮"）。
    /// - 优先级：title 含长关键字 → 短关键字，按数组顺序第一个命中返回。
    static func inferMainIngredient(from title: String) -> String? {
        for entry in mainIngredientPatterns where title.contains(entry.pattern) {
            return entry.ingredient
        }
        return nil
    }
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
    /// 主料（可选；未填时由 seedEatCards 启发式推断）
    ///
    /// D054 主料去重依赖此字段。nil 表示不参与主料去重。
    /// 旧 v1.0 默认值是 `["mainIngredient": title]`（每张卡主料都不同 = 失效），
    /// v1.1 改为显式指定或启发式推断。
    let mainIngredient: String?
    /// 用餐场景（D030 · 默认 `.takeout` 因为 v1 大部分卡是外卖）
    let scenario: EatScenario
    /// 适用的时段列表（D032 · 默认空；「在家做」卡覆盖全部时段）
    let availableTimes: [TimeOfDay]
    /// 菜谱（D041 · 可选；只有「在家做」卡会填）
    let recipe: Recipe?

    /// 自定义 init：参数顺序按"业务逻辑"组织（基础字段 → 场景元数据），
    /// 规避 Swift struct memberwise init 的"命名参数必须按字段顺序"限制。
    ///
    /// 所有可选参数都有默认值，调用方只需传关心的字段。
    init(
        title: String,
        emoji: String? = nil,
        brand: String? = nil,
        allergens: [String] = [],
        difficulty: Int = 1,
        timeMinutes: Int = 30,
        scenario: EatScenario = .takeout,
        availableTimes: [TimeOfDay] = [],
        mainIngredient: String? = nil,
        recipe: Recipe? = nil
    ) {
        self.title = title
        self.emoji = emoji
        self.brand = brand
        self.allergens = allergens
        self.difficulty = difficulty
        self.timeMinutes = timeMinutes
        self.scenario = scenario
        self.availableTimes = availableTimes
        self.mainIngredient = mainIngredient
        self.recipe = recipe
    }
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
    /// 费用档（D061 · v1.3 新增；默认 nil）
    let costLevel: CostLevel? = nil
}

private struct DoPoolSpec {
    let name: String
    let icon: String
    let sortOrder: Int
    let category: String
    let cards: [DoCardSpec]
}

private struct DoCardSpec {
    let title: String
    let emoji: String?
    let difficulty: Int
    let timeMinutes: Int
    let metadata: [String: String]?
}

private struct PhotoPoolSpec {
    let name: String
    let icon: String
    let sortOrder: Int
    let category: String
    let cards: [PhotoCardSpec]
}

private struct PhotoCardSpec {
    let title: String
    let emoji: String?
    let metadata: [String: String]?
}