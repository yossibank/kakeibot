import Core
import Foundation
import GRDB
import Store
import Testing

struct EntryItemWriteTests {
    @Test
    func savesItemsInOrderWithTrimmedNames() async throws {
        let setup = try await EntryWriteTests.Setup()
        var draft = setup.draft
        draft.items = Self.items

        let entry = try await setup.database.saveEntry(draft, at: setup.now)
        let items = try await setup.database.entryItems(of: entry.id)

        #expect(items.map(\.name) == ["牛乳", "パン", "値引"])
        #expect(items.map(\.sortOrder) == [0, 1, 2])
        #expect(items.map(\.amount) == [396, 220, -30])
        #expect(items.map(\.quantity) == [2, 1, 1])
    }

    @Test
    func keepsIdsAndDropsExtraItemsWhenEdited() async throws {
        let setup = try await EntryWriteTests.Setup()
        let later = setup.now.addingTimeInterval(60)
        var draft = setup.draft
        draft.items = Self.items
        let entry = try await setup.database.saveEntry(draft, at: setup.now)
        let before = try await setup.database.entryItems(of: entry.id)

        draft.items = [EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396)]
        try await setup.database.saveEntry(draft, editing: entry.id, at: later)
        let after = try await setup.database.entryItems(of: entry.id)

        #expect(after.map(\.id) == [before[0].id])
        #expect(after.map(\.updatedAt) == [setup.now])
    }

    @Test
    func keepsItemsWhenDraftHasNone() async throws {
        let setup = try await EntryWriteTests.Setup()
        var draft = setup.draft
        draft.items = Self.items
        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        draft.items = nil
        draft.amount = 1200
        try await setup.database.saveEntry(draft, editing: entry.id, at: setup.now)

        #expect(try await setup.database.entryItems(of: entry.id).count == 3)
    }

    @Test
    func dropsItemsWhenEntryBecomesTransfer() async throws {
        let setup = try await EntryWriteTests.Setup()
        let options = try await setup.database.entryOptions()
        var draft = setup.draft
        draft.items = Self.items
        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        draft.type = .transfer
        draft.categoryId = nil
        draft.items = nil
        draft.toWalletId = options.wallets[1].id
        try await setup.database.saveEntry(draft, editing: entry.id, at: setup.now)

        #expect(try await setup.database.entryItems(of: entry.id).isEmpty)
    }

    @Test
    func deletesItemsWithEntry() async throws {
        let setup = try await EntryWriteTests.Setup()
        var draft = setup.draft
        draft.items = Self.items
        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        try await setup.database.deleteEntry(entry.id)

        #expect(try setup.database.snapshot().entryItems.isEmpty)
    }

    @Test
    func touchesItemsWhenWalletChanges() async throws {
        let setup = try await EntryWriteTests.Setup()
        let options = try await setup.database.entryOptions()
        let later = setup.now.addingTimeInterval(60)
        var draft = setup.draft
        draft.items = Self.items
        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        let change = EntryBatchChange.wallet(options.wallets[1].id)
        _ = try await setup.database.changeEntries([entry.id], to: change, at: later)
        let items = try await setup.database.entryItems(of: entry.id)

        #expect(items.map(\.updatedAt) == [later, later, later])
    }

    @Test
    func remembersItemNamesPerStore() async throws {
        let setup = try await EntryWriteTests.Setup()
        let database = setup.database

        try await database.rememberItemName("牛乳", for: "ｷﾞｭｳﾆｭｳ", at: "青葉", on: setup.now)
        try await database.rememberItemName("低脂肪乳", for: "ｷﾞｭｳﾆｭｳ", at: "青葉", on: setup.now)
        try await database.rememberItemName("牛乳", for: "ｷﾞｭｳﾆｭｳ", at: "若葉", on: setup.now)
        let aoba = try await database.itemNames(at: "青葉")
        let count = try database.snapshot().itemNames.count

        #expect(aoba == ["ｷﾞｭｳﾆｭｳ": "低脂肪乳"])
        #expect(count == 2)
    }
}

private extension EntryItemWriteTests {
    static let items = [
        EntryItem.Draft(name: " 牛乳 ", quantity: 2, amount: 396),
        EntryItem.Draft(name: "パン", amount: 220),
        EntryItem.Draft(name: "値引", amount: -30)
    ]
}
