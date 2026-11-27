import Core
@testable import FeatureModels
import Foundation
import Store
import Testing

@MainActor
struct EditFlowTests {
    @Test
    func placesSavedValueInOutcome() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = CategoryEditModel(parts: .system(database), kind: .income)
        model.state.fields.name = "配当"

        await model.flow.save().value
        let outcome = try #require(model.flow.state.outcome.value)
        let categories = try await database.categoryList().categories

        #expect(categories.contains { $0.id == outcome.saved?.id })
        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == nil)
        #expect(outcome.deletion == nil)
        #expect(outcome.closes)
    }

    @Test
    func placesNoOutcomeWhenSaveFails() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        model.state.fields.name = "自炊した日"
        model.state.press(.digit(5))
        try await database.failWrites(to: "reward_rule")

        await model.flow.save().value

        #expect(model.flow.state.outcome.value == nil)
        #expect(model.flow.state.outcome == ScreenOutcome())
        #expect(model.state.errorNotice.message == "保存できませんでした")
    }

    @Test
    func reportsEachSaveAsChange() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        await model.flow.save().value
        let first = model.flow.state.outcome
        await model.flow.save().value

        #expect(first.value?.saved != nil)
        #expect(model.flow.state.outcome != first)
    }

    @Test
    func placesHiddenInOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        await model.flow.setHidden(true).value
        let outcome = try #require(model.flow.state.outcome.value)

        #expect(outcome.isHidden == true)
        #expect(outcome.saved == nil)
        #expect(outcome.closes)
        #expect(model.flow.output.isHidden)
    }

    @Test
    func placesNoOutcomeWhenHidingFails() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        try await database.failWrites(to: "shelf_icon")

        await model.flow.setHidden(true).value

        #expect(model.flow.state.outcome.value == nil)
        #expect(!model.flow.output.isHidden)
    }

    @Test
    func placesDeletionInOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        await model.flow.delete().value
        let outcome = try #require(model.flow.state.outcome.value)
        let shelf = try await database.shelfIconList()

        #expect(outcome.deletion != nil)
        #expect(outcome.closes)
        #expect(!shelf.shelfIcons.contains { $0.id == stamp.id })
    }

    @Test
    func placesSaveAndHideInOneOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        model.state.icon.color = "#4A6FA5"

        await model.flow.saveTogglingHidden().value
        let outcome = try #require(model.flow.state.outcome.value)
        let shelf = try await database.shelfIconList()

        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == true)
        #expect(outcome.closes)
        #expect(model.flow.output.isHidden)
        #expect(shelf.shelfIcons.first { $0.id == stamp.id }?.archivedAt != nil)
    }

    @Test
    func keepsSheetOpenWhenHidingAfterSaveFails() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        model.state.icon.color = "#4A6FA5"
        try await database.failUpdates(to: "shelf_icon", changing: "archived_at")

        await model.flow.saveTogglingHidden().value
        let outcome = try #require(model.flow.state.outcome.value)

        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == nil)
        #expect(outcome.closes == false)
        #expect(model.flow.output.isHidden == false)
        #expect(model.state.errorNotice.message == "保存できませんでした")
    }

    @Test
    func savesWithoutHidingAfterFailedSaveAndHide() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        model.state.fields.name = "自炊した日"
        model.state.press(.digit(5))
        try await database.failWrites(to: "reward_rule")

        await model.flow.saveTogglingHidden().value

        #expect(model.flow.state.outcome.value == nil)
        #expect(!model.flow.state.task.isRunning)
    }

    @Test
    func keepsPanelOpenBehindPrompt() throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        let closed = model.state.presented.panel.current

        model.state.presented.panel.show(.amount)
        model.flow.state.presented.prompt.show(.delete)
        let opened = model.state.presented.panel.current

        model.state.presented.panel.closeAll()

        #expect(closed == nil)
        #expect(opened == .amount)
        #expect(model.state.presented.panel.current == nil)
        #expect(model.flow.state.presented.prompt.isShowing(.delete))
    }

    @Test
    func closesWithoutAskingWhenUnchanged() throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))

        model.flow.close()
        let outcome = try #require(model.flow.state.outcome.value)

        #expect(outcome.closes)
        #expect(outcome.saved == nil)
        #expect(model.flow.state.presented.prompt.current == nil)
    }

    @Test
    func asksBeforeDiscardingChanges() throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        model.state.fields.name = "自炊した日"

        model.flow.close()
        let asked = model.flow.state.presented.prompt.isShowing(.discard)
        let pending = model.flow.state.outcome.value
        model.flow.discard()

        #expect(asked)
        #expect(pending == nil)
        #expect(model.flow.state.outcome.value?.closes == true)
    }

    @Test
    func ignoresSecondSaveWhileSaving() async throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsRewardGoalEditModel(parts: .system(database))
        model.state.fields.name = "新しい靴"
        model.state.press(.digit(8))

        let first = model.flow.save()
        let second = model.flow.save()
        await first.value
        await second.value
        let goals = try await database.rewardBank().waitingGoals

        #expect(goals.count == 1)
        #expect(!model.flow.state.task.isRunning)
    }
}

private extension EditFlowTests {
    static func stamp() async throws -> (AppDatabase, ShelfIcon) {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())

        let shelf = try await database.shelfIconList()

        return try (database, #require(shelf.shelfIcons.first))
    }
}
