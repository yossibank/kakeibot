import Core
import Foundation
import Store
import Testing

extension CardBillRecalcWriteTests.Setup {
    init(usage: [Int]) async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let startDate = try #require(LocalDate("2026-11-01"))
        let through = try #require(LocalDate("2026-11-10"))

        try database.insertDefaultsIfEmpty(at: now)

        let options = try await database.entryOptions()
        let bank = options.wallets[0].id
        let card = options.wallets[1].id
        let category = options.expenseCategories[0].id

        let bill = Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank,
            toWalletId: card,
            frequency: .monthly,
            day: 10,
            closingDay: 15,
            startDate: startDate,
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try bill.insert(db)
        }

        self.init(
            database: database,
            now: now,
            bank: bank,
            card: card,
            category: category,
            recurringId: bill.id
        )

        for amount in usage {
            try await spend(amount, on: "2026-10-01")
        }

        try await database.generateRecurringEntries(through: through, at: now)
    }

    @discardableResult
    func spend(
        _ amount: Int,
        on date: String,
        wallet: Wallet.ID? = nil
    ) async throws -> Entry {
        let day = try #require(LocalDate(date))

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: day,
            categoryId: category,
            walletId: wallet ?? card
        )

        return try await database.saveEntry(draft, at: now)
    }

    func bill() throws -> Entry? {
        try bill(of: recurringId)
    }

    func bill(of id: Recurring.ID) throws -> Entry? {
        try database.snapshot().entries.first { $0.recurringId == id }
    }

    func bills() throws -> [Entry] {
        try database.snapshot().entries.filter { $0.recurringId == recurringId }
    }
}
