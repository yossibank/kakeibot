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

        #expect(change.message == "食費 ¥500 を記録した")
        #expect(entries.isEmpty)
        #expect(setup.notice.change == nil)
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

        #expect(change.message == "食費 ¥98 を直した")
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

        #expect(change.message == "食費 ¥980 を消した")
        #expect(deleted.isEmpty)
        #expect(entries.map(\.id) == [saved.id])
        #expect(entries.map(\.amount) == [980])
    }

    @Test
    func namesTransferByWallets() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel(type: .transfer)
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.digit(0))

        let change = try #require(await model.save())

        #expect(change.message == "財布 → 銀行 ¥3,000 を振り替えた")
    }

    @Test
    func clearsNotice() async throws {
        let setup = try await Setup()
        let model = try await setup.entryModel()
        model.press(.digit(5))

        let change = try #require(await model.save())
        setup.notice.show(change)
        let shown = setup.notice.isShown
        setup.notice.clear()

        #expect(shown)
        #expect(!setup.notice.isShown)
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
        try database.insertDefaultsIfEmpty(at: Date())
        let date = try #require(LocalDate("2026-10-12"))

        self.init(
            database: database,
            date: date,
            notice: EntryNoticeModel(database: database)
        )
    }

    func entryModel(
        editing id: Entry.ID? = nil,
        type: Entry.Kind = .expense
    ) async throws -> EntryModel {
        let model = EntryModel(
            database: database,
            editing: id,
            date: date,
            type: type
        )

        await model.load()
        return model
    }

    func saveEntry() async throws -> Entry {
        let options = try await database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        return try await database.saveEntry(draft, at: Date())
    }
}
