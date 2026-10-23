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
        #expect(model.saveTitle == "額を入れてください")
    }

    @Test
    func editsSavedRule() async throws {
        let database = try AppDatabase.inMemory()

        let draft = RewardRuleDraft(
            name: "自炊した日",
            amount: 500,
            icon: IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        )

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
}
