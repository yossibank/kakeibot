import Core
@testable import FeatureModels
import Foundation
import Testing

struct AssetsWalletSectionTests {
    @Test
    func splitsOwnedAndOwedTotals() {
        let sections = AssetsModel.WalletSection.sections(of: [
            Self.row(.cash, balance: 30000),
            Self.row(.bank, balance: 50000),
            Self.row(.card, balance: -20000),
            Self.row(.loan, balance: -60000)
        ])

        #expect(sections.owned.map(\.role) == [.onHand])
        #expect(sections.owed.map(\.role) == [.card, .loan])
        #expect(sections.owned.total == 80000)
        #expect(sections.owed.total == -80000)
        #expect(sections.owned.rowCount == 2)
        #expect(sections.first?.total == 80000)
        #expect(sections.ownedShare == 0.5)
    }

    @Test
    func sharesAllToOwnedWithoutBalances() {
        let sections = AssetsModel.WalletSection.sections(of: [Self.row(.cash, balance: 0)])

        #expect(sections.ownedShare == 1)
        #expect(sections.owed.isEmpty)
    }

    @Test
    func countsUnpaidAcrossCards() {
        let rows = [
            Self.row(.card, balance: 0, unpaid: [1000, 2000]),
            Self.row(.bank, balance: 0),
            Self.row(.card, balance: 0, unpaid: [500])
        ]

        #expect(rows.unpaidCount == 3)
        #expect(rows.unpaidTotal == 3500)
    }
}

private extension AssetsWalletSectionTests {
    static func row(
        _ kind: Wallet.Kind,
        balance: Int,
        unpaid amounts: [Int]? = nil
    ) -> AssetsModel.WalletRow {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let wallet = Wallet(
            name: "口座",
            kind: kind,
            iconId: Icon.ID(),
            initialBalance: 0,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let unpaid = amounts.map { amounts in
            AssetsModel.Unpaid(
                total: amounts.reduce(0, +),
                bills: [],
                later: amounts.map(item)
            )
        }

        return AssetsModel.WalletRow(
            wallet: wallet,
            icon: nil,
            balance: balance,
            bills: [],
            unpaid: unpaid,
            repayment: nil,
            repaidRatio: nil
        )
    }

    static func item(_ amount: Int) -> EntryRowItem {
        EntryRowItem(
            id: Entry.ID(),
            icon: nil,
            title: "記録",
            tag: nil,
            detail: nil,
            route: nil,
            memo: nil,
            amount: amount,
            type: .expense,
            isRecurring: false,
            items: [],
            taxIncluded: false
        )
    }
}
