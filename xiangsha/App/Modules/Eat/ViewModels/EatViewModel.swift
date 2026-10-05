//
//  EatViewModel.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  关联决策：D015（统一入口）+ D035（按钮三态）+ D088（过敏警告）+ D006（4h 冷却）
//

import Foundation
import SwiftUI
import SwiftData

/// 模块 A · 吃啥 ViewModel
@Observable
@MainActor
final class EatViewModel {
    // MARK: - UI 状态

    var engine: DrawEngine
    var scene: DecisionScene?
    var selectedPool: CardPool?
    var pools: [CardPool] = []
    var userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    var lastResult: DrawResult?
    var isLoading: Bool = false
    var error: DrawEngineError?

    /// L2 过敏警告（D088）— 是否正在显示
    var showingAllergenWarning: Bool = false

    /// 当前抽到的卡片是否已收藏
    var isCurrentFavorite: Bool = false

    /// D135 emoji 评分状态：用户对当前抽到的卡的评分
    var currentRating: EmojiRating?

    /// 🦊 评分反馈文案（fox-persona §7.2）
    var ratingFeedback: String?

    /// D134 连续无候选计数
    var consecutiveNoCandidatesCount: Int = 0

    /// D134 不决策模式是否显示
    var showingNoDecisionPanel: Bool = false

    /// 注入 ModelContext（v1 简化：让 VM 直接写库）
    var modelContext: ModelContext?

    init(
        engine: DrawEngine = RuleBasedEngine(),
        scene: DecisionScene? = nil,
        selectedPool: CardPool? = nil,
        userProfileSnapshot: UserProfileSnapshot = UserProfileSnapshot()
    ) {
        self.engine = engine
        self.scene = scene
        self.selectedPool = selectedPool
        self.userProfileSnapshot = userProfileSnapshot
    }

    // MARK: - 业务动作

    func selectPool(_ pool: CardPool) {
        selectedPool = pool
    }

    func draw() async {
        // 兜底：如果 scene.cardPools 没自动加载（SwiftData 关系惰性），直接从 context 拉
        var effectivePool = selectedPool
        if effectivePool == nil, let scene {
            if !scene.cardPools.isEmpty {
                effectivePool = scene.cardPools.first
            } else if let context = modelContext {
                // 用 predicate 直接 query，避开关系惰性问题
                let sceneID = scene.id
                let descriptor = FetchDescriptor<CardPool>(
                    predicate: #Predicate { $0.scene?.id == sceneID }
                )
                if let first = try? context.fetch(descriptor).first {
                    effectivePool = first
                }
            }
        }
        guard let pool = effectivePool else {
            error = .invalidContext(reason: "无可用卡池")
            recordNoCandidates()
            checkNoDecisionTrigger()
            return
        }

        isLoading = true
        error = nil
        showingAllergenWarning = false
        defer { isLoading = false }

        let context = DrawContext(
            pool: pool,
            userProfileSnapshot: userProfileSnapshot
        )

        do {
            let result = try await engine.draw(context: context)
            lastResult = result
            resetNoDecisionCounter()  // 成功抽到 → 重置
            // 检查 L2 过敏警告（fallbackLevel == .l2Allergen）
            if result.fallbackLevel == .l2Allergen {
                showingAllergenWarning = true
            }
            // 收藏状态查询
            updateFavoriteStatus()
        } catch let engineError as DrawEngineError {
            self.error = engineError
            handleFallback(engineError)
        } catch {
            self.error = .invalidContext(reason: error.localizedDescription)
        }
    }

    /// 接受结果（D035 "就这个了 ✅"）→ 写 DrawRecord
    func accept() {
        guard let result = lastResult, let modelContext else { return }
        recordDraw(result: result, action: .accept)
        // 清空字段
        clearCurrent()
    }

    /// 拒绝（D025 "换一个" / "不想要"）→ 写 DrawRecord + 设置 4h 冷却
    func reject() {
        guard let result = lastResult, let modelContext else { return }
        recordDraw(result: result, action: .reject)
        setExcludeUntil(cardID: result.card.id, hours: 4)
        clearCurrent()
    }

