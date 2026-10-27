import Core
import Foundation
import Testing

struct RecurringCardBillTests {
    @Test(arguments: try periodCases)
    func findsBillingPeriod(fixture: PeriodCase) throws {
        let bill = try Self.bill(
            closingDay: fixture.closingDay,
            day: fixture.day ?? 10,
            holidayShift: fixture.holidayShift ?? .none
        )

        let period = bill.billingPeriod(paidOn: fixture.paidOn)
        #expect(period == fixture.from...fixture.through)
    }

    @Test(arguments: ["2027-01", "2027-12"])
    func continuesPeriodsAcrossShortMonths(
        start: String
    ) throws {
        let first = try #require(YearMonth(start))

        for closingDay in 28...31 {
            for day in 28...31 {
                let bill = try Self.bill(closingDay: closingDay, day: day)

                let periods = try (0..<14).map { offset in
                    let month = first.adding(months: offset)

                    let paidOn = try #require(
                        stride(from: day, through: 1, by: -1)
                            .lazy
                            .compactMap { LocalDate(yearMonth: month, day: $0) }
                            .first
                    )

                    return try #require(bill.billingPeriod(paidOn: paidOn))
                }

                #expect(periods.count == 14)

                for (previous, next) in zip(periods, periods.dropFirst()) {
                    #expect(
                        previous.upperBound.adding(days: 1) == next.lowerBound,
                        Comment(
                            rawValue: "closing \(closingDay) day \(day) at \(next.lowerBound)"
                        )
                    )
                }
            }
        }
    }

    @Test
    func sumsCardUsageOfPeriod() throws {
        let bill = try Self.bill(closingDay: 15)
        let card = try #require(bill.toWalletId)
        let paidOn = try #require(LocalDate("2026-11-10"))

        let entries = try [
            Self.entry(.expense, 30000, on: "2026-09-16", wallet: card),
            Self.entry(.expense, 12000, on: "2026-10-15", wallet: card),
            Self.entry(.income, 2000, on: "2026-10-01", wallet: card),
            Self.entry(.transfer, 45000, on: "2026-10-10", wallet: card),
            Self.entry(.expense, 9000, on: "2026-10-16", wallet: card),
            Self.entry(.expense, 5000, on: "2026-10-01", wallet: Wallet.ID())
        ]

        #expect(bill.amount(paidOn: paidOn, entries: entries) == 40000)
    }

    @Test
    func countsMovedUsageInChosenMonth() throws {
        let bill = try Self.bill(closingDay: 31)
        let card = try #require(bill.toWalletId)
        let october = try #require(LocalDate("2026-10-10"))
        let november = try #require(LocalDate("2026-11-10"))

        var late = try Self.entry(
            .expense,
            3000,
            on: "2026-08-31",
            wallet: card
        )

        late.billMonth = november.yearMonth

        var moved = try Self.entry(
            .expense,
            500,
            on: "2026-09-20",
            wallet: card
        )

        moved.billMonth = november.yearMonth

        let entries = try [
            late,
            moved,
            Self.entry(.expense, 9000, on: "2026-09-05", wallet: card),
            Self.entry(.expense, 7000, on: "2026-10-05", wallet: card)
        ]

        #expect(bill.amount(paidOn: october, entries: entries) == 9000)
        #expect(bill.amount(paidOn: november, entries: entries) == 10500)
    }

    @Test
    func countsMovedUsageOncePerOccurrence() throws {
        let bill = try Self.bill(
            closingDay: 31,
            day: 27,
            holidayShift: .next
        )

        let card = try #require(bill.toWalletId)
        let february = try #require(LocalDate("2027-03-01"))
        let march = try #require(LocalDate("2027-03-29"))

        var moved = try Self.entry(
            .expense,
            500,
            on: "2027-01-20",
            wallet: card
        )

        moved.billMonth = YearMonth("2027-02")

        let entries = try [
            moved,
            Self.entry(.expense, 9000, on: "2027-01-05", wallet: card),
            Self.entry(.expense, 7000, on: "2027-02-05", wallet: card)
        ]

        #expect(bill.amount(paidOn: february, entries: entries) == 9500)
        #expect(bill.amount(paidOn: march, entries: entries) == 7000)
    }

    @Test
    func listsBillDatesFromUsualOne() throws {
        let bill = try Self.bill(closingDay: 31)
        let used = try #require(LocalDate("2026-08-31"))

        let dates = bill.billDates(for: used, count: 3)

        #expect(dates.map(\.description) == [
            "2026-09-10",
            "2026-10-10",
            "2026-11-10"
        ])
    }

    @Test
    func keepsFixedAmountWithoutClosingDay() throws {
        var bill = try Self.bill(closingDay: 15)
        bill.closingDay = nil
        let paidOn = try #require(LocalDate("2026-11-10"))

        #expect(bill.amount(paidOn: paidOn, entries: []) == 45000)
    }
}

extension RecurringCardBillTests {
    struct PeriodCase: Decodable, Sendable {
        let closingDay: Int
        let day: Int?
        let holidayShift: Recurring.HolidayShift?
        let paidOn: LocalDate
        let from: LocalDate
        let through: LocalDate
    }
}

private extension RecurringCardBillTests {
    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.cases("recurring/card-bill-period.json")
        }
    }

    static func bill(
        closingDay: Int,
        day: Int = 10,
        holidayShift: Recurring.HolidayShift = .none
    ) throws -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let start = try #require(LocalDate("2026-01-01"))

        return Recurring(
            type: .transfer,
            amount: 45000,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: Wallet.ID(),
            frequency: .monthly,
            day: day,
            holidayShift: holidayShift,
            closingDay: closingDay,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )
    }

    static func entry(
        _ type: Entry.Kind,
        _ amount: Int,
        on date: String,
        wallet: Wallet.ID
    ) throws -> Entry {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return try Entry(
            type: type,
            amount: amount,
            date: #require(LocalDate(date)),
            categoryId: nil,
            walletId: wallet,
            createdAt: now,
            updatedAt: now
        )
    }
}
