import Core
import Foundation
import Testing

struct RecurringScheduleTests {
    @Test(arguments: try datesCases)
    func findsDatesInRange(fixture: DatesCase) {
        let recurring = Self.recurring(
            frequency: fixture.frequency,
            month: fixture.month,
            day: fixture.day,
            startDate: fixture.startDate,
            endDate: fixture.endDate
        )

        let dates = recurring.dates(
            from: fixture.from,
            through: fixture.through
        )

        #expect(dates == fixture.dates)
    }

    @Test
    func continuesAfterGeneratedDate() throws {
        let start = try #require(LocalDate("2026-01-01"))
        let generated = try #require(LocalDate("2026-02-25"))
        let today = try #require(LocalDate("2026-04-30"))

        var recurring = Self.recurring(
            frequency: .monthly,
            month: nil,
            day: 25,
            startDate: start,
            endDate: nil
        )

        let fresh = recurring.pendingDates(through: today)
        recurring.generatedUntil = generated
        let pending = recurring.pendingDates(through: today)

        #expect(fresh.map(\.description) == [
            "2026-01-25",
            "2026-02-25",
            "2026-03-25",
            "2026-04-25"
        ])
        #expect(pending.map(\.description) == ["2026-03-25", "2026-04-25"])
    }

    @Test
    func findsNextDate() throws {
        let start = try #require(LocalDate("2026-01-01"))
        let end = try #require(LocalDate("2026-06-30"))
        let payday = try #require(LocalDate("2026-03-25"))
        let after = try #require(LocalDate("2026-03-26"))
        let late = try #require(LocalDate("2026-07-01"))

        let recurring = Self.recurring(
            frequency: .monthly,
            month: nil,
            day: 25,
            startDate: start,
            endDate: end
        )

        let same = recurring.nextDate(onOrAfter: payday)
        let next = recurring.nextDate(onOrAfter: after)
        let none = recurring.nextDate(onOrAfter: late)

        #expect(same == payday)
        #expect(next?.description == "2026-04-25")
        #expect(none == nil)
    }

    @Test
    func totalsTypeInRange() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let start = try #require(LocalDate("2026-01-01"))
        let from = try #require(LocalDate("2026-10-01"))
        let through = try #require(LocalDate("2026-10-31"))

        let rent = Recurring(
            type: .expense,
            amount: 78000,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID(),
            frequency: .monthly,
            day: 27,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )

        var insurance = rent
        insurance.amount = 12000
        insurance.frequency = .yearly
        insurance.month = 4

        var salary = rent
        salary.type = .income

        let recurrings = [rent, insurance, salary]

        #expect(recurrings.total(of: .expense, in: from...through) == 78000)
        #expect(recurrings.total(of: .income, in: from...through) == 78000)
    }
}

extension RecurringScheduleTests {
    struct DatesCase: Decodable, Sendable {
        let frequency: Recurring.Frequency
        let month: Int?
        let day: Int
        let startDate: LocalDate
        let endDate: LocalDate?
        let from: LocalDate
        let through: LocalDate
        let dates: [LocalDate]
    }
}

private extension RecurringScheduleTests {
    static var datesCases: [DatesCase] {
        get throws {
            try Fixture.load("recurring/recurring-dates.json")
        }
    }

    static func recurring(
        frequency: Recurring.Frequency,
        month: Int?,
        day: Int,
        startDate: LocalDate,
        endDate: LocalDate?
    ) -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return Recurring(
            type: .expense,
            amount: 78000,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID(),
            frequency: frequency,
            month: month,
            day: day,
            startDate: startDate,
            endDate: endDate,
            createdAt: now,
            updatedAt: now
        )
    }
}