    /// 重抽（D006 "换一个 🔁"）→ 不写 DrawRecord（redraw.isPersistent = false）
    func redraw() async {
        await draw()
    }

    /// 切换收藏（⭐ 收藏按钮）
    func toggleFavorite() {
        guard let result = lastResult,
              let modelContext else { return }
        let cardID = result.card.id

        // 查询现有收藏
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            // 取消收藏
            modelContext.delete(existing)
        } else {
            // 加收藏（需要先查询 Card 实体）
            let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
            if let card = (try? modelContext.fetch(cardDescriptor))?.first {
                let fav = Favorite(card: card)
                modelContext.insert(fav)
            }
        }
        try? modelContext.save()
        updateFavoriteStatus()
    }

    /// 重置错误状态
    func dismissError() {
        error = nil
        showingAllergenWarning = false
    }

    /// 主动加载初始数据（替代 @Query 的异步时序问题）
    ///
    /// SwiftData @Query 首次 fetch 是异步的，且 xiangshawApp.init() 的 seed 任务可能比 .task 慢，
    /// 这里最多重试 20 次（每次 100ms），确保拿到数据。
    func loadInitialData(context: ModelContext) async {
        var scenes: [DecisionScene] = []
        for _ in 0..<20 {
            let sceneDescriptor = FetchDescriptor<DecisionScene>(
                predicate: #Predicate { $0.typeRaw == "eat" }
            )
            scenes = (try? context.fetch(sceneDescriptor)) ?? []
            if !scenes.isEmpty { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        self.scene = scenes.first

        // D033 · 按当前时段自动选 pool（fallback 到第一个）
        if selectedPool == nil, let scene = self.scene {
            let sceneID = scene.id
            var allPools: [CardPool] = []
            for _ in 0..<20 {
                allPools = (try? context.fetch(FetchDescriptor<CardPool>())) ?? []
                if !allPools.isEmpty { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let scenePools = allPools.filter { $0.scene?.id == sceneID }
            self.pools = scenePools  // 让 PoolPickerView 始终有数据可显示
            let currentTime = TimeOfDay.from()
            // 「在家做」卡池任何时段都匹配；其他时段卡池按名字前缀匹配
            let preferred = scenePools.first { pool in
                if pool.name == "在家做" { return true }
                return pool.name.contains(currentTime.title)
            } ?? scenePools.first
            self.selectedPool = preferred
        }
    }

    /// D134 不决策模式触发判断（连续 L1 兜底 ≥ 3 次）
    func shouldTriggerNoDecisionMode() -> Bool {
        consecutiveNoCandidatesCount >= 3
    }

    /// 标记一次无候选（D134 累计）
    func recordNoCandidates() {
        consecutiveNoCandidatesCount += 1
    }

    /// 重置 D134 累计（成功抽到时）
    func resetNoDecisionCounter() {
        consecutiveNoCandidatesCount = 0
    }

    /// D135 emoji 评分（用户主动评分）
    ///
    /// 评分逻辑：
    /// - 😋 → 写 DrawRecord(.accept, emojiRating: .like) + 更新 card 偏好权重
    /// - 😐 → 写 DrawRecord(.accept, emojiRating: .neutral)
    /// - 🙅 → 写 DrawRecord(.reject, emojiRating: .dislike) + 设 7d excludeUntil
    func rate(emoji: EmojiRating) {
        guard let result = lastResult, let modelContext else { return }
        currentRating = emoji
        ratingFeedback = emoji.feedbackText

        let cardID = result.card.id
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? modelContext.fetch(cardDescriptor))?.first else { return }

        switch emoji {
        case .like:
            // 喜欢 → 更新偏好 + 写 accept + DrawRecord
            recordDraw(result: result, action: .accept, emojiRating: emoji)
            updateCardPreference(card: card, liked: true)

        case .neutral:
            // 一般 → 写 accept
            recordDraw(result: result, action: .accept, emojiRating: emoji)

        case .dislike:
            // 不喜欢 → 写 reject + 7d excludeUntil + dislike flag
            recordDraw(result: result, action: .reject, emojiRating: emoji)
            setExcludeUntil(cardID: cardID, hours: 24 * 7) // 7d
            updateCardPreference(card: card, liked: false)
        }

        try? modelContext.save()
    }

    /// 清除评分反馈（用户读完反馈后）
    func clearRatingFeedback() {
        ratingFeedback = nil
        currentRating = nil
    }

    /// 更新 Card 偏好（D135 数据闭环）
    private func updateCardPreference(card: Card, liked: Bool) {
        var meta = card.metadata ?? [:]
        let key = "preferenceScore"
        let current = Double(meta[key] ?? "1.0") ?? 1.0
        // 简单累加：每次喜欢 +0.3，每次不喜欢 -0.3，clamp 到 [0.1, 2.0]
        let newScore = max(0.1, min(2.0, current + (liked ? 0.3 : -0.3)))
        meta[key] = String(format: "%.2f", newScore)
        card.metadata = meta
        card.updatedAt = Date()
    }

    // MARK: - 私有

    /// 兜底分类处理（D007 + D134）
    private func handleFallback(_ engineError: DrawEngineError) {
        switch engineError {
        case .noCandidates:
            recordNoCandidates()
            checkNoDecisionTrigger()
        case .invalidContext, .notImplemented:
            break
        }
    }

    /// D134 不决策模式触发检查
    private func checkNoDecisionTrigger() {
        if shouldTriggerNoDecisionMode() {
            showingNoDecisionPanel = true
        }
    }

    /// D134 三选项：跳过 / 改类别 / 自己决定
    func performNoDecisionAction(_ action: NoDecisionAction) {
        showingNoDecisionPanel = false
        consecutiveNoCandidatesCount = 0
        switch action {
        case .skip:
            // 🛌 跳过 — 直接关掉
            error = nil
        case .changeCategory:
            // 🔄 改类别 — 自动切换到下一个卡池
            switchToNextPool()
        case .decideMyself:
            // 💡 自己决定 — 让用户清空过敏原 / 加新卡
            // v1 简化：显示 toast 提示"去设置看看"
            error = .invalidContext(reason: "考虑去「设置 → 隐私」清空过敏原")
        }
    }

    /// D134 切换到下一个卡池
    private func switchToNextPool() {
        guard let pools = scene?.cardPools, !pools.isEmpty else { return }
        let currentID = selectedPool?.id
        let next = pools.first { $0.id != currentID } ?? pools.first
        if let next {
            selectedPool = next
            Task { await draw() }
        }
    }

    /// 写 DrawRecord
    private func recordDraw(result: DrawResult, action: DrawAction, emojiRating: EmojiRating? = nil) {
        guard let modelContext else { return }
        let cardID = result.card.id
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? modelContext.fetch(cardDescriptor))?.first else { return }

        let record = DrawRecord(
            card: card,
            action: action,
            candidatesBeforeFilter: result.candidatesBeforeFilter,
            candidatesAfterFilter: result.candidatesAfterFilter,
            fallbackUsed: result.fallbackUsed,
            fallbackLevel: result.fallbackLevel,
            timeOfDay: TimeOfDay.from(),
            drawsTodayAtTime: userProfileSnapshot.drawsToday,
            emojiRating: emojiRating
        )
        modelContext.insert(record)

        // D050 餐次平衡：accept 时把 card.category 写入 profile.lastMealOfToday
        // 后续抽签 DrawEngine.mealTimeFactor 会据此软调权（主食/菜/汤 = 1:1:0.5）
        if action == .accept {
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = (try? modelContext.fetch(profileDescriptor))?.first {
                profile.lastMealOfToday = card.category
                profile.updatedAt = Date()
            }
        }

        try? modelContext.save()
    }

    /// 设置卡片 4h 冷却（D006）
    private func setExcludeUntil(cardID: UUID, hours: Double) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? modelContext.fetch(descriptor))?.first else { return }
        card.excludeUntil = Date().addingTimeInterval(hours * 3600)
        card.updatedAt = Date()
        try? modelContext.save()
    }

    /// 查询当前抽到的卡是否已收藏
    private func updateFavoriteStatus() {
        guard let result = lastResult, let modelContext else {
            isCurrentFavorite = false
            return
        }
        let cardID = result.card.id
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.cardID == cardID })
        isCurrentFavorite = ((try? modelContext.fetch(descriptor))?.first) != nil
    }

    private func clearCurrent() {
        lastResult = nil
        isCurrentFavorite = false
        showingAllergenWarning = false
    }

    // MARK: - 派生显示属性

    var greetingText: String {
        guard let scene else { return "你好呀 🦊" }
        switch scene.type {
        case .eat: return "今天想去哪儿吃？🦊"
        case .play: return "今天想玩点啥？🦊"
        case .task: return "今天先做点啥？🦊"
        case .photo: return "今天拍点啥？🦊"
        }
    }

    var primaryButtonText: String {
        if isLoading { return "让小狐狸想想……🦊" }
        if lastResult != nil { return "就这个了 ✅" }
        return "抽一个试试"
    }

    var showsSecondaryActions: Bool {
        lastResult != nil
    }

    // MARK: - D045/D046 烹饪进度

    /// 已"做过"的卡 ID 集合（D046 进度计算用）
    var cookedCardIDs: Set<UUID> = []

    /// 当前 Eat Scene 的总卡数（进度分母）
    var totalCardsCount: Int {
        guard let scene else { return 0 }
        return scene.cardPools.flatMap { $0.cards }.filter { !$0.isHidden }.count
    }

    /// 已解锁进度（cookedCardIDs.count / totalCardsCount）
    var cookedCount: Int { cookedCardIDs.count }

    /// 刷新烹饪进度（call after markCooked / after view appear）
    func refreshCookedProgress() {
        guard let modelContext else { return }
        let records = (try? modelContext.fetch(FetchDescriptor<UserCookedRecord>())) ?? []
        cookedCardIDs = Set(records.map { $0.cardID })
    }

    /// 标记一道菜"我做完了"（D045/D046 · 写 UserCookedRecord）
    func markCooked(card: Card, noteText: String? = nil, rating: Int? = nil) {
        guard let modelContext else { return }
        let record = UserCookedRecord(card: card, noteText: noteText, rating: rating)
        modelContext.insert(record)
        try? modelContext.save()
        refreshCookedProgress()
    }

    // MARK: - 用户自定义卡（Card.isUserCreated = true）

    /// 用户新增一张自定义卡
    func createUserCard(
        title: String,
        emoji: String,
        scenario: EatScenario,
        category: String
    ) {
        guard let modelContext, let scene = self.scene, let pool = findOrCreateUserPool(scenario: scenario, category: category, scene: scene) else { return }
        let card = Card(
            title: title,
            scene: scene,
            pool: pool,
            emoji: emoji,
            category: category,
            isUserCreated: true,
            scenario: scenario
        )
        modelContext.insert(card)
        try? modelContext.save()
    }

    /// 删除一张用户自定义卡
    func deleteUserCard(_ card: Card) {
        guard let modelContext, card.isUserCreated else { return }
        modelContext.delete(card)
        try? modelContext.save()
    }

    /// 查找或创建"用户自定义"卡池（按 scenario + category 维度）
    private func findOrCreateUserPool(scenario: EatScenario, category: String, scene: DecisionScene) -> CardPool? {
        guard let modelContext else { return nil }
        let sceneID = scene.id
        let allPools = (try? modelContext.fetch(FetchDescriptor<CardPool>())) ?? []
        let userPools = allPools.filter { $0.scene?.id == sceneID && $0.isUserCreated }
        let poolName = "我的 \(category)"
        if let existing = userPools.first(where: { $0.name == poolName }) {
            return existing
        }
        let pool = CardPool(
            name: poolName,
            icon: "person.crop.circle.fill",
            sortOrder: 100,
            isUserCreated: true,
            scene: scene
        )
        modelContext.insert(pool)
        return pool
    }
}