import Core
import Foundation
import Testing

struct HoldingsTests {
    @Test
    func splitsAvailableMoneyFromNetWorth() {
        let wallets = [
            Self.wallet(.bank, 489_700),
            Self.wallet(.card, -52000),
            Self.wallet(.investment, 300_000),
            Self.wallet(.loan, -1_200_000)
        ]

        let holdings = Holdings(wallets: wallets, entries: [])

        #expect(holdings.available == 437_700)
        #expect(holdings.unpaid == 52000)
        #expect(holdings.refund == 0)
        #expect(holdings.netWorth == -462_300)
    }

    @Test
    func showsRefundWhenCardIsPositive() {
        let wallets = [
            Self.wallet(.cash, 10000),
            Self.wallet(.card, 3000)
        ]

        let holdings = Holdings(wallets: wallets, entries: [])

        #expect(holdings.unpaid == 0)
        #expect(holdings.refund == 3000)
        #expect(holdings.available == 13000)
    }
}

private extension HoldingsTests {
    static func wallet(
        _ kind: Wallet.Kind,
        _ balance: Int
    ) -> Wallet {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return Wallet(
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
