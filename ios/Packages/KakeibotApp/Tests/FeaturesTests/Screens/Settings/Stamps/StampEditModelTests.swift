import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct StampEditModelTests {
    @Test
    func addsShelfIcon() async throws {
        let database = try Self.database()
        let model = StampEditModel(parts: .system(database))
        model.state.submodels.icon.state.fields.markKind = .emoji
        model.state.submodels.icon.inputEmoji("🎉")

        let isSaved = await model.save() != nil
        let shelf = try await database.shelfIconList()
        let last = try #require(shelf.shelfIcons.last)

        #expect(isSaved)
        #expect(shelf.shelfIcons.count == 9)
        #expect(shelf.icons[last.iconId]?.emoji == "🎉")
    }

    @Test
    func cannotSaveWithoutMark() throws {
        let database = try Self.database()
        let model = StampEditModel(parts: .system(database))

        model.state.submodels.icon.state.fields.markKind = .text

        #expect(!model.flow.output.canSave)
        #expect(model.flow.output.saveTitle == "アイコンを選んでください")
    }

    @Test
    func editsExistingShelfIcon() async throws {
        let database = try Self.database()
        let first = try await Self.firstShelfIcon(in: database)
        let model = StampEditModel(parts: .system(database), editing: first.id)

        await model.load()
        let loadedGlyph = model.state.submodels.icon.state.fields.glyph
        let changedBeforeEdit = model.flow.output.isChanged

        model.state.submodels.icon.state.fields.color = "#4A6FA5"
        let changedAfterEdit = model.flow.output.isChanged
        let isSaved = await model.save() != nil
        let shelf = try await database.shelfIconList()

        #expect(loadedGlyph == .star)
        #expect(!changedBeforeEdit)
        #expect(changedAfterEdit)
        #expect(isSaved)
        #expect(shelf.shelfIcons.first?.id == first.id)
        #expect(shelf.icons[first.iconId]?.color == "#4A6FA5")
    }

    @Test
    func hidesStamp() async throws {
        let database = try Self.database()
        let first = try await Self.firstShelfIcon(in: database)
        let model = StampEditModel(parts: .system(database), editing: first.id)
        await model.load()

        await model.flow.setHidden(true).value
        let shelf = try await database.shelfIconList()

        #expect(model.flow.state.outcome.value?.isHidden == true)
        #expect(model.flow.output.isHidden)
        #expect(shelf.shelfIcons.first?.archivedAt != nil)
    }
}

private extension StampEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())
        return database
    }

    static func firstShelfIcon(in database: AppDatabase) async throws -> ShelfIcon {
        let shelf = try await database.shelfIconList()
        return try #require(shelf.shelfIcons.first)
    }
}
