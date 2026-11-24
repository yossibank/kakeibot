import Core
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct CategoryListModelTests {
    @Test
    func splitsShownAndHiddenByKind() async throws {
        let database = try Self.database()
        let list = try await database.categoryList()
        let food = try #require(list.categories.first { $0.name == "食費" })
        try await database.setHidden(food.id, isHidden: true, at: Date())
        let model = CategoryListModel(database: database, clock: .system)

        await model.load()
        let expenseShown = model.output.shown.map(\.name)
        let expenseHidden = model.output.hidden.map(\.name)

        model.state.kind = .income
        let incomeShown = model.output.shown.map(\.name)

        #expect(expenseShown.count == 11)
        #expect(expenseShown.first == "日用品")
        #expect(expenseHidden == ["食費"])
        #expect(incomeShown == ["給料", "臨時収入", "その他"])
    }

    @Test
    func savesMovedOrder() async throws {
        let database = try Self.database()
        let model = CategoryListModel(database: database, clock: .system)
        await model.load()
        let first = try #require(model.output.shown.first)

        model.move(first.id, to: 2)
        let moving = model.output.shown.map(\.name)

        await model.finishMoving()
        let saved = model.output.shown.map(\.name)

        #expect(Array(moving.prefix(3)) == ["日用品", "交通", "食費"])
        #expect(saved == moving)
        #expect(model.state.movingOrder == nil)
    }

    @Test
    func hidesWhileMoving() async throws {
        let database = try Self.database()
        let model = CategoryListModel(database: database, clock: .system)
        await model.load()
        let first = try #require(model.output.shown.first)

        model.move(first.id, to: 4)
        await model.hide(first.id)

        #expect(model.output.hidden.map(\.name) == ["食費"])
        #expect(model.output.shown.first?.name == "日用品")
        #expect(model.state.movingOrder == nil)
    }

    @Test
    func showsHiddenCategory() async throws {
        let database = try Self.database()
        let model = CategoryListModel(database: database, clock: .system)
        await model.load()
        let first = try #require(model.output.shown.first)
        await model.hide(first.id)

        await model.show(first.id)

        #expect(model.output.hidden.isEmpty)
        #expect(model.output.shown.first?.name == "食費")
    }
}

private extension CategoryListModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
