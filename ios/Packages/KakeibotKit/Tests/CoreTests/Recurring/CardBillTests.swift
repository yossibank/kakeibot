import Core
import Foundation
import Testing

struct CardBillTests {
    @Test
    func subtractsBillsFromSourceInDateOrder() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-20"))
        let start = try #require(LocalDate("2026-01-01"))
        let bank = Self.wallet(.bank, balance: 60000, at: now)
        let first = Self.wallet(.card, balance: 0, at: now)
        let second = Self.wallet(.card, balance: 0, at: now)

        let bills = [
            Self.bill(from: bank.id, to: second.id, amount: 40000, day: 27),
            Self.bill(from: bank.id, to: first.id, amount: 30000, day: 26)
        ].map { draft in
            Recurring(
                type: .transfer,
                amount: draft.amount,
                categoryId: nil,
                walletId: draft.from,
                toWalletId: draft.to,
                frequency: .monthly,
                day: draft.day,
                startDate: start,
                createdAt: now,
                updatedAt: now
            )
        }

        let upcoming = CardBill.upcoming(
            recurrings: bills,
            wallets: [bank, first, second],
            entries: [],
            valuations: [],
            after: today
        )

        #expect(upcoming.map(\.date.day) == [26, 27])
        #expect(upcoming.map(\.balanceBefore) == [60000, 30000])
        #expect(upcoming.map(\.shortage) == [0, 10000])
    }

    @Test
    func startsFromValuationOfSource() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-20"))
        let start = try #require(LocalDate("2026-01-01"))
        let source = Self.wallet(.investment, balance: 10000, at: now)
        let card = Self.wallet(.card, balance: 0, at: now)
        let valuationDate = try #require(LocalDate("2026-10-01"))

        let bill = Recurring(
            type: .transfer,
            amount: 30000,
            categoryId: nil,
            walletId: source.id,
            toWalletId: card.id,
            frequency: .monthly,
            day: 27,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )

        let valuation = Valuation(
            walletId: source.id,
            date: valuationDate,
            amount: 50000,
            createdAt: now,
            updatedAt: now
        )

        let upcoming = CardBill.upcoming(
            recurrings: [bill],
            wallets: [source, card],
            entries: [],
            valuations: [valuation],
            after: today
        )

        #expect(upcoming.map(\.balanceBefore) == [50000])
        #expect(upcoming.map(\.shortage) == [0])
    }
}

extension CardBillTests {
    struct Bill {
        let from: Wallet.ID
        let to: Wallet.ID
        let amount: Int
        let day: Int
    }
}

private extension CardBillTests {
    static func bill(
        from: Wallet.ID,
        to: Wallet.ID,
        amount: Int,
        day: Int
    ) -> Bill {
        Bill(from: from, to: to, amount: amount, day: day)
    }

    static func wallet(
        _ kind: Wallet.Kind,
        balance: Int,
        at now: Date
    ) -> Wallet {
        Wallet(
            name: "\(kind)",
            kind: kind,
            iconId: Icon.ID(),
            initialBalance: balance,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )
    }
}
