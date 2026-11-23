import Core
import GRDB

extension Entry: StoreRecord {
    public static let databaseTableName = "entry"
}

extension Entry {
    static func hasExpense(
        on date: LocalDate,
        in db: Database
    ) throws -> Bool {
        let expenses = filter(Column("date") == date).filter(Column("type") == Kind.expense)
        return try expenses.fetchCount(db) > 0
    }
}

extension Entry.Kind: DatabaseValueConvertible {}
