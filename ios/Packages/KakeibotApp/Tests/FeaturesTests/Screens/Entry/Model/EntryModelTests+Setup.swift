import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
    }
}

extension EntryModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let date = try #require(LocalDate("2026-10-12"))

        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database, date: date)
    }

    func saveEntry(amount: Int) async throws -> Entry {
        let options = try await database.entryOptions()
        let categoryId = options.expenseCategories.first?.id
        let walletId = try #require(options.wallets.first?.id)
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: date,
            categoryId: categoryId,
            walletId: walletId
        )

        return try await database.saveEntry(draft, at: now)
    }

    func saveEntry(
        category categoryId: EntryCategory.ID,
        wallet walletId: Wallet.ID,
        at seconds: TimeInterval
    ) async throws {
        let today = LocalDate(Date(), in: .current)
        let createdAt = Date(timeIntervalSince1970: seconds)

        let draft = EntryDraft(
            type: .expense,
            amount: 500,
            date: today,
            categoryId: categoryId,
            walletId: walletId
        )

        try await database.saveEntry(draft, at: createdAt)
    }

    func cardWithBill() async throws -> Wallet {
        let options = try await database.entryOptions()
        let bank = options.wallets.first { $0.kind == .bank }

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await database.saveWallet(wallet, at: Date())

        let recurring = RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank?.id,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            closingDay: 31,
            startDate: date
        )

        _ = try await database.saveRecurring(recurring, today: date, at: Date())

        return card
    }
}
