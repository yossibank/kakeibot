import Core
import Foundation
import Store
import Testing

extension AppDatabase {
    func insertCardBill(at now: Date) async throws -> Recurring {
        let options = try await entryOptions()
        let bank = options.wallets[1]
        let start = try #require(LocalDate("2026-01-01"))

        let card = Wallet(
            name: "カード",
            kind: .card,
            iconId: bank.iconId,
            initialBalance: 0,
            sortOrder: 9,
            createdAt: now,
            updatedAt: now
        )

        let bill = Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: card.id,
            frequency: .monthly,
            day: 27,
            closingDay: 15,
            startDate: start,
            createdAt: now,
            updatedAt: now
        )

        try await writer.write { db in
            try card.insert(db)
            try bill.insert(db)
        }

        return bill
    }
}
