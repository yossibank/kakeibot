import Core
import Foundation
import Store
import Testing

struct MonthOverviewTests {
    @Test
    func sumsMonthAndBudget() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let today = try #require(LocalDate("2026-10-23"))
        let month = try #require(YearMonth("2026-10"))
        let tomorrowDate = today.adding(days: 1)
        let nextMonthDate = today.adding(days: 9)

        for (text, amount) in [
            ("2026-09-30", 999),
            ("2026-10-01", 3000),
            ("2026-10-23", 1200)
        ] {
            let date = try #require(LocalDate(text))

            let draft = EntryDraft(
                type: .expense,
                amount: amount,
                date: date,
                categoryId: options.expenseCategories[0].id,
                walletId: options.wallets[0].id
            )

            try await database.saveEntry(draft, at: now)
        }

        try await database.setBudget(50000, for: nil, from: month)
        let overview = try await database.monthOverview(on: today)
        let tomorrow = overview.moved(to: tomorrowDate)
        let nextMonth = overview.moved(to: nextMonthDate)

        #expect(overview.monthExpense == 4200)
        #expect(overview.todayExpense == 1200)
        #expect(overview.budgetUsage?.remaining == 45800)
        #expect(tomorrow.todayExpense == 0)
        #expect(tomorrow.yesterdayExpense == 1200)
        #expect(nextMonth.monthExpense == 0)
    }

    @Test
    func treatsUngeneratedRecurringOfTodayAsUpcoming() throws {
        let today = try #require(LocalDate("2026-10-23"))
        let yesterday = today.adding(days: -1)
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        func overview(generatedUntil: LocalDate?) throws -> MonthOverview {
            let startDate = try #require(LocalDate("2026-01-01"))

            let recurring = Recurring(
                type: .expense,
                amount: 5000,
                categoryId: EntryCategory.ID(),
                walletId: Wallet.ID(),
                frequency: .monthly,
                day: 23,
                startDate: startDate,
                generatedUntil: generatedUntil,
                createdAt: now,
                updatedAt: now
            )

            return MonthOverview(
                list: nil,
                budgets: [],
                recurrings: [recurring],
                monthStartDay: .first,
                today: today
            )
        }

        let ungenerated = try overview(generatedUntil: yesterday)
        let neverGenerated = try overview(generatedUntil: nil)
        let deleted = try overview(generatedUntil: today)

        #expect(ungenerated.periodRecurrings.map(\.status) == [.upcoming])
        #expect(ungenerated.nextRecurringExpense?.date == today)
        #expect(neverGenerated.periodRecurrings.map(\.status) == [.upcoming])
        #expect(deleted.periodRecurrings.map(\.status) == [.missing])
        #expect(deleted.nextRecurringExpense == nil)
    }
}
