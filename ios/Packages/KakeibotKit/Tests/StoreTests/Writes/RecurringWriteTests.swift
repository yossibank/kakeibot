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
    func generatesOnShiftedDate() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-04-30"))
        try await setup.shiftHoliday(to: .next)

        try await setup.database.generateRecurringEntries(
            through: today,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == [
            "2026-01-26",
            "2026-02-25",
            "2026-03-25",
            "2026-04-27"
        ])
    }

    @Test
    func keepsOneEntryAfterChangingShift() async throws {
        let setup = try await Setup()
        let saturday = try #require(LocalDate("2026-04-25"))
        let may = try #require(LocalDate("2026-05-31"))

        try await setup.database.generateRecurringEntries(
            through: saturday,
            at: setup.now
        )

        try await setup.shiftHoliday(to: .next)

        try await setup.database.generateRecurringEntries(
            through: may,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == [
            "2026-01-25",
            "2026-02-25",
            "2026-03-25",
            "2026-04-25",
            "2026-05-25"
        ])
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

        try await setup.database.generateRecurringEntries(
            through: paidOn,
            at: setup.now
        )

        let payment = try setup.database
            .snapshot()
            .entries
            .first { $0.recurringId == bill.id }

        #expect(payment?.amount == 42500)
        #expect(payment?.date == paidOn)
    }

    @Test
    func recordsOneEntryOnRequestedDate() async throws {
        let setup = try await Setup()
        let recurrings = try await setup.database.recurrings()
        let recurring = try #require(recurrings.first)
        let date = try #require(LocalDate("2026-03-25"))

        let first = try await setup.database.recordRecurring(
            recurring.id,
            on: date,
            at: setup.now
        )

        let second = try await setup.database.recordRecurring(
            recurring.id,
            on: date,
            at: setup.now
        )

        #expect(first?.recurringDate == date)
        #expect(second == nil)
        #expect(try setup.database.snapshot().entries.count == 1)
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

        let saved = try await setup.database.saveRecurring(
            draft,
            today: today,
            at: setup.now
        )

        let incomes = try setup.database
            .snapshot()
            .entries
            .filter { $0.recurringId == saved.id }

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

        let saved = try await setup.database.saveRecurring(
            draft,
            today: today,
            at: setup.now
        )

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

        let added = try await setup.database.saveRecurring(
            draft,
            today: start,
            at: setup.now
        )

        let before = try await setup.database.recurrings().map(\.id)
        try await setup.database.reorderRecurrings(
            before.reversed(),
            at: setup.now
        )
        let after = try await setup.database.recurrings().map(\.id)

        #expect(added.sortOrder == 1)
        #expect(before.last == added.id)
        #expect(after == before.reversed())
    }

    @Test
    func deletesRecurringButKeepsEntries() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-02-28"))

        try await setup.database.generateRecurringEntries(
            through: today,
            at: setup.now
        )

        let id = try #require(setup.database.snapshot().recurrings.first?.id)
        let deletion = try await setup.database.deleteRecurring(id)
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

    @Test
    func pausesWhileHiddenWithoutBackfill() async throws {
        let setup = try await Setup()
        let january = try #require(LocalDate("2026-01-31"))
        let february = try #require(LocalDate("2026-02-01"))
        let april = try #require(LocalDate("2026-04-30"))
        let may = try #require(LocalDate("2026-05-25"))
        try await setup.database.generateRecurringEntries(
            through: january,
            at: setup.now
        )

        let recurring = try #require(
            try setup.database.snapshot().recurrings.first
        )

        try await setup.database.setRecurringHidden(
            recurring.id,
            isHidden: true,
            today: february,
            at: setup.now
        )
        try await setup.database.generateRecurringEntries(
            through: april,
            at: setup.now
        )
        let shownWhileHidden = try await setup.database.recurrings()

        let allWhileHidden = try await setup.database.recurrings(
            includingHidden: true
        )

        try await setup.database.setRecurringHidden(
            recurring.id,
            isHidden: false,
            today: may,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(shownWhileHidden.isEmpty)
        #expect(allWhileHidden.count == 1)
        #expect(dates == ["2026-01-25", "2026-05-25"])
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

private extension RecurringWriteTests.Setup {
    func shiftHoliday(to shift: Recurring.HolidayShift) async throws {
        try await database.writer.write { db in
            for var recurring in try Recurring.fetchAll(db) {
                recurring.holidayShift = shift
                try recurring.update(db)
            }
        }
    }
}
