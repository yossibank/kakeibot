import Core
import Features
import Foundation
import Testing

struct BillPageTests {
    @Test
    func groupsBillsIntoTwoMonths() throws {
        let bills = try [
            Self.bill(on: "2026-10-26", amount: 30000),
            Self.bill(on: "2026-11-10", amount: 8000, isOpen: true),
            Self.bill(on: "2026-11-26", amount: 12000, isOpen: true),
            Self.bill(on: "2026-12-26", amount: 500, isOpen: true)
        ]

        let pages = BillPage.pages(of: bills)

        #expect(pages.map(\.month) == [YearMonth("2026-10"), YearMonth("2026-11")])
        #expect(pages.map(\.total) == [30000, 20000])
        #expect(pages.map(\.isOpen) == [false, true])
        #expect(pages.map(\.openCount) == [0, 2])
    }

    @Test
    func leavesOutBillsWithNothingToPay() throws {
        let bills = try [
            Self.bill(on: "2026-11-26", amount: 0),
            Self.bill(on: "2026-11-27", amount: 48200),
            Self.bill(on: "2026-12-26", amount: 0, isOpen: true),
            Self.bill(on: "2026-12-27", amount: 0, isOpen: true)
        ]

        let zero = try Self.bill(on: "2026-12-26", amount: 0, isOpen: true)

        let pages = BillPage.pages(of: bills)

        #expect(pages.map(\.month) == [YearMonth("2026-11")])
        #expect(pages.map(\.bills.count) == [1])
        #expect(pages.map(\.total) == [48200])
        #expect(BillPage.pages(of: [zero]).isEmpty)
    }

    @Test
    func keepsLastPageForIndexOutOfRange() throws {
        let bills = try [
            Self.bill(on: "2026-10-26", amount: 30000),
            Self.bill(on: "2026-11-26", amount: 12000)
        ]

        let pages = BillPage.pages(of: bills)
        let page = BillPage.page(5, in: pages)

        #expect(page?.month == YearMonth("2026-11"))
        #expect(BillPage.page(0, in: []) == nil)
    }
}

private extension BillPageTests {
    static func bill(
        on text: String,
        amount: Int,
        isOpen: Bool = false
    ) throws -> CardBill {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let date = try #require(LocalDate(text))
        let start = try #require(LocalDate("2026-01-01"))

        let recurring = Recurring(
            type: .transfer,
            amount: amount,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: Wallet.ID(),
            frequency: .monthly,
            day: date.day,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )

        return CardBill(
            recurring: recurring,
            date: date,
            amount: amount,
            balanceBefore: 0,
            isOpen: isOpen
        )
    }
}
