import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct RewardRuleEditModelTests {
    @Test
    func addsRule() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(database: database)
        model.name = "自炊した日"
        model.press(.digit(5))
        model.press(.digit(0))
        model.press(.digit(0))

        let isSaved = await model.save()
        let list = try await database.rewardRuleList()

        #expect(isSaved)
        #expect(list.rules.map(\.name) == ["自炊した日"])
        #expect(list.rules.map(\.amount) == [500])
    }

    @Test
    func cannotSaveWithoutAmount() throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(database: database)

        model.name = "自炊した日"

        #expect(!model.canSave)
        #expect(model.saveTitle == "金額を入れてください")
    }

    @Test
    func editsSavedRule() async throws {
        let database = try AppDatabase.inMemory()
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: 500, icon: icon)
        let rule = try await database.saveRewardRule(draft, at: Date())
        let model = RewardRuleEditModel(database: database, editing: rule.id)
        await model.load()

        let loaded = model.name
        let isChanged = model.isChanged
        model.name = "お弁当の日"

        #expect(loaded == "自炊した日")
        #expect(!isChanged)
        #expect(model.isChanged)
        #expect(model.amount == 500)
    }

    @Test
    func tellsWhenRuleCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(database: database)
        model.name = "自炊した日"
        model.press(.digit(5))
        try await database.failWrites(to: "reward_rule")

        let isSaved = await model.save()

        #expect(isSaved == false)
        #expect(model.errorNotice.message == "保存できませんでした")
    }

    @Test
    func deletesRuleWithoutLogs() async throws {
        let database = try AppDatabase.inMemory()
        let rule = try await Self.saveRule(in: database)
        let model = RewardRuleEditModel(database: database, editing: rule.id)
        await model.load()

        let deletion = await model.delete()
        let rules = try await database.rewardRuleList().rules

        #expect(model.hasLogs == false)
        #expect(deletion != nil)
        #expect(rules.isEmpty)
    }

    @Test
    func keepsRuleWithLogs() async throws {
        let database = try AppDatabase.inMemory()
        let rule = try await Self.saveRule(in: database)
        let day = try #require(LocalDate("2026-10-01"))
        try await database.setReward(rule.id, isAchieved: true, on: day, at: Date())
        let model = RewardRuleEditModel(database: database, editing: rule.id)
        await model.load()

        let deletion = await model.delete()
        let rules = try await database.rewardRuleList().rules

        #expect(model.hasLogs)
        #expect(deletion == nil)
        #expect(model.errorNotice.message == "削除できませんでした")
        #expect(rules.map(\.id) == [rule.id])
    }

    @Test
    func hidesRule() async throws {
        let database = try AppDatabase.inMemory()
        let rule = try await Self.saveRule(in: database)
        let model = RewardRuleEditModel(database: database, editing: rule.id)
        await model.load()

        let isHidden = await model.setHidden(true)
        let rules = try await database.rewardRuleList().rules

        #expect(isHidden)
        #expect(model.isHidden)
        #expect(rules.first?.isActive == false)
    }
}

private extension RewardRuleEditModelTests {
    static func saveRule(in database: AppDatabase) async throws -> RewardRule {
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: 500, icon: icon)

        return try await database.saveRewardRule(draft, at: Date())
    }
}
