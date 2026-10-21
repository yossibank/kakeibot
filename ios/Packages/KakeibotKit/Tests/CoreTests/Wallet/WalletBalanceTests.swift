import Core
import Foundation
import Testing

struct WalletBalanceTests {
    @Test(arguments: try balanceCases)
    func countsEntriesThroughDate(fixture: BalanceCase) {
        let other = Wallet.ID()
        let wallet = fixture.wallet()
        let entries = fixture.entries(wallet: wallet.id, other: other)
        let valuations = fixture.valuations(wallet: wallet.id)

        let balance = wallet.balance(
            with: entries,
            valuations: valuations,
            through: fixture.through
        )

        #expect(balance == fixture.balance)
    }

    @Test
    func sumsWallets() throws {
        let cash = BalanceCase.wallet(initialBalance: 1000)
        let card = BalanceCase.wallet(initialBalance: -500)
        let date = try #require(LocalDate("2026-10-01"))

        let entry = Entry(
            type: .expense,
            amount: 300,
            date: date,
            categoryId: EntryCategory.ID(),
            walletId: cash.id,
            createdAt: Date(),
            updatedAt: Date()
        )

        let total = Wallet.totalBalance(of: [cash, card], with: [entry])

        #expect(total == 200)
    }
}

extension WalletBalanceTests {
    struct BalanceCase: Decodable, Sendable {
        let initialBalance: Int
        let entries: [EntryCase]
        let valuations: [ValuationCase]?
        let through: LocalDate?
        let balance: Int
    }

    struct ValuationCase: Decodable, Sendable {
        let date: LocalDate
        let amount: Int
        let createdAt: Date?
    }

    struct EntryCase: Decodable, Sendable {
        let type: Entry.Kind
        let amount: Int
        let date: LocalDate
        let wallet: Side
        let toWallet: Side?
        let createdAt: Date?
    }

    enum Side: String, Decodable, Sendable {
        case `self`
        case other
    }
}

extension WalletBalanceTests.BalanceCase {
    static let recordedAt = Date(timeIntervalSince1970: 0)
    static let valuedAt = Date(timeIntervalSince1970: 1)

    static func wallet(initialBalance: Int) -> Wallet {
        Wallet(
            name: "財布",
            kind: .cash,
            iconId: Icon.ID(),
            initialBalance: initialBalance,
            sortOrder: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func wallet() -> Wallet {
        Self.wallet(initialBalance: initialBalance)
    }

    func valuations(wallet: Wallet.ID) -> [Valuation] {
        (valuations ?? []).map { valuation in
            Valuation(
                walletId: wallet,
                date: valuation.date,
                amount: valuation.amount,
                createdAt: valuation.createdAt ?? Self.valuedAt,
                updatedAt: Date()
            )
        }
    }

    func entries(
        wallet: Wallet.ID,
        other: Wallet.ID
    ) -> [Entry] {
        entries.map { entry in
            let from = entry.wallet == .self ? wallet : other
            let to = entry.toWallet.map { $0 == .self ? wallet : other }
            let category = entry.type == .transfer ? nil : EntryCategory.ID()

            return Entry(
                type: entry.type,
                amount: entry.amount,
                date: entry.date,
                categoryId: category,
                walletId: from,
                toWalletId: to,
                createdAt: entry.createdAt ?? Self.recordedAt,
                updatedAt: Date()
            )
        }
    }
}

private extension WalletBalanceTests {
    static var balanceCases: [BalanceCase] {
        get throws {
            try Fixture.load("wallet/wallet-balance.json")
        }
    }
}
