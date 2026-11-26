import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func appliesReceiptReading() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let categoryId = model.state.category.id
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

        #expect(model.output.amount == 911)
        #expect(model.state.payment.date == date)
        #expect(model.state.fields.store == "スーパー青葉")
        #expect(model.state.items.list.map(\.name) == ["牛乳", "食パン"])
        #expect(model.state.category.id == categoryId)
        #expect(model.output.hasItemAdjustment)
    }

    @Test
    func appliesIncludedTaxFromReceipt() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                total: 3170,
                items: [
                    EntryItem.Draft(name: "絹香食パン", amount: 890, taxRate: .reduced),
                    EntryItem.Draft(name: "スイートポテト", amount: 2280, taxRate: .reduced)
                ],
                taxIncluded: true
            )
        )

        #expect(model.state.items.taxIncluded)
        #expect(model.output.itemTotal == 3170)
        #expect(!model.output.hasItemAdjustment)

        model.state.setTaxIncluded(false)

        #expect(model.output.itemTotal == 3423)
        #expect(model.output.amount == 3423)
    }

    @Test
    func keepsUnreadValuesFromReceipt() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.fields.memo = "店名\n2 行目"
        model.state.press(.digit(5))

        await model.apply(ReceiptReading(total: 0))

        #expect(model.output.amount == 5)
        #expect(model.state.payment.date == setup.date)
        #expect(model.state.fields.memo == "店名\n2 行目")
        #expect(model.state.items.list.isEmpty)
    }

    @Test
    func followsItemTotalWhenReceiptTotalIsUnread() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                items: [
                    EntryItem.Draft(name: "牛乳", amount: 396),
                    EntryItem.Draft(name: "食パン", amount: 220)
                ]
            )
        )

        #expect(model.output.amount == 616)
        #expect(!model.output.hasItemAdjustment)
    }

    @Test
    func marksSuspectItemsOnlyForReadItems() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        model.state.press(.digit(6))
        model.state.press(.digit(1))
        model.state.press(.digit(6))
        model.state.addItem(name: "牛乳", amount: 396)
        model.state.addItem(name: "食パン", amount: 220)
        model.state.addItem(name: "食パン", amount: 220)
        let typed = model.output.suspectItemIndices

        await model.apply(
            ReceiptReading(
                total: 616,
                items: [
                    EntryItem.Draft(name: "牛乳", amount: 396),
                    EntryItem.Draft(name: "食パン", amount: 220),
                    EntryItem.Draft(name: "食パン", amount: 220)
                ]
            )
        )

        #expect(typed.isEmpty)
        #expect(model.output.suspectItemIndices == [1, 2])
    }

    @Test
    func countsFreeReceiptsLeft() async throws {
        let setup = try await Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: 2)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        #expect(model.output.freeReceiptsLeft == 1)
    }

    @Test
    func remembersNamesUnderReadStore() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                store: "セブン新宿店",
                total: 396,
                items: [EntryItem.Draft(name: "ギユウニユウ", amount: 396)]
            )
        )
        model.state.fields.store = "セブン"
        model.state.updateItem(at: 0, name: "牛乳", amount: 396)
        _ = await model.save()
        let read = try await setup.database.itemNames(at: "セブン新宿店")
        let edited = try await setup.database.itemNames(at: "セブン")

        #expect(read == ["ギユウニユウ": "牛乳"])
        #expect(edited.isEmpty)
    }

    @Test
    func forgetsEarlierNamesWhenOnlyTotalIsRead() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        await model.apply(
            ReceiptReading(
                store: "スーパー青葉",
                items: [EntryItem.Draft(name: "ギユウニユウ", amount: 396)]
            )
        )
        model.state.updateItem(at: 0, name: "牛乳", amount: 396)
        await model.apply(ReceiptReading(store: "ドラッグ若葉", total: 500))
        _ = await model.save()
        let first = try await setup.database.itemNames(at: "スーパー青葉")
        let second = try await setup.database.itemNames(at: "ドラッグ若葉")

        #expect(first.isEmpty)
        #expect(second.isEmpty)
        #expect(model.state.items.list.allSatisfy { $0.readName == nil })
    }

    @Test
    func reportsAmountOnlyWhenReceiptSetsIt() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))

        let storeOnly = await model.apply(ReceiptReading(store: "スーパー青葉"))
        let total = await model.apply(ReceiptReading(total: 911))

        #expect(!storeOnly)
        #expect(total)
    }

    @Test
    func skipsCountWhenSavedAsTransfer() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        await model.apply(ReceiptReading(total: 911))
        model.select(.transfer)
        _ = await model.save()
        let count = try await setup.database.setting(.receiptSavedCount)

        #expect(count == 0)
    }

    @Test
    func countsOnlySavesFromReceipt() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        model.state.press(.digit(5))
        _ = await model.save()
        await model.startNext()
        let manual = try await setup.database.setting(.receiptSavedCount)

        await model.apply(ReceiptReading(total: 911))
        _ = await model.save()
        await model.startNext()
        let read = try await setup.database.setting(.receiptSavedCount)

        #expect(manual == 0)
        #expect(read == 1)
        #expect(model.input.receiptSavedCount == 1)
        #expect(model.output.showsReceiptGuide)
    }

    @Test
    func limitsFreeReceiptSaves() async throws {
        let setup = try await Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: EntryModel.freeReceiptLimit)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        #expect(!model.output.canReadReceipt(isPro: false))
        #expect(model.output.canReadReceipt(isPro: true))
    }

    @Test
    func remembersCorrectedItemNamesByStore() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
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
        model.state.updateItem(at: 0, name: "牛乳", amount: 396)
        _ = await model.save()
        await model.startNext()
        let names = try await setup.database.itemNames(at: "スーパー青葉")
        await model.apply(reading)

        #expect(names == ["ギユウニユウ": "牛乳"])
        #expect(model.state.items.list.map(\.name) == ["牛乳", "食パン"])
    }

    @Test
    func forgetsNameRestoredToTheReadText() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let reading = ReceiptReading(
            store: "スーパー青葉",
            total: 396,
            items: [EntryItem.Draft(name: "ギユウニユウ", amount: 396)]
        )

        await model.apply(reading)
        model.state.updateItem(at: 0, name: "低脂肪乳", amount: 396)
        _ = await model.save()
        await model.startNext()
        await model.apply(reading)
        model.state.updateItem(at: 0, name: "ギユウニユウ", amount: 396)
        _ = await model.save()
        await model.startNext()
        let names = try await setup.database.itemNames(at: "スーパー青葉")
        await model.apply(reading)

        #expect(names.isEmpty)
        #expect(model.state.items.list.map(\.name) == ["ギユウニユウ"])
    }

    @Test
    func keepsItemSourcesAlignedWithItems() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
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
        let removed = try #require(model.state.removeItem(at: 0))
        model.state.addItem(name: "卵", amount: 258)
        model.state.restoreItem(removed)
        model.state.updateItem(at: 0, name: "牛乳", amount: 396)
        model.state.updateItem(at: 2, name: "たまご", amount: 258)
        _ = await model.save()
        let names = try await setup.database.itemNames(at: "スーパー青葉")

        #expect(names == ["ギユウニユウ": "牛乳"])
    }
}
