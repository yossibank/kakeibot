import Core
import Foundation
import Store
import Testing

extension RecurringWriteTests {
    @Test
    func savesAndGeneratesUpToToday() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-02-01"))
        let today = try #require(LocalDate("2026-03-31"))

        let draft = RecurringDraft(
            type: .income,
            amount: 280_000,
            categoryId: options.incomeCategories[0].id,
            walletId: options.wallets[1].id,
            memo: "給料",
            frequency: .monthly,
            month: 1,
            day: 25,
            startDate: start
        )

        let saved = try await setup.database.saveRecurring(draft, today: today, at: setup.now)
        let incomes = try setup.database.snapshot().entries.filter { $0.recurringId == saved.id }

        #expect(incomes.count == 2)
        #expect(saved.generatedUntil == today)
    }

    @Test
    func generatesTransferBetweenWallets() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let today = try #require(LocalDate("2026-01-26"))
        try await setup.database.markNoSpendDay(today, at: setup.now)

        let draft = RecurringDraft(
            type: .transfer,
            amount: 30000,
            categoryId: nil,
            walletId: options.wallets[1].id,
            toWalletId: options.wallets[0].id,
            frequency: .monthly,
            month: 1,
            day: 26,
            startDate: today
        )

        let saved = try await setup.database.saveRecurring(draft, today: today, at: setup.now)
        let snapshot = try setup.database.snapshot()
        let transfers = snapshot.entries.filter { $0.recurringId == saved.id }

        #expect(transfers.map(\.type) == [.transfer])
        #expect(transfers.first?.toWalletId == options.wallets[0].id)
        #expect(transfers.first?.categoryId == nil)
        #expect(snapshot.noSpendDays.map(\.date) == [today])
    }

    @Test
    func addsAtEndAndReorders() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-02-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 4800,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            frequency: .monthly,
            month: 1,
            day: 1,
            startDate: start
        )

        let added = try await setup.database.saveRecurring(draft, today: start, at: setup.now)
        let before = try await setup.database.recurrings().map(\.id)
        try await setup.database.reorderRecurrings(before.reversed(), at: setup.now)
        let after = try await setup.database.recurrings().map(\.id)

        #expect(added.sortOrder == 1)
        #expect(before.last == added.id)
        #expect(after == before.reversed())
    }

    @Test
    func deletesRecurringButKeepsEntries() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-02-28"))
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let id = try #require(setup.database.snapshot().recurrings.first?.id)

        let deletion = try await setup.database.deleteRecurring(id, at: setup.now)
        let snapshot = try setup.database.snapshot()
        try await setup.database.restore(deletion)
        let restored = try setup.database.snapshot()

        #expect(snapshot.recurrings.isEmpty)
        #expect(snapshot.entries.count == 2)
        #expect(snapshot.entries.allSatisfy { $0.recurringId == nil })
        #expect(restored.recurrings.map(\.id) == [id])
        #expect(restored.entries.allSatisfy { $0.recurringId == id })
    }

    @Test
    func touchesUpdatedAtOfLinkedEntriesOnDelete() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-02-28"))
        let later = setup.now.addingTimeInterval(60)
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let id = try #require(setup.database.snapshot().recurrings.first?.id)

        try await setup.database.deleteRecurring(id, at: later)
        let entries = try setup.database.snapshot().entries

        #expect(!entries.isEmpty)
        #expect(entries.allSatisfy { $0.updatedAt == later })
    }

    @Test
    func restoresRemainingEntriesWhenOneIsGone() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-02-28"))
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let id = try #require(setup.database.snapshot().recurrings.first?.id)
        let ids = try setup.database.snapshot().entries.map(\.id)
        let gone = try #require(ids.first)
        let kept = try #require(ids.last)
        let deletion = try await setup.database.deleteRecurring(id, at: setup.now)

        try await setup.database.deleteEntry(gone)
        try await setup.database.restore(deletion)
        let restored = try setup.database.snapshot()

        #expect(restored.recurrings.map(\.id) == [id])
        #expect(restored.entries.map(\.id) == [kept])
        #expect(restored.entries.allSatisfy { $0.recurringId == id })
    }

    @Test
    func rejectsUnknownRecurring() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-02-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 4800,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            frequency: .monthly,
            month: 1,
            day: 10,
            startDate: start
        )

        await #expect(throws: AppDatabase.RecurringWriteError.self) {
            try await setup.database.saveRecurring(
                draft,
                editing: Recurring.ID(),
                today: start,
                at: setup.now
            )
        }
    }
}
