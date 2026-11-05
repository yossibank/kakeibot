import Core
import Foundation
import GRDB

public extension AppDatabase {
    func deletableRecordCount() async throws -> Int {
        try await writer.read { db in
            let counts = try [
                Self.deletableEntries.fetchCount(db),
                Self.deletableValuations.fetchCount(db),
                Self.deletableAdjustments.fetchCount(db),
                RewardLog.fetchCount(db),
                CalendarStamp.fetchCount(db),
                NoSpendDay.fetchCount(db)
            ]

            return counts.reduce(0, +)
        }
    }

    func deleteAllRecords(at now: Date = Date()) async throws {
        try await writer.write { db in
            let entries = try Self.deletableEntries.fetchAll(db)
            let change = CardBillChange(before: entries)

            try Self.detachRewardGoals(from: entries.map(\.id), in: db, at: now)
            _ = try Self.deletableEntries.deleteAll(db)
            _ = try Self.deletableValuations.deleteAll(db)
            _ = try Self.deletableAdjustments.deleteAll(db)
            _ = try RewardLog.deleteAll(db)
            _ = try CalendarStamp.deleteAll(db)
            _ = try NoSpendDay.deleteAll(db)
            try Self.recalculateCardBills(change, in: db, at: now)
        }
    }
}

private extension AppDatabase {
    static var deletableEntries: QueryInterfaceRequest<Entry> {
        Entry.filter(sql: """
        wallet_id NOT IN (SELECT wallet_id FROM sync_share)
            AND (to_wallet_id IS NULL OR to_wallet_id NOT IN (SELECT wallet_id FROM sync_share))
            AND (transfer_id IS NULL OR transfer_id NOT IN (
                SELECT id FROM entry
                WHERE wallet_id IN (SELECT wallet_id FROM sync_share)
                    OR to_wallet_id IN (SELECT wallet_id FROM sync_share)
            ))
        """)
    }

    static var deletableValuations: QueryInterfaceRequest<Valuation> {
        Valuation.filter(sql: "wallet_id NOT IN (SELECT wallet_id FROM sync_share)")
    }

    static var deletableAdjustments: QueryInterfaceRequest<Adjustment> {
        Adjustment.filter(sql: "wallet_id NOT IN (SELECT wallet_id FROM sync_share)")
    }
}
