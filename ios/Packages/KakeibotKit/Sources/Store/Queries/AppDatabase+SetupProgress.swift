import Core
import GRDB

public extension AppDatabase {
    func setupProgressUpdates() -> some AsyncSequence<SetupProgress, any Error> {
        ValueObservation.tracking(Self.setupProgress).removeDuplicates().values(in: writer)
    }
}

extension AppDatabase {
    static func setupProgress(in db: Database) throws -> SetupProgress {
        let totals = try budgets(in: db).filter { $0.categoryId == nil }
        let latestTotal = totals.max { $0.fromMonth < $1.fromMonth }
        let hasBudget = latestTotal?.amount != nil
        let wallets = try Wallet.fetchAll(db).filter { $0.archivedAt == nil }
        let hasBalance = wallets.contains { $0.initialBalance != 0 }
        let hasValuation = try Valuation.fetchCount(db) > 0
        let hasWalletBalance = hasBalance || hasValuation
        let hasRecurring = try !recurrings(in: db).isEmpty
        let hasReminder = try setting(.reminderTime, in: db) != nil
        let hasTheme = try setting(.theme, in: db) != .system

        return SetupProgress(
            hasBudget: hasBudget,
            hasWalletBalance: hasWalletBalance,
            hasRecurring: hasRecurring,
            hasReminder: hasReminder,
            hasTheme: hasTheme
        )
    }
}
