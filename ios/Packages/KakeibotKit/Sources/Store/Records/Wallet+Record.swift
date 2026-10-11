import Core
import GRDB

extension Wallet: StoreRecord {
    public static let databaseTableName = "wallet"
}

extension Wallet.Kind: DatabaseValueConvertible {}
