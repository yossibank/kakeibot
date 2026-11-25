import Core
@testable import FeatureModels
import Foundation
import Store
import Testing

@MainActor
struct SettingsEditOutcomeTests {
    @Test
    func placesSavedValueInOutcome() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = CategoryEditModel(parts: .system(database), kind: .income)
        model.state.name = "配当"

        let saved = await model.save()
        let outcome = try #require(model.state.outcome.value)

        #expect(outcome.saved?.id == saved?.id)
        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == nil)
        #expect(outcome.deletion == nil)
        #expect(outcome.closes)
    }

    @Test
    func placesNoOutcomeWhenSaveFails() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        model.state.name = "自炊した日"
        model.state.press(.digit(5))
        try await database.failWrites(to: "reward_rule")

        let isSaved = await model.save()

        #expect(isSaved == false)
        #expect(model.state.outcome.value == nil)
        #expect(model.state.outcome == ScreenOutcome())
    }

    @Test
    func reportsEachSaveAsChange() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        _ = await model.save()
        let first = model.state.outcome
        _ = await model.save()

        #expect(first.value?.saved != nil)
        #expect(model.state.outcome != first)
    }

    @Test
    func placesHiddenInOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        _ = await model.setHidden(true)
        let outcome = try #require(model.state.outcome.value)

        #expect(outcome.isHidden == true)
        #expect(outcome.saved == nil)
        #expect(outcome.closes)
    }

    @Test
    func placesNoOutcomeWhenHidingFails() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        try await database.failWrites(to: "shelf_icon")

        let isHidden = await model.setHidden(true)

        #expect(isHidden == false)
        #expect(model.state.outcome.value == nil)
    }

    @Test
    func placesDeletionInOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()

        let deletion = await model.delete()
        let outcome = try #require(model.state.outcome.value)

        #expect(deletion != nil)
        #expect(outcome.deletion?.id == deletion?.id)
        #expect(outcome.closes)
    }

    @Test
    func placesSaveAndHideInOneOutcome() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        model.state.icon.color = "#4A6FA5"

        await model.saveTogglingHidden {
            await $0.save()
        }
        let outcome = try #require(model.state.outcome.value)
        let shelf = try await database.shelfIconList()

        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == true)
        #expect(outcome.closes)
        #expect(model.input.isHidden)
        #expect(model.state.prompt.togglesHiddenAfterSave == false)
        #expect(shelf.shelfIcons.first { $0.id == stamp.id }?.archivedAt != nil)
    }

    @Test
    func keepsSheetOpenWhenHidingAfterSaveFails() async throws {
        let (database, stamp) = try await Self.stamp()
        let model = StampEditModel(parts: .system(database), editing: stamp.id)
        await model.load()
        model.state.icon.color = "#4A6FA5"
        try await database.failUpdates(to: "shelf_icon", changing: "archived_at")

        await model.saveTogglingHidden {
            await $0.save()
        }
        let outcome = try #require(model.state.outcome.value)

        #expect(outcome.saved != nil)
        #expect(outcome.isHidden == nil)
        #expect(outcome.closes == false)
        #expect(model.input.isHidden == false)
        #expect(model.state.errorNotice.message == "保存できませんでした")
    }

    @Test
    func savesWithoutHidingAfterFailedSaveAndHide() async throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        model.state.name = "自炊した日"
        model.state.press(.digit(5))
        try await database.failWrites(to: "reward_rule")

        await model.saveTogglingHidden {
            await $0.save()
        }

        #expect(model.state.outcome.value == nil)
        #expect(model.state.prompt.togglesHiddenAfterSave == false)
    }
}

private extension SettingsEditOutcomeTests {
    static func stamp() async throws -> (AppDatabase, ShelfIcon) {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())

        let shelf = try await database.shelfIconList()

        return try (database, #require(shelf.shelfIcons.first))
    }
}
