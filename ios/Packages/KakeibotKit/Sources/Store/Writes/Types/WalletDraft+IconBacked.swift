import Core
import Foundation
import GRDB

extension WalletDraft: IconBackedDraft {
    public func newRecord(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> Wallet {
        try newWallet(iconId: iconId, sortOrder: sortOrder, at: now)
    }

    public func locked(by record: Wallet, in db: Database) throws -> WalletDraft {
        let id = record.id
        let hasRecords = try AppDatabase.hasRecords(of: id, in: db)
        let hasValuations = try AppDatabase.hasValuations(of: id, in: db)
        return locked(by: record, hasRecords: hasRecords, hasValuations: hasValuations)
    }
}
