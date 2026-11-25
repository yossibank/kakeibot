import Core
@testable import FeatureModels
import Testing

@MainActor
struct EntryItemModelTests {
    @Test
    func startsNextDraftWithLastTaxRate() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel(isSlipOpen: true)
        entry.state.addItem(name: "牛乳", amount: 200, taxRate: .reduced)
        items.state.draft.name = "パン"

        items.reset(for: entry)

        #expect(items.state.isSlipOpen)
        #expect(items.state.draft.name.isEmpty)
        #expect(items.state.draft.taxRate == .reduced)
        #expect(items.state.draft.editing == nil)
    }

    @Test
    func fillsDraftFromEditedItem() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "卵", quantity: 3, amount: 600, taxRate: .reduced)

        items.edit(0, in: entry)
        let draft = items.state.draft
        items.edit(4, in: entry)

        #expect(draft.name == "卵")
        #expect(draft.unit.amount == 200)
        #expect(draft.quantityValue == 3)
        #expect(draft.taxRate == .reduced)
        #expect(draft.isEditing(0))
        #expect(draft.canSubmit)
        #expect(items.state.draft == draft)
    }

    @Test
    func keepsReadAmountUntilPriceChanges() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "割引セット", quantity: 3, amount: 100)

        items.edit(0, in: entry)
        let kept = items.state.draft
        items.state.draft.press(.digit(5))

        #expect(kept.lineQuantity == 3)
        #expect(kept.lineAmount == 100)
        #expect(items.state.draft.lineQuantity == 1)
        #expect(items.state.draft.lineAmount == 5)
    }

    @Test
    func addsItemFromDraft() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        items.state.draft.name = " パン "
        items.state.draft.taxRate = .standard
        items.state.draft.press(.digit(2))
        items.state.draft.press(.doubleZero)

        items.add(to: entry)

        #expect(entry.state.items.list.map(\.name) == ["パン"])
        #expect(entry.state.items.list.map(\.amount) == [200])
        #expect(entry.state.items.list.map(\.taxRate) == [.standard])
    }

    @Test
    func turnsDiscountNegativeAndHalvesUnit() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        items.state.draft.name = "値引"
        items.state.draft.press(.digit(5))
        items.state.draft.press(.doubleZero)
        items.state.draft.target = .quantity

        items.state.draft.toggleDiscount()
        items.state.draft.halveUnit()

        #expect(items.state.draft.isDiscount)
        #expect(items.state.draft.target == .unit)
        #expect(items.state.draft.unit.amount == 250)
        #expect(items.state.draft.lineAmount == -250)
    }

    @Test
    func refusesDraftWithoutNameOrPrice() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()

        items.state.draft.name = "  "
        items.state.draft.press(.digit(5))
        let unnamed = items.state.draft.canSubmit
        items.reset(for: entry)
        items.state.draft.name = "パン"
        let unpriced = items.state.draft.canSubmit
        items.state.draft.press(.digit(5))

        #expect(!unnamed)
        #expect(!unpriced)
        #expect(items.state.draft.canSubmit)
    }

    @Test
    func updatesEditedItem() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "牛乳", amount: 200)
        entry.state.addItem(name: "パン", amount: 300)
        items.edit(1, in: entry)
        items.state.draft.name = "食パン"
        items.state.draft.halveUnit()

        items.update(in: entry)

        #expect(entry.state.items.list.map(\.name) == ["牛乳", "食パン"])
        #expect(entry.state.items.list.map(\.amount) == [200, 150])
    }

    @Test
    func followsEditedRowWhenRowsAreRemovedAndRestored() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "牛乳", amount: 200)
        entry.state.addItem(name: "パン", amount: 300)
        items.edit(1, in: entry)

        items.state.draft.shiftEditing(afterRemoving: 0)
        items.remove(0, from: entry)
        let removed = try #require(items.state.removed)
        let shifted = items.state.draft.editing?.index
        items.restore(removed, in: entry)

        #expect(removed.item.name == "牛乳")
        #expect(shifted == 0)
        #expect(items.state.draft.isEditing(1))
        #expect(entry.state.items.list.map(\.name) == ["牛乳", "パン"])
    }

    @Test
    func asksToScrollOnlyToExistingRows() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "牛乳", amount: 200)

        items.scroll(to: 3, in: entry)
        let missing = items.state.scroll
        items.scroll(to: 0, in: entry)
        let first = items.state.scroll
        items.scroll(to: 0, in: entry)

        #expect(missing.value == nil)
        #expect(first.value == 0)
        #expect(items.state.scroll != first)
    }
}
