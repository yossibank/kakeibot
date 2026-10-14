import Core
import Features
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

        try await database.setCategoryHidden(
            food.id,
            isHidden: true,
            at: Date()
        )
        let model = CategoryListModel(database: database)

        await model.load()
        let expenseShown = model.shown.map(\.name)
        let expenseHidden = model.hidden.map(\.name)

        model.kind = .income
        let incomeShown = model.shown.map(\.name)

        #expect(expenseShown.count == 11)
        #expect(expenseShown.first == "日用品")
        #expect(expenseHidden == ["食費"])
        #expect(incomeShown == ["給料", "臨時収入", "その他"])
    }

    @Test
    func savesMovedOrder() async throws {
        let database = try Self.database()
        let model = CategoryListModel(database: database)
        await model.load()
        let first = try #require(model.shown.first)
        let third = model.shown[2]

        model.move(first.id, to: third.id)
        let moving = model.shown.map(\.name)

        await model.finishMoving()
        let saved = model.shown.map(\.name)

        #expect(Array(moving.prefix(3)) == ["日用品", "交通", "食費"])
        #expect(saved == moving)
        #expect(model.movingOrder == nil)
    }
}

private extension CategoryListModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
