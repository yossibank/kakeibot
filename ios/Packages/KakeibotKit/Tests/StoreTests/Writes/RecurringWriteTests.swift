import Core
import Foundation
import Store
import Testing

struct RecurringWriteTests {
    @Test
    func generatesMissingEntriesOnce() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-04-30"))

        try await setup.database.generateRecurringEntries(
            through: today,
            at: setup.now
        )

        try await setup.database.generateRecurringEntries(
            through: today,
            at: setup.now
        )

        let snapshot = try setup.database.snapshot()
        let dates = snapshot.entries.compactMap(\.recurringDate)
        let generated = snapshot.recurrings.first?.generatedUntil

        #expect(dates.sorted().map(\.description) == [
            "2026-01-25",
            "2026-02-25",
            "2026-03-25",
            "2026-04-25"
        ])
        #expect(snapshot.entries.allSatisfy { $0.amount == 78000 })
        #expect(generated == today)
    }

    @Test
    func continuesFromGeneratedDate() async throws {
        let setup = try await Setup()
        let march = try #require(LocalDate("2026-03-01"))
        let may = try #require(LocalDate("2026-05-31"))

        try await setup.database.generateRecurringEntries(
            through: march,
            at: setup.now
        )

        let first = try setup.database.snapshot().entries.count

        try await setup.database.generateRecurringEntries(
            through: may,
            at: setup.now
        )

        let second = try setup.database.snapshot().entries.count

        #expect(first == 2)
        #expect(second == 5)
    }

    @Test
    func clearsNoSpendDayOfExpense() async throws {
        let setup = try await Setup()
        let payday = try #require(LocalDate("2026-01-25"))

        try await setup.database.markNoSpendDay(payday, at: setup.now)

        try await setup.database.generateRecurringEntries(
            through: payday,
            at: setup.now
        )

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.noSpendDays.isEmpty)
        #expect(snapshot.entries.count == 1)
    }
}

extension RecurringWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
    }
}

extension RecurringWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let start = try #require(LocalDate("2026-01-01"))

        let recurring = Recurring(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            frequency: .monthly,
            day: 25,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try recurring.insert(db)
        }

        self.init(database: database, now: now)
    }
}
