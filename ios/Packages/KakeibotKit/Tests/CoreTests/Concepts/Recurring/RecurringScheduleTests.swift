import Core
import Foundation
import Testing

struct RecurringScheduleTests {
    @Test(arguments: try datesCases)
    func findsDatesInRange(fixture: DatesCase) {
        var recurring = Self.recurring(
            frequency: fixture.frequency,
            month: fixture.month,
            day: fixture.day,
            startDate: fixture.startDate,
            endDate: fixture.endDate
        )

        recurring.holidayShift = fixture.holidayShift ?? .none

        let dates = recurring.dates(from: fixture.from, through: fixture.through)

        #expect(dates == fixture.dates)
    }

    @Test(arguments: try occurrenceCases)
    func createsOnlyUnrecordedOccurrences(fixture: OccurrenceCase) throws {
        let startDate = try #require(LocalDate("2026-01-01"))

        var recurring = Self.recurring(
            frequency: .monthly,
            month: nil,
            day: fixture.day,
            startDate: startDate,
            endDate: nil
        )

        recurring.holidayShift = fixture.holidayShift ?? .none

        let entries = fixture.recorded.map { recorded in
            Entry(
                type: .expense,
                amount: 1000,
                date: recorded,
                categoryId: EntryCategory.ID(),
                walletId: Wallet.ID(),
                recurringId: recurring.id,
                recurringDate: recorded,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt
            )
        }

        let created = recurring
            .occurrences(from: fixture.from, through: fixture.through)
            .filter { occurrence in
                !entries.contains {
                    recurring.isRecorded(by: $0, scheduled: occurrence.scheduled)
                }
            }
            .map(\.scheduled)

        #expect(created == fixture.created)
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

        let fresh = recurring.pendingOccurrences(through: today).map(\.date.description)
        recurring.generatedUntil = generated
        let pending = recurring.pendingOccurrences(through: today).map(\.date.description)

        #expect(fresh == ["2026-01-25", "2026-02-25", "2026-03-25", "2026-04-25"])
        #expect(pending == ["2026-03-25", "2026-04-25"])
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
        let range = from...through

        let expense = recurrings.total(of: .expense, in: range)
        let income = recurrings.total(of: .income, in: range)

        #expect(expense == 78000)
        #expect(income == 78000)
    }
}

extension RecurringScheduleTests {
    struct OccurrenceCase: Decodable, Sendable {
        let day: Int
        let holidayShift: HolidayShift?
        let recorded: [LocalDate]
        let from: LocalDate
        let through: LocalDate
        let created: [LocalDate]
    }

    struct DatesCase: Decodable, Sendable {
        let frequency: Recurring.Frequency
        let month: Int?
        let day: Int
        let holidayShift: HolidayShift?
        let startDate: LocalDate
        let endDate: LocalDate?
        let from: LocalDate
        let through: LocalDate
        let dates: [LocalDate]
    }
}

private extension RecurringScheduleTests {
    static var occurrenceCases: [OccurrenceCase] {
        get throws {
            try CoreFixture.cases("recurring/recurring-occurrence.json")
        }
    }

    static var datesCases: [DatesCase] {
        get throws {
            try CoreFixture.cases("recurring/recurring-dates.json")
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
