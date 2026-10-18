import Core
import GRDB

extension Recurring: StoreRecord {
    public static let databaseTableName = "recurring"
}

extension Recurring.Frequency: DatabaseValueConvertible {}

extension Recurring: SortableRecord {}
