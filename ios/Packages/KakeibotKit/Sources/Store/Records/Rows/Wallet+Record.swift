import Core
import Foundation
import GRDB

extension Wallet: StoreRecord {
    public static let databaseTableName = "wallet"
}

extension Wallet.Kind: DatabaseValueConvertible {}

extension Wallet: ArchivableRecord, IconBackedRecord {
    public static var notFound: any Error {
        AppDatabase.WalletWriteError.walletNotFound
    }

    public static var iconNotFound: any Error {
        AppDatabase.WalletWriteError.iconNotFound
    }

    public static func setHidden(
        _ id: ID,
        _ isHidden: Bool,
        in db: Database,
        at now: Date
    ) throws {
        guard var wallet = try fetchOne(db, key: id) else {
            throw notFound
        }

        if isHidden,
           try AppDatabase.shownWalletCount(in: db) <= 1 {
            throw AppDatabase.WalletWriteError.lastShownWallet
        }

        wallet.archivedAt = isHidden ? now : nil
        wallet.updatedAt = now

        try wallet.update(db)
    }
}
