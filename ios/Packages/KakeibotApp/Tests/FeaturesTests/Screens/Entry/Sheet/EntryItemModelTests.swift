import Core
@testable import FeatureModels
import Testing
import TestSupport

@MainActor
struct EntryItemModelTests {
    @Test
    func startsNextDraftWithLastTaxRate() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel(isSlipOpen: true)
        entry.state.addItem(name: "牛乳", amount: 200, taxRate: .reduced)
        items.state.fields.draft.name = "パン"

        items.reset(for: entry)

        #expect(items.state.presented.isSlipOpen)
        #expect(items.state.fields.draft.name.isEmpty)
        #expect(items.state.fields.draft.taxRate == .reduced)
        #expect(items.state.fields.draft.editing == nil)
    }

    @Test
    func fillsDraftFromEditedItem() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "卵", quantity: 3, amount: 600, taxRate: .reduced)

        items.edit(0, in: entry)
        let draft = items.state.fields.draft
        items.edit(4, in: entry)

        #expect(draft.name == "卵")
        #expect(draft.unit.amount == 200)
        #expect(draft.quantityValue == 3)
        #expect(draft.taxRate == .reduced)
        #expect(draft.isEditing(0))
        #expect(draft.canSubmit)
        #expect(items.state.fields.draft == draft)
    }

    @Test
    func keepsReadAmountUntilPriceChanges() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "割引セット", quantity: 3, amount: 100)

        items.edit(0, in: entry)
        let kept = items.state.fields.draft
        items.state.fields.draft.press(.digit(5))

        #expect(kept.lineQuantity == 3)
        #expect(kept.lineAmount == 100)
        #expect(items.state.fields.draft.lineQuantity == 1)
        #expect(items.state.fields.draft.lineAmount == 5)
    }

    @Test
    func addsItemFromDraft() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        items.state.fields.draft.name = " パン "
        items.state.fields.draft.taxRate = .standard
        items.state.fields.draft.press(.digit(2))
        items.state.fields.draft.press(.doubleZero)

        items.add(to: entry)

        #expect(entry.state.items.list.map(\.name) == ["パン"])
        #expect(entry.state.items.list.map(\.amount) == [200])
        #expect(entry.state.items.list.map(\.taxRate) == [.standard])
    }

    @Test
    func turnsDiscountNegativeAndHalvesUnit() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        items.state.fields.draft.name = "値引"
        items.state.fields.draft.press(.digit(5))
        items.state.fields.draft.press(.doubleZero)
        items.state.fields.draft.target = .quantity

        items.state.fields.draft.toggleDiscount()
        items.state.fields.draft.halveUnit()

        #expect(items.state.fields.draft.isDiscount)
        #expect(items.state.fields.draft.target == .unit)
        #expect(items.state.fields.draft.unit.amount == 250)
        #expect(items.state.fields.draft.lineAmount == -250)
    }

    @Test
    func refusesDraftWithoutNameOrPrice() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()

        items.state.fields.draft.name = "  "
        items.state.fields.draft.press(.digit(5))
        let unnamed = items.state.fields.draft.canSubmit
        items.reset(for: entry)
        items.state.fields.draft.name = "パン"
        let unpriced = items.state.fields.draft.canSubmit
        items.state.fields.draft.press(.digit(5))

        #expect(!unnamed)
        #expect(!unpriced)
        #expect(items.state.fields.draft.canSubmit)
    }

    @Test
    func updatesEditedItem() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "牛乳", amount: 200)
        entry.state.addItem(name: "パン", amount: 300)
        items.edit(1, in: entry)
        items.state.fields.draft.name = "食パン"
        items.state.fields.draft.halveUnit()

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

        items.state.fields.draft.shiftEditing(afterRemoving: 0)
        items.remove(0, from: entry)
        let removed = try #require(items.state.notices.removed.current)
        let shifted = items.state.fields.draft.editing?.index
        items.restore(removed, in: entry)

        #expect(removed.item.name == "牛乳")
        #expect(shifted == 0)
        #expect(items.state.fields.draft.isEditing(1))
        #expect(entry.state.items.list.map(\.name) == ["牛乳", "パン"])
    }

    @Test
    func clearsRemovedItemNoticeAfterDuration() async throws {
        let entry = try await EntryModelTests.newModel()
        let clock = ManualWait()
        let items = EntryItemModel(isSlipOpen: false, wait: clock.wait)
        entry.state.addItem(name: "牛乳", amount: 200)

        items.remove(0, from: entry)
        await ObservationWait.until { clock.isSleeping }
        clock.advance(by: UndoNotice<EntryModel.RemovedItem>.duration - .seconds(1))
        let kept = items.state.notices.removed.current
        clock.advance(by: .seconds(1))
        await ObservationWait.until { items.state.notices.removed.current == nil }

        #expect(kept?.item.name == "牛乳")
        #expect(entry.state.items.list.isEmpty)
    }

    @Test
    func restoresRemovedItemBeforeDurationEnds() async throws {
        let entry = try await EntryModelTests.newModel()
        let clock = ManualWait()
        let items = EntryItemModel(isSlipOpen: false, wait: clock.wait)
        entry.state.addItem(name: "牛乳", amount: 200)
        entry.state.addItem(name: "パン", amount: 300)

        items.remove(0, from: entry)
        await ObservationWait.until { clock.isSleeping }
        clock.advance(by: UndoNotice<EntryModel.RemovedItem>.duration - .seconds(1))
        let removed = try #require(items.state.notices.removed.take())
        items.restore(removed, in: entry)
        clock.advance(by: .seconds(1))

        #expect(items.state.notices.removed.current == nil)
        #expect(entry.state.items.list.map(\.name) == ["牛乳", "パン"])
    }

    @Test
    func asksToScrollOnlyToExistingRows() async throws {
        let entry = try await EntryModelTests.newModel()
        let items = entry.newItemModel()
        entry.state.addItem(name: "牛乳", amount: 200)

        items.scroll(to: 3, in: entry)
        let missing = items.state.outcome
        items.scroll(to: 0, in: entry)
        let first = items.state.outcome
        items.scroll(to: 0, in: entry)

        #expect(missing.value == nil)
        #expect(first.value == 0)
        #expect(items.state.outcome != first)
    }
}
