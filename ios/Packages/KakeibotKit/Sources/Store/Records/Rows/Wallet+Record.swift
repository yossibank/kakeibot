import Core
import Foundation
import GRDB

extension Wallet: StoreRecord {
    public static let databaseTableName = "wallet"
}

extension Wallet.Kind: DatabaseValueConvertible {}

extension Wallet: ArchivableRecord {
    static var notFound: any Error {
        AppDatabase.WalletWriteError.walletNotFound
    }

    static func setHidden(
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

extension Wallet: IconBackedRecord {
    static var iconNotFound: any Error {
        AppDatabase.WalletWriteError.iconNotFound
    }
}

extension Wallet: ArchivableRow {
    public static let ordering = OrderedRowWrite<Wallet>.sortable
    public static let hiding = HidableRowWrite<Wallet>.hidable
}
