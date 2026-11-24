import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct StampListModelTests {
    @Test
    func showsShelfInOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(parts: .system(database))

        await model.load()
        let glyphs = model.output.shown.map { model.output.icon(for: $0)?.glyph }

        #expect(glyphs.count == 8)
        #expect(glyphs.first == .star)
        #expect(glyphs.last == .moon)
    }

    @Test
    func savesMovedOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(parts: .system(database))
        await model.load()
        let first = try #require(model.output.shown.first)

        model.move(first.id, to: 2)
        await model.finishMoving()
        let shelf = try await database.shelfIconList()

        #expect(model.state.movingOrder == nil)
        #expect(shelf.shelfIcons[2].id == first.id)
    }

    @Test
    func cancelsMovedOrder() async throws {
        let database = try Self.database()
        let model = StampListModel(parts: .system(database))
        await model.load()
        let ids = model.output.shown.map(\.id)

        model.move(ids[0], to: 3)
        model.cancelMoving()

        #expect(model.output.shown.map(\.id) == ids)
    }

    @Test
    func hidesAndShowsStamp() async throws {
        let database = try Self.database()
        let model = StampListModel(parts: .system(database))
        await model.load()
        let first = try #require(model.output.shown.first)

        await model.hide(first.id)
        let shown = model.output.shown.map(\.id)
        let hidden = model.output.hidden.map(\.id)

        await model.show(first.id)

        #expect(shown.count == 7)
        #expect(hidden == [first.id])
        #expect(model.output.hidden.isEmpty)
        #expect(model.output.shown.first?.id == first.id)
    }
}

private extension StampListModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertShelfIfEmpty(at: Date())
        return database
    }
}
