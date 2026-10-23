import Core
import GRDB

public extension AppDatabase {
    func setupProgressUpdates()
        -> some AsyncSequence<SetupProgress, any Error> {
        ValueObservation
            .tracking(Self.setupProgress)
            .removeDuplicates()
            .values(in: writer)
    }
}

extension AppDatabase {
    static func setupProgress(in db: Database) throws -> SetupProgress {
        let totals = try budgets(in: db).filter { $0.categoryId == nil }
        let latestTotal = totals.max { $0.fromMonth < $1.fromMonth }

        let wallets = try Wallet.fetchAll(db)
            .filter { $0.archivedAt == nil }

        let hasBalance = wallets.contains { $0.initialBalance != 0 }
        let hasValuation = try Valuation.fetchCount(db) > 0

        return try SetupProgress(
            hasBudget: latestTotal?.amount != nil,
            hasWalletBalance: hasBalance || hasValuation,
            hasRecurring: !recurrings(in: db).isEmpty,
            hasReminder: setting(.reminderTime, in: db) != nil,
            hasTheme: setting(.theme, in: db) != .system
        )
    }
}
