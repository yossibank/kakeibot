import Core
@testable import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func savesItemsWithEntry() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.addItem(name: "牛乳", amount: 400)

        let change = await model.save()
        let entryId = try #require(change?.entry.id)
        let items = try await setup.database.entryItems(of: entryId)

        #expect(change?.entry.amount == 400)
        #expect(items.map(\.name) == ["牛乳"])
        #expect(items.map(\.amount) == [400])
    }

    @Test
    func followsItemTotalWhileNoDifference() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.state.addItem(name: "牛乳", amount: 396)
        model.state.addItem(name: "パン", amount: 250)
        let followed = model.output.amount
        model.state.updateItem(at: 1, name: "パン", amount: 200)
        let updated = model.output.amount

        #expect(followed == 646)
        #expect(updated == 596)

        model.state.press(.digit(9))
        model.state.addItem(name: "卵", amount: 100)

        #expect(model.output.amount == 9)
        #expect(model.output.itemAdjustment == -687)

        model.state.adjustToItems()

        #expect(model.output.amount == 696)
    }

    @Test
    func restoresRemovedItemInPlace() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.addItem(name: "牛乳", amount: 396)
        model.state.addItem(name: "パン", amount: 250)

        let removed = try #require(model.state.removeItem(at: 0))
        let afterRemove = model.output.amount
        model.state.restoreItem(removed)

        #expect(afterRemove == 250)
        #expect(model.state.items.list.map(\.name) == ["牛乳", "パン"])
        #expect(model.output.amount == 646)
    }

    @Test
    func loadsItemsWhenEditing() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 500)
        let draft = EntryItem.Draft(name: "パン", amount: 250)
        var edited = EntryDraft(entry)
        edited.items = [draft]
        try await setup.database.saveEntry(edited, editing: entry.id, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        let loaded = model.state.items.list
        let unchanged = model.output.isChanged
        _ = model.state.removeItem(at: 0)

        #expect(loaded == [draft])
        #expect(!unchanged)
        #expect(model.output.isChanged)
        #expect(model.output.amount == 500)
    }

    @Test
    func followsItemTotalWithTax() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.state.addItem(name: "牛乳", quantity: 2, amount: 396, taxRate: .reduced)
        model.state.addItem(name: "食パン", amount: 250, taxRate: .reduced)
        model.state.addItem(name: "洗剤", amount: 398, taxRate: .standard)
        model.state.addItem(name: "弁当", amount: 540)

        #expect(model.output.itemTotals.subtotal == 1584)
        #expect(model.output.itemTotals.taxes.map(\.amount) == [51, 39])
        #expect(model.output.amount == 1674)
        #expect(model.output.itemAdjustment == 0)
    }

    @Test
    func keepsAmountWhenItemTotalIsNegative() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.press(.digit(5))
        model.state.addItem(name: "値引", amount: -30)

        model.state.adjustToItems()

        #expect(!model.output.canAdjustToItems)
        #expect(model.output.amount == 5)
    }

    @Test
    func countsItemsWithQuantity() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.addItem(name: "牛乳", quantity: 2, amount: 396)
        model.state.addItem(name: "パン", amount: 250)

        let matched = model.output.hasItemAdjustment
        model.state.press(.digit(9))

        #expect(model.output.itemCount == 3)
        #expect(!matched)
        #expect(model.output.hasItemAdjustment)
    }

    @Test
    func editsStoreAsFirstMemoLine() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.state.store = "青葉"
        let added = model.state.memo

        model.state.memo = "若葉\n特売"
        model.state.store = "青葉\n本店"

        #expect(added == "青葉")
        #expect(model.state.memo == "青葉 本店\n特売")
        #expect(model.state.store == "青葉 本店")
    }

    @Test
    func suggestsRecentItemNames() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 500)
        var edited = EntryDraft(entry)
        edited.items = [
            EntryItem.Draft(name: "牛乳", amount: 200),
            EntryItem.Draft(name: "低脂肪乳", amount: 200),
            EntryItem.Draft(name: "パン", amount: 100)
        ]
        try await setup.database.saveEntry(edited, editing: entry.id, at: Date())
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        let all = model.output.itemNameSuggestions(for: " ")
        let milk = model.output.itemNameSuggestions(for: "乳")
        let exact = model.output.itemNameSuggestions(for: "パン")

        #expect(Set(all) == ["牛乳", "低脂肪乳", "パン"])
        #expect(Set(milk) == ["牛乳", "低脂肪乳"])
        #expect(exact.isEmpty)
    }

    @Test
    func showsQuantityOnlyWhenMany() {
        let pair = EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396)
        let uneven = EntryItem.Draft(name: "卵", quantity: 3, amount: 200)
        let single = EntryItem.Draft(name: "パン", amount: 250)

        #expect(EntryModel.quantityText(for: pair) == "2 × ¥198")
        #expect(EntryModel.quantityText(for: uneven) == "×3")
        #expect(EntryModel.quantityText(for: single) == nil)
    }

    @Test
    func splitsAmountIntoUnitPrice() {
        let pair = EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396)
        let odd = EntryItem.Draft(name: "卵", quantity: 3, amount: 100)
        let pairPrice = EntryModel.unitPrice(of: pair)
        let oddPrice = EntryModel.unitPrice(of: odd)

        #expect(pairPrice.unit == 198)
        #expect(pairPrice.quantity == 2)
        #expect(oddPrice.unit == 100)
        #expect(oddPrice.quantity == 1)
    }
}
