import Core
@testable import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func appliesReceiptReading() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let categoryId = model.categoryId
        let date = try #require(LocalDate("2026-10-03"))

        await model.apply(
            ReceiptReading(
                store: "スーパー青葉",
                date: date,
                total: 911,
                items: [
                    EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396),
                    EntryItem.Draft(name: "食パン", amount: 220)
                ]
            )
        )

        #expect(model.amount == 911)
        #expect(model.date == date)
        #expect(model.store == "スーパー青葉")
        #expect(model.items.map(\.name) == ["牛乳", "食パン"])
        #expect(model.categoryId == categoryId)
        #expect(model.hasItemAdjustment)
    }

    @Test
    func keepsUnreadValuesFromReceipt() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.memo = "店名\n2 行目"
        model.press(.digit(5))

        await model.apply(ReceiptReading(total: 0))

        #expect(model.amount == 5)
        #expect(model.date == setup.date)
        #expect(model.memo == "店名\n2 行目")
        #expect(model.items.isEmpty)
    }

    @Test
    func followsItemTotalWhenReceiptTotalIsUnread() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                items: [
                    EntryItem.Draft(name: "牛乳", amount: 396),
                    EntryItem.Draft(name: "食パン", amount: 220)
                ]
            )
        )

        #expect(model.amount == 616)
        #expect(!model.hasItemAdjustment)
    }

    @Test
    func countsOnlySavesFromReceipt() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.press(.digit(5))
        _ = await model.save()
        await model.startNext()
        let manual = try await setup.database.setting(.receiptSavedCount)

        await model.apply(ReceiptReading(total: 911))
        _ = await model.save()
        await model.startNext()
        let read = try await setup.database.setting(.receiptSavedCount)

        #expect(manual == 0)
        #expect(read == 1)
        #expect(model.receiptSavedCount == 1)
        #expect(!model.showsReceiptGuide)
    }

    @Test
    func limitsFreeReceiptSaves() async throws {
        let setup = try await Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: EntryModel.freeReceiptLimit)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        #expect(!model.canReadReceipt(isPro: false))
        #expect(model.canReadReceipt(isPro: true))
    }

    @Test
    func remembersCorrectedItemNamesByStore() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let reading = ReceiptReading(
            store: "スーパー青葉",
            total: 616,
            items: [
                EntryItem.Draft(name: "ギユウニユウ", amount: 396),
                EntryItem.Draft(name: "食パン", amount: 220)
            ]
        )

        await model.apply(reading)
        model.updateItem(at: 0, name: "牛乳", amount: 396)
        _ = await model.save()
        await model.startNext()
        let names = try await setup.database.itemNames(at: "スーパー青葉")
        await model.apply(reading)

        #expect(names == ["ギユウニユウ": "牛乳"])
        #expect(model.items.map(\.name) == ["牛乳", "食パン"])
    }

    @Test
    func keepsItemSourcesAlignedWithItems() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                store: "スーパー青葉",
                items: [
                    EntryItem.Draft(name: "ギユウニユウ", amount: 396),
                    EntryItem.Draft(name: "パン", amount: 220)
                ]
            )
        )
        let removed = try #require(model.removeItem(at: 0))
        model.addItem(name: "卵", amount: 258)
        model.restoreItem(removed)
        model.updateItem(at: 0, name: "牛乳", amount: 396)
        model.updateItem(at: 2, name: "たまご", amount: 258)
        _ = await model.save()
        let names = try await setup.database.itemNames(at: "スーパー青葉")

        #expect(names == ["ギユウニユウ": "牛乳"])
    }
}
