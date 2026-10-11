import Core
import GRDB

extension Setting: StoreRecord {
    public static let databaseTableName = "setting"
}

extension Setting.Key: DatabaseValueConvertible {}
