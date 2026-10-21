import Core
import Foundation
import GRDB

public extension AppDatabase {
    @discardableResult
    func saveValuation(
        _ amount: Int,
        of walletId: Wallet.ID,
        on date: LocalDate,
        at now: Date
    ) async throws -> Valuation {
        try await writer.write { db in
            try Valuation
                .filter(Column("wallet_id") == walletId)
                .filter(Column("date") == date)
                .deleteAll(db)

            let valuation = Valuation(
                walletId: walletId,
                date: date,
                amount: amount,
                createdAt: now,
                updatedAt: now
            )

            try valuation.insert(db)
            return valuation
        }
    }

    func deleteValuation(_ id: Valuation.ID) async throws {
        try await writer.write { db in
            _ = try Valuation.deleteOne(db, key: id)
        }
    }
}
