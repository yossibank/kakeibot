import Core
import Foundation
import Store
import Testing

struct EntryWriteTests {
    @Test
    func savesNewEntry() async throws {
        let setup = try await Setup()

        let saved = try await setup.database.saveEntry(
            setup.draft,
            at: setup.now
        )

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries == [saved])
    }

    @Test
    func updatesExistingEntry() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        var edited = setup.draft
        edited.amount = 1500

        let saved = try await setup.database.saveEntry(
            setup.draft,
            at: setup.now
        )

        let updated = try await setup.database.saveEntry(
            edited,
            editing: saved.id,
            at: later
        )

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries == [updated])
        #expect(updated.amount == 1500)
        #expect(updated.createdAt == setup.now)
        #expect(updated.updatedAt == later)
    }

    @Test
    func rejectsUnknownEntry() async throws {
        let setup = try await Setup()

        await #expect(throws: AppDatabase.WriteError.entryNotFound) {
            try await setup.database.saveEntry(
                setup.draft,
                editing: Entry.ID(),
                at: setup.now
            )
        }
    }

    @Test
    func rejectsInvalidDraft() async throws {
        let setup = try await Setup()
        var draft = setup.draft
        draft.amount = 0

        await #expect(throws: EntryDraft.Problem.amountNotPositive) {
            try await setup.database.saveEntry(draft, at: setup.now)
        }
    }

    @Test(arguments: [Entry.Kind.expense, .income])
    func clearsNoSpendDayOnlyForExpense(type: Entry.Kind) async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let categories = type == .expense
            ? options.expenseCategories
            : options.incomeCategories
        var draft = setup.draft
        draft.type = type
        draft.categoryId = categories[0].id
        let noSpendDay = NoSpendDay(date: draft.date, createdAt: setup.now)

        try await setup.database.writer.write { db in
            try noSpendDay.insert(db)
        }

        try await setup.database.saveEntry(draft, at: setup.now)
        let snapshot = try setup.database.snapshot()

        #expect(snapshot.noSpendDays.isEmpty == (type == .expense))
    }

    @Test
    func savesEntriesTogetherOrNotAtAll() async throws {
        let setup = try await Setup()
        var invalid = setup.draft
        invalid.amount = 0

        try await setup.database.saveEntries(
            [setup.draft, setup.draft],
            at: setup.now
        )

        let saved = try setup.database.snapshot().entries.count

        await #expect(throws: (any Error).self) {
            try await setup.database.saveEntries(
                [setup.draft, invalid],
                at: setup.now
            )
        }

        let after = try setup.database.snapshot().entries.count

        #expect(saved == 2)
        #expect(after == 2)
    }

    @Test
    func deletesEntry() async throws {
        let setup = try await Setup()

        let saved = try await setup.database.saveEntry(
            setup.draft,
            at: setup.now
        )

        try await setup.database.deleteEntry(saved.id)
        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries.isEmpty)
    }

    @Test
    func restoresDeletedAndEditedEntry() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        var edited = setup.draft
        edited.amount = 1500

        let saved = try await setup.database.saveEntry(
            setup.draft,
            at: setup.now
        )

        try await setup.database.deleteEntry(saved.id)
        try await setup.database.restoreEntry(saved)
        let restored = try setup.database.snapshot().entries

        try await setup.database.saveEntry(
            edited,
            editing: saved.id,
            at: later
        )
        try await setup.database.restoreEntry(saved)
        let reverted = try setup.database.snapshot().entries

        #expect(restored == [saved])
        #expect(reverted == [saved])
    }

    @Test
    func changesCategoryOnlyForMatchingType() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let category = options.expenseCategories[1]
        let later = setup.now.addingTimeInterval(60)
        var income = setup.draft
        income.type = .income
        income.categoryId = options.incomeCategories[0].id

        let spent = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let earned = try await setup.database.saveEntry(income, at: setup.now)

        let previous = try await setup.database.changeEntries(
            [spent.id, earned.id],
            to: .category(category.id),
            at: later
        )

        let changed = try await setup.database.entry(spent.id)
        let kept = try await setup.database.entry(earned.id)

        #expect(previous == [spent])
        #expect(changed?.categoryId == category.id)
        #expect(changed?.updatedAt == later)
        #expect(kept == earned)
    }

    @Test
    func changesWalletOfEntries() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let wallet = options.wallets[1]

        let saved = try await setup.database.saveEntry(setup.draft, at: setup.now)

        let previous = try await setup.database.changeEntries(
            [saved.id],
            to: .wallet(wallet.id),
            at: setup.now
        )

        let changed = try await setup.database.entry(saved.id)

        #expect(previous == [saved])
        #expect(changed?.walletId == wallet.id)
    }

    @Test
    func deletesAndRestoresEntries() async throws {
        let setup = try await Setup()

        let first = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let second = try await setup.database.saveEntry(setup.draft, at: setup.now)

        let deleted = try await setup.database.deleteEntries([first.id, second.id])
        let emptied = try setup.database.snapshot().entries
        try await setup.database.restoreEntries(deleted)
        let restored = try setup.database.snapshot().entries

        #expect(Set(deleted) == [first, second])
        #expect(emptied.isEmpty)
        #expect(Set(restored) == [first, second])
    }
}

extension EntryWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: EntryDraft
    }
}

extension EntryWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: "ランチ"
        )

        self.init(
            database: database,
            now: now,
            draft: draft
        )
    }
}
