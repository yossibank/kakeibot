import Core
@testable import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func savesItemsWithEntry() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.addItem(name: "牛乳", amount: 400)

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
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.addItem(name: "牛乳", amount: 396)
        model.addItem(name: "パン", amount: 250)
        let followed = model.amount
        model.updateItem(at: 1, name: "パン", amount: 200)
        let updated = model.amount

        #expect(followed == 646)
        #expect(updated == 596)

        model.press(.digit(9))
        model.addItem(name: "卵", amount: 100)

        #expect(model.amount == 9)
        #expect(model.itemAdjustment == -687)

        model.adjustToItems()

        #expect(model.amount == 696)
    }

    @Test
    func restoresRemovedItemInPlace() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.addItem(name: "牛乳", amount: 396)
        model.addItem(name: "パン", amount: 250)

        let removed = try #require(model.removeItem(at: 0))
        let afterRemove = model.amount
        model.restoreItem(removed)

        #expect(afterRemove == 250)
        #expect(model.items.map(\.name) == ["牛乳", "パン"])
        #expect(model.amount == 646)
    }

    @Test
    func loadsItemsWhenEditing() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 500)
        let draft = EntryItem.Draft(name: "パン", amount: 250)
        var edited = EntryDraft(entry)
        edited.items = [draft]
        try await setup.database.saveEntry(edited, editing: entry.id, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        let loaded = model.items
        let unchanged = model.isChanged
        _ = model.removeItem(at: 0)

        #expect(loaded == [draft])
        #expect(!unchanged)
        #expect(model.isChanged)
        #expect(model.amount == 500)
    }

    @Test
    func followsItemTotalWithTax() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.addItem(name: "牛乳", quantity: 2, amount: 396, taxRate: .reduced)
        model.addItem(name: "食パン", amount: 250, taxRate: .reduced)
        model.addItem(name: "洗剤", amount: 398, taxRate: .standard)
        model.addItem(name: "弁当", amount: 540)

        #expect(model.itemTotals.subtotal == 1584)
        #expect(model.itemTotals.taxes.map(\.amount) == [51, 39])
        #expect(model.amount == 1674)
        #expect(model.itemAdjustment == 0)
    }

    @Test
    func keepsAmountWhenItemTotalIsNegative() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        model.addItem(name: "値引", amount: -30)

        model.adjustToItems()

        #expect(!model.canAdjustToItems)
        #expect(model.amount == 5)
    }

    @Test
    func countsItemsWithQuantity() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.addItem(name: "牛乳", quantity: 2, amount: 396)
        model.addItem(name: "パン", amount: 250)

        let matched = model.hasItemAdjustment
        model.press(.digit(9))

        #expect(model.itemCount == 3)
        #expect(!matched)
        #expect(model.hasItemAdjustment)
    }

    @Test
    func editsStoreAsFirstMemoLine() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.store = "青葉"
        let added = model.memo

        model.memo = "若葉\n特売"
        model.store = "青葉\n本店"

        #expect(added == "青葉")
        #expect(model.memo == "青葉 本店\n特売")
        #expect(model.store == "青葉 本店")
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
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        let all = model.itemNameSuggestions(for: " ")
        let milk = model.itemNameSuggestions(for: "乳")
        let exact = model.itemNameSuggestions(for: "パン")

        #expect(Set(all) == ["牛乳", "低脂肪乳", "パン"])
        #expect(Set(milk) == ["牛乳", "低脂肪乳"])
        #expect(exact.isEmpty)
    }

    @Test
    func showsQuantityOnlyWhenMany() {
        let pair = EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396)
        let single = EntryItem.Draft(name: "パン", amount: 250)

        #expect(EntryModel.quantityText(for: pair) == "×2")
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
