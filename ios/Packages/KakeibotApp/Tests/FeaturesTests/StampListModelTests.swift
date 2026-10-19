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
    func removesFromShelf() async throws {
        let database = try Self.database()
        let model = StampListModel(database: database)
        await model.load()
        let first = try #require(model.shown.first)

        await model.remove(first.id)

        #expect(model.shown.count == 7)
        #expect(!model.shown.contains { $0.id == first.id })
    }
}

private extension StampListModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())
        return database
    }
}
