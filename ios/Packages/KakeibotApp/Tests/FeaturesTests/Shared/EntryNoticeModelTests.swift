import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryNoticeModelTests {
    @Test
    func undoesNewEntry() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel()
        model.press(.digit(5))
        model.press(.doubleZero)

        let change = try #require(await model.save())
        setup.notice.show(change)
        await setup.notice.undo()
        let entries = try setup.database.snapshot().entries

        #expect(change.message == "食費 ¥500 を記録しました")
        #expect(entries.isEmpty)
        #expect(setup.notice.notice == .undone)
        #expect(setup.notice.notice?.message == "取り消しました")
    }

    @Test
    func restoresFeeDeletedFromStaleList() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()

        var draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: setup.date,
            categoryId: nil,
            walletId: options.wallets[1].id,
            toWalletId: options.wallets[0].id
        )

        let transfer = try await setup.database.saveEntry(draft, at: Date())
        let stale = try await setup.database.entryList()
        draft.fee = 110
        try await setup.database.saveEntry(draft, editing: transfer.id, at: Date())

        await setup.notice.delete(transfer.id, in: stale)
        await setup.notice.undo()
        let fee = try await setup.database.fee(of: transfer.id)

        #expect(fee?.amount == 110)
    }

    @Test
    func undoesEdit() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry()
        let model = try await setup.entryModel(editing: saved.id)
        model.press(.delete)

        let change = try #require(await model.save())
        let edited = try setup.database.snapshot().entries
        setup.notice.show(change)
        await setup.notice.undo()
        let entries = try setup.database.snapshot().entries

        #expect(change.message == "食費 ¥98 を変えました")
        #expect(edited.map(\.amount) == [98])
        #expect(entries.map(\.id) == [saved.id])
        #expect(entries.map(\.amount) == [980])
    }

    @Test
    func undoesDelete() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry()
        let model = try await setup.entryModel(editing: saved.id)

        let change = try #require(await model.delete())
        let deleted = try setup.database.snapshot().entries
        setup.notice.show(change)
        await setup.notice.undo()
        let entries = try setup.database.snapshot().entries

        #expect(change.message == "食費 ¥980 を消しました")
        #expect(deleted.isEmpty)
        #expect(entries.map(\.id) == [saved.id])
        #expect(entries.map(\.amount) == [980])
    }

    @Test
    func deletesFromListAndUndoes() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry()
        let list = try await setup.database.entryList()

        await setup.notice.delete(saved.id, in: list)
        let message = setup.notice.notice?.message
        let deleted = try setup.database.snapshot().entries
        await setup.notice.undo()
        let restored = try setup.database.snapshot().entries

        #expect(message == "食費 ¥980 を消しました")
        #expect(deleted.isEmpty)
        #expect(restored.map(\.id) == [saved.id])
    }

    @Test
    func namesDeletedEntryByMemo() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry(memo: "ランチ\n同僚と")
        let list = try await setup.database.entryList()

        await setup.notice.delete(saved.id, in: list)
        let change = setup.notice.change

        #expect(change?.subject == "ランチ")
        #expect(change?.amountText == "¥980")
        #expect(change?.predicate == "を消しました")
        #expect(change?.message == "ランチ ¥980 を消しました")
    }

    @Test
    func namesDeletedEntryWithoutCategoryAsRecord() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry(memo: "  ")
        let change = EntryChange(kind: .deleted, entry: saved, label: "")

        #expect(change.subject == "記録")
        #expect(change.message == "記録 ¥980 を消しました")
    }

    @Test
    func keepsDeletionNoticeOnScreenTap() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry()
        let list = try await setup.database.entryList()

        await setup.notice.delete(saved.id, in: list)
        setup.notice.clearOnTap()
        let notice = setup.notice.notice

        #expect(notice?.seconds == 4)
        #expect(notice?.dismissesOnTap == false)
        #expect(setup.notice.change?.isDeletion == true)
    }

    @Test
    func namesTransferByWallets() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel(type: .transfer)
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.digit(0))

        let change = try #require(await model.save())

        #expect(change.message == "財布 → 銀行 ¥3,000 を振り替えました")
    }

    @Test
    func clearsNotice() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel()
        model.press(.digit(5))

        let change = try #require(await model.save())
        setup.notice.show(change)
        let shown = setup.notice.notice
        setup.notice.clear()

        #expect(shown == .changed(change))
        #expect(setup.notice.notice == nil)
    }

    @Test
    func changesCategoryOfSelectedEntriesAndUndoes() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry()
        let options = try await setup.database.entryOptions()
        let other = options.expenseCategories[1]

        await setup.notice.changeEntries([saved.id], to: .category(other.id))
        let message = setup.notice.notice?.message
        let changed = try setup.database.snapshot().entries
        await setup.notice.undo()
        let restored = try setup.database.snapshot().entries

        #expect(message == "1 件のカテゴリを変えました")
        #expect(changed.map(\.categoryId) == [other.id])
        #expect(restored.map(\.categoryId) == [saved.categoryId])
    }

    @Test
    func deletesSelectedEntriesAndUndoes() async throws {
        let setup = try await Setup()
        let first = try await setup.saveEntry()
        let second = try await setup.saveEntry()

        await setup.notice.deleteEntries([first.id, second.id])
        let message = setup.notice.notice?.message
        let deleted = try setup.database.snapshot().entries
        await setup.notice.undo()
        let restored = try setup.database.snapshot().entries

        #expect(message == "2 件を削除しました")
        #expect(deleted.isEmpty)
        #expect(Set(restored.map(\.id)) == [first.id, second.id])
    }

    @Test
    func keepsBatchNoticeLongerAndIgnoresScreenTaps() async throws {
        let setup = try await Setup()
        let first = try await setup.saveEntry()
        let second = try await setup.saveEntry()

        await setup.notice.deleteEntries([first.id, second.id])
        setup.notice.clearOnTap()
        let batch = setup.notice.notice

        let change = EntryChange(kind: .recorded, entry: first, label: "食費")
        setup.notice.show(change)
        setup.notice.clearOnTap()

        #expect(batch?.seconds == 8)
        #expect(batch != nil)
        #expect(setup.notice.notice == nil)
        #expect(EntryNoticeModel.Notice.failed("x").seconds == 4)
        #expect(EntryNoticeModel.Notice.undone.seconds == 2)
    }

    @Test
    func restoresNoSpendMarkWhenUndoingNewEntry() async throws {
        let setup = try await Setup()
        try await setup.database.markNoSpendDay(setup.date, at: Date())
        let model = try await setup.entryModel()
        model.press(.digit(5))

        let change = try #require(await model.save())
        let cleared = try setup.database.snapshot().noSpendDays
        setup.notice.show(change)
        await setup.notice.undo()
        let restored = try setup.database.snapshot().noSpendDays

        #expect(cleared.isEmpty)
        #expect(restored.map(\.date) == [setup.date])
    }

    @Test
    func doesNotMakeNoSpendMarkWhenUndoingEntryOnUnmarkedDay() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel()
        model.press(.digit(5))

        let change = try #require(await model.save())
        setup.notice.show(change)
        await setup.notice.undo()
        let restored = try setup.database.snapshot().noSpendDays

        #expect(restored.isEmpty)
    }
}

extension EntryNoticeModelTests {
    @MainActor
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
        let notice: EntryNoticeModel
    }
}

extension EntryNoticeModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let date = try #require(LocalDate("2026-10-12"))
        let notice = EntryNoticeModel(database: database)

        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database, date: date, notice: notice)
    }

    func entryModel(
        editing id: Entry.ID? = nil,
        type: Entry.Kind = .expense
    ) async throws -> EntryModel {
        let model = EntryModel(database: database, editing: id, date: date, type: type)
        await model.load()
        return model
    }

    func saveEntry(memo: String = "") async throws -> Entry {
        let options = try await database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: memo
        )

        return try await database.saveEntry(draft, at: Date())
    }
}
