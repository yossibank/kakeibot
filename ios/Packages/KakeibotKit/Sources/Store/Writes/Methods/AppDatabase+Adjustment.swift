import Core
import Foundation
import GRDB

public extension AppDatabase {
    @discardableResult
    func saveAdjustment(
        _ amount: Int,
        of walletId: Wallet.ID,
        on date: LocalDate,
        at now: Date
    ) async throws -> Adjustment? {
        guard amount != 0 else {
            return nil
        }

        return try await writer.write { db in
            let adjustment = Adjustment(
                walletId: walletId,
                date: date,
                amount: amount,
                createdAt: now,
                updatedAt: now
            )

            try adjustment.insert(db)

            return adjustment
        }
    }

    func deleteAdjustment(_ id: Adjustment.ID) async throws -> Deletion? {
        try await writer.write { db in
            guard let adjustment = try Adjustment.fetchOne(db, key: id) else {
                return nil
            }

            _ = try adjustment.delete(db)

            return Deletion(adjustments: [adjustment])
        }
    }
}
