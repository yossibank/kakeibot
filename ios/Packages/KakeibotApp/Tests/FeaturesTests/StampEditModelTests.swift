import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct StampEditModelTests {
    @Test
    func addsShelfIcon() async throws {
        let database = try Self.database()
        let model = StampEditModel(database: database)
        model.icon.markKind = .emoji
        model.icon.inputEmoji("🎉")

        let isSaved = await model.save()
        let shelf = try await database.iconShelf()
        let last = try #require(shelf.shelfIcons.last)

        #expect(isSaved)
        #expect(shelf.shelfIcons.count == 9)
        #expect(shelf.icons[last.iconId]?.emoji == "🎉")
    }

    @Test
    func cannotSaveWithoutMark() throws {
        let database = try Self.database()
        let model = StampEditModel(database: database)

        model.icon.markKind = .text

        #expect(!model.canSave)
        #expect(model.saveTitle == "アイコンを選んでください")
    }

    @Test
    func editsExistingShelfIcon() async throws {
        let database = try Self.database()
        let first = try await Self.firstShelfIcon(in: database)
        let model = StampEditModel(database: database, editing: first.id)

        await model.load()
        let loadedGlyph = model.icon.glyph
        let changedBeforeEdit = model.isChanged

        model.icon.color = "#4A6FA5"
        let changedAfterEdit = model.isChanged
        let isSaved = await model.save()
        let shelf = try await database.iconShelf()

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
        let model = StampEditModel(database: database, editing: first.id)
        await model.load()

        let isHidden = await model.setHidden(true)
        let shelf = try await database.iconShelf()

        #expect(isHidden)
        #expect(model.isHidden)
        #expect(shelf.shelfIcons.first?.archivedAt != nil)
    }
}

private extension StampEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())
        return database
    }

    static func firstShelfIcon(
        in database: AppDatabase
    ) async throws -> ShelfIcon {
        let shelf = try await database.iconShelf()
        return try #require(shelf.shelfIcons.first)
    }
}
