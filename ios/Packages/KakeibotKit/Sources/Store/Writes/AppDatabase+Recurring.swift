import Core
import Foundation
import GRDB

public extension AppDatabase {
    func generateRecurringEntries(
        through today: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            for recurring in try Recurring.fetchAll(db) {
                try Self.generateEntries(
                    of: recurring,
                    through: today,
                    in: db,
                    at: now
                )
            }
        }
    }
}

private extension AppDatabase {
    static func generateEntries(
        of recurring: Recurring,
        through today: LocalDate,
        in db: Database,
        at now: Date
    ) throws {
        let dates = recurring.pendingDates(through: today)

        for date in dates {
            let exists = try Entry
                .filter(Column("recurring_id") == recurring.id)
                .filter(Column("recurring_date") == date)
                .fetchCount(db) > 0

            guard !exists else {
                continue
            }

            let entry = Entry(
                type: recurring.type,
                amount: recurring.amount,
                date: date,
                categoryId: recurring.categoryId,
                walletId: recurring.walletId,
                toWalletId: recurring.toWalletId,
                memo: recurring.memo,
                recurringId: recurring.id,
                recurringDate: date,
                createdAt: now,
                updatedAt: now
            )

            try entry.insert(db)

            if entry.type == .expense {
                try NoSpendDay.deleteOne(db, key: date)
            }
        }

        guard recurring.startDate <= today else {
            return
        }

        var updated = recurring
        updated.generatedUntil = today
        try updated.update(db)
    }
}
