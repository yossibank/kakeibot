import Core
import Foundation
import Store
import Testing

struct RecurringWriteTests {
    @Test
    func generatesMissingEntriesOnce() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-04-30"))

        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)

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
    func skipsWritingWhenNothingChanged() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-04-30"))
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)

        let before = try await setup.database.writer.read { $0.totalChangesCount }
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let after = try await setup.database.writer.read { $0.totalChangesCount }

        #expect(after == before)
    }

    @Test
    func paysCardUsageUntilClosingDay() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = options.wallets[0].id
        let card = options.wallets[1].id
        let category = options.expenseCategories[0].id
        let paidOn = try #require(LocalDate("2026-11-10"))

        let usage = [
            ("2026-09-15", 7000),
            ("2026-09-16", 30000),
            ("2026-10-15", 12000),
            ("2026-10-16", 9000)
        ]

        let entries = try usage.map { date, amount in
            try Entry(
                type: .expense,
                amount: amount,
                date: #require(LocalDate(date)),
                categoryId: category,
                walletId: card,
                createdAt: setup.now,
                updatedAt: setup.now
            )
        }

        let late = try Entry(
            type: .expense,
            amount: 500,
            date: #require(LocalDate("2026-08-20")),
            categoryId: category,
            walletId: card,
            billMonth: paidOn.yearMonth,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        let bill = try Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank,
            toWalletId: card,
            frequency: .monthly,
            day: 10,
            closingDay: 15,
            startDate: #require(LocalDate("2026-11-01")),
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            for entry in entries + [late] {
                try entry.insert(db)
            }

            try bill.insert(db)
        }

        try await setup.database.generateRecurringEntries(through: paidOn, at: setup.now)
        let payment = try setup.database.snapshot().entries.first { $0.recurringId == bill.id }

        #expect(payment?.amount == 42500)
        #expect(payment?.date == paidOn)
    }

    @Test
    func recordsOneEntryOnRequestedDate() async throws {
        let setup = try await Setup()
        let recurrings = try await setup.database.recurrings()
        let recurring = try #require(recurrings.first)
        let date = try #require(LocalDate("2026-03-25"))

        let first = try await setup.database.recordRecurring(recurring.id, on: date, at: setup.now)
        let second = try await setup.database.recordRecurring(recurring.id, on: date, at: setup.now)

        #expect(first?.recurringDate == date)
        #expect(second == nil)
        #expect(try setup.database.snapshot().entries.count == 1)
    }

    @Test
    func continuesFromGeneratedDate() async throws {
        let setup = try await Setup()
        let march = try #require(LocalDate("2026-03-01"))
        let may = try #require(LocalDate("2026-05-31"))

        try await setup.database.generateRecurringEntries(through: march, at: setup.now)
        let first = try setup.database.snapshot().entries.count
        try await setup.database.generateRecurringEntries(through: may, at: setup.now)
        let second = try setup.database.snapshot().entries.count

        #expect(first == 2)
        #expect(second == 5)
    }

    @Test
    func clearsNoSpendDayOfExpense() async throws {
        let setup = try await Setup()
        let payday = try #require(LocalDate("2026-01-25"))
        try await setup.database.markNoSpendDay(payday, at: setup.now)

        try await setup.database.generateRecurringEntries(through: payday, at: setup.now)
        let snapshot = try setup.database.snapshot()

        #expect(snapshot.noSpendDays.isEmpty)
        #expect(snapshot.entries.count == 1)
    }

    @Test
    func recordsShiftedBillMonthOfCardRecurring() async throws {
        let setup = try await Setup()
        let bill = try await setup.database.insertCardBill(at: setup.now)
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-01-01"))
        let today = try #require(LocalDate("2026-02-28"))

        let subscription = try Recurring(
            type: .expense,
            amount: 1200,
            categoryId: options.expenseCategories[0].id,
            walletId: #require(bill.toWalletId),
            frequency: .monthly,
            day: 20,
            billShift: 1,
            startDate: start,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            try subscription.insert(db)
        }

        try await setup.database.generateRecurringEntries(through: today, at: setup.now)

        let all = try setup.database.snapshot().entries
        let entries = all.filter { $0.recurringId == subscription.id }

        #expect(!entries.isEmpty)
        #expect(entries.allSatisfy { $0.billMonth != nil })
        #expect(entries.allSatisfy { $0.billMonth == bill.billMonth(for: $0.date, shift: 1) })
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
        let start = try #require(LocalDate("2026-01-01"))

        try database.insertDefaultsIfEmpty(at: now)

        let options = try await database.entryOptions()

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
