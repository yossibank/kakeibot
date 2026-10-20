import Core
import Foundation
import Testing

struct RecurringCardBillTests {
    @Test(arguments: try periodCases)
    func findsBillingPeriod(fixture: PeriodCase) throws {
        let bill = try Self.bill(closingDay: fixture.closingDay)
        let period = bill.billingPeriod(paidOn: fixture.paidOn)
        #expect(period == fixture.from...fixture.through)
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
        let paidOn: LocalDate
        let from: LocalDate
        let through: LocalDate
    }
}

private extension RecurringCardBillTests {
    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.load("recurring/card-bill-period.json")
        }
    }

    static func bill(closingDay: Int) throws -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let start = try #require(LocalDate("2026-01-01"))

        return Recurring(
            type: .transfer,
            amount: 45000,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: Wallet.ID(),
            frequency: .monthly,
            day: 10,
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
