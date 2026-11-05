import Core
@testable import Features
import Foundation
import SwiftUI
import Testing

struct BillTextTests {
    @Test(arguments: [
        ("2026-10-20", "今日"),
        ("2026-10-21", "明日"),
        ("2026-10-22", "あと 2 日"),
        ("2026-11-10", "あと 21 日")
    ])
    func namesDaysUntilBill(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-20"))
        let date = try #require(LocalDate(text))
        let days = BillText.days(until: date, today: today)
        #expect(days == expected)
    }

    @Test
    func namesShortageWithBalance() {
        let text = BillText.shortage(1200)
        #expect(text == "残高が ¥1,200 足りません")
    }

    @Test(arguments: [
        ("みずほ銀行", "みずほ銀行から"),
        (nil, "口座から")
    ] as [(String?, String)])
    func namesSourceWallet(name: String?, expected: String) {
        let text = BillText.source(name)
        #expect(text == expected)
    }

    @Test(arguments: [
        (459_600, "¥459,600 → ¥408,800"),
        (49600, "残高が ¥1,200 足りません")
    ])
    func showsBalanceOrShortage(before: Int, expected: String) throws {
        let bill = try Self.bill(amount: 50800, balanceBefore: before)
        let text = BillText.balance(bill)
        #expect(text == expected)
    }

    @Test(arguments: [
        (50800, 203_200, 0.25),
        (50800, 49600, 1),
        (50800, 0, 1)
    ])
    func sharesBalanceUpToWhole(amount: Int, before: Int, expected: Double) throws {
        let bill = try Self.bill(amount: amount, balanceBefore: before)
        let share = BillRow<EmptyView>.share(of: bill)
        #expect(share == expected)
    }
}

private extension BillTextTests {
    static func bill(
        amount: Int,
        balanceBefore: Int
    ) throws -> CardBill {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let date = try #require(LocalDate("2026-10-26"))

        let recurring = Recurring(
            type: .transfer,
            amount: amount,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: Wallet.ID(),
            frequency: .monthly,
            day: 26,
            startDate: date,
            createdAt: now,
            updatedAt: now
        )

        return CardBill(
            recurring: recurring,
            date: date,
            amount: amount,
            balanceBefore: balanceBefore
        )
    }
}
