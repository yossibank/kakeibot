import Core
@testable import Features
import Foundation
import Testing

struct AssetsEntrySheetTests {
    @Test
    func groupsUnpaidByCard() throws {
        let first = try Self.row("楽天カード", bills: [3000, 1000], later: [500])
        let second = try Self.row("イオンカード", bills: [2000], later: [])
        let bank = try Self.row("銀行", bills: nil, later: [])

        let content = AssetsEntrySheet.Content.unpaid(of: [first, bank, second])

        #expect(content.groups.map(\.title) == ["楽天カード", "イオンカード"])
        #expect(content.groups.map(\.amount) == [4500, 2000])
        #expect(content.groups.map(\.sections.count) == [3, 2])
        #expect(content.amount == 6500)
        #expect(content.note == "カード 2 枚 · 4 件")
    }

    @Test
    func namesSingleCardInNote() throws {
        let row = try Self.row("楽天カード", bills: [3000], later: [])
        let content = AssetsEntrySheet.Content.unpaid(of: [row])
        #expect(content.note == "楽天カード · 1 件")
    }
}

private extension AssetsEntrySheetTests {
    static func row(
        _ name: String,
        bills amounts: [Int]?,
        later: [Int]
    ) throws -> AssetsModel.WalletRow {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let date = try #require(LocalDate("2026-11-27"))

        let wallet = Wallet(
            name: name,
            kind: .card,
            iconId: Icon.ID(),
            initialBalance: 0,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let recurring = Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: wallet.id,
            frequency: .monthly,
            day: 27,
            startDate: date,
            createdAt: now,
            updatedAt: now
        )

        let unpaid = amounts.map { amounts in
            let bills = amounts.enumerated().map { index, amount in
                AssetsModel.UnpaidBill(
                    bill: CardBill(
                        recurring: recurring,
                        date: date.adding(days: index * 30),
                        amount: amount,
                        balanceBefore: 0
                    ),
                    total: amount,
                    rows: [item(amount)]
                )
            }

            let total = (amounts + later).reduce(0, +)

            return AssetsModel.Unpaid(
                total: total,
                bills: bills,
                later: later.map(item)
            )
        }

        return AssetsModel.WalletRow(
            wallet: wallet,
            icon: nil,
            balance: 0,
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
