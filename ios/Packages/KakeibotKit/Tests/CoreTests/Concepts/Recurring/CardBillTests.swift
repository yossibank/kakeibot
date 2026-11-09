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
            adjustments: [],
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
            adjustments: [],
            after: today
        )

        #expect(upcoming.map(\.balanceBefore) == [50000])
        #expect(upcoming.map(\.shortage) == [0])
    }

    @Test
    func startsFromAdjustedBalanceOfSource() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-20"))
        let start = try #require(LocalDate("2026-01-01"))
        let source = Self.wallet(.bank, balance: 10000, at: now)
        let card = Self.wallet(.card, balance: 0, at: now)

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

        let adjustment = Adjustment(
            walletId: source.id,
            date: today,
            amount: 5000,
            createdAt: now,
            updatedAt: now
        )

        let upcoming = CardBill.upcoming(
            recurrings: [bill],
            wallets: [source, card],
            entries: [],
            valuations: [],
            adjustments: [adjustment],
            after: today
        )

        #expect(upcoming.map(\.balanceBefore) == [15000])
        #expect(upcoming.map(\.shortage) == [15000])
    }

    @Test
    func countsSourceRecordsBeforeBillDate() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-20"))
        let bank = Self.wallet(.bank, balance: 100_000, at: now)
        let card = Self.wallet(.card, balance: 0, at: now)
        let recurring = try Self.recurring(from: bank.id, to: card.id, amount: 30000, day: 27)

        let entries = try [
            Self.entry(.expense, 10000, on: "2026-10-26", wallet: bank.id),
            Self.entry(.income, 280_000, on: "2026-10-27", wallet: bank.id),
            Self.entry(.income, 50000, on: "2026-11-25", wallet: bank.id)
        ]

        let upcoming = CardBill.upcoming(
            recurrings: [recurring],
            wallets: [bank, card],
            entries: entries,
            valuations: [],
            adjustments: [],
            after: today
        )

        #expect(upcoming.map(\.balanceBefore) == [90000])
    }

    @Test
    func listsBillsOfEachCardUpToCount() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-20"))
        let bank = Self.wallet(.bank, balance: 100_000, at: now)
        let first = Self.wallet(.card, balance: 0, at: now)
        let second = Self.wallet(.card, balance: 0, at: now)

        let recurrings = try [
            Self.recurring(from: bank.id, to: first.id, amount: 30000, day: 26),
            Self.recurring(from: bank.id, to: second.id, amount: 20000, day: 10)
        ]

        let entries = try [
            Self.entry(.income, 280_000, on: "2026-10-27", wallet: bank.id),
            Self.entry(.expense, 5000, on: "2026-11-26", wallet: bank.id)
        ]

        let upcoming = CardBill.upcoming(
            recurrings: recurrings,
            wallets: [bank, first, second],
            entries: entries,
            valuations: [],
            adjustments: [],
            after: today,
            count: 2
        )

        #expect(upcoming.map(\.date.description) == [
            "2026-10-26",
            "2026-11-10",
            "2026-11-26",
            "2026-12-10"
        ])

        #expect(upcoming.map(\.balanceBefore) == [100_000, 350_000, 330_000, 295_000])
    }

    @Test
    func marksBillBeforeClosingAsOpen() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate("2026-10-16"))
        let bank = Self.wallet(.bank, balance: 100_000, at: now)
        let card = Self.wallet(.card, balance: 0, at: now)
        let fixed = Self.wallet(.card, balance: 0, at: now)

        let recurrings = try [
            Self.recurring(from: bank.id, to: card.id, amount: 0, day: 26, closingDay: 15),
            Self.recurring(from: bank.id, to: fixed.id, amount: 30000, day: 27)
        ]

        let upcoming = CardBill.upcoming(
            recurrings: recurrings,
            wallets: [bank, card, fixed],
            entries: [],
            valuations: [],
            adjustments: [],
            after: today,
            count: 2
        )

        #expect(upcoming.map(\.isOpen) == [false, false, true, false])
        #expect(upcoming.map(\.month.description) == ["2026-10", "2026-10", "2026-11", "2026-11"])
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

    static func recurring(
        from source: Wallet.ID,
        to card: Wallet.ID,
        amount: Int,
        day: Int,
        closingDay: Int? = nil
    ) throws -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let start = try #require(LocalDate("2026-01-01"))

        return Recurring(
            type: .transfer,
            amount: amount,
            categoryId: nil,
            walletId: source,
            toWalletId: card,
            frequency: .monthly,
            day: day,
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
        let localDate = try #require(LocalDate(date))

        return Entry(
            type: type,
            amount: amount,
            date: localDate,
            categoryId: nil,
            walletId: wallet,
            createdAt: now,
            updatedAt: now
        )
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
