import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct StampListModelTests {
    @Test
    func showsShelfInOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(database: database)

        await model.load()
        let glyphs = model.shown.map { model.icon(for: $0)?.glyph }

        #expect(glyphs.count == 8)
        #expect(glyphs.first == .star)
        #expect(glyphs.last == .moon)
    }

    @Test
    func savesMovedOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(database: database)
        await model.load()
        let first = try #require(model.shown.first)

        model.move(first.id, to: 2)
        await model.finishMoving()
        let shelf = try await database.iconShelf()

        #expect(model.movingOrder == nil)
        #expect(shelf.shelfIcons[2].id == first.id)
    }

    @Test
    func cancelsMovedOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(database: database)
        await model.load()
        let ids = model.shown.map(\.id)

        model.move(ids[0], to: 3)
        model.cancelMoving()

        #expect(model.shown.map(\.id) == ids)
    }

    @Test
    func hidesAndShowsStamp() async throws {
        let database = try Self.database()
        let model = StampListModel(database: database)
        await model.load()
        let first = try #require(model.shown.first)

        await model.hide(first.id)
        let shown = model.shown.map(\.id)
        let hidden = model.hidden.map(\.id)

        await model.show(first.id)

        #expect(shown.count == 7)
        #expect(hidden == [first.id])
        #expect(model.hidden.isEmpty)
        #expect(model.shown.first?.id == first.id)
    }
}

private extension StampListModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())
        return database
    }
}
