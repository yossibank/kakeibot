import Core
import GRDB

extension Entry: StoreRecord {
    public static let databaseTableName = "entry"
}

extension Entry {
    static let recurrenceSearchDays = 40

    static func recorded(
        of recurringId: Recurring.ID,
        near scheduled: LocalDate
    ) -> QueryInterfaceRequest<Entry> {
        let earliest = scheduled.adding(days: -recurrenceSearchDays)
        let latest = scheduled.adding(days: recurrenceSearchDays)

        return filter(Column("recurring_id") == recurringId)
            .filter(Column("recurring_date") >= earliest)
            .filter(Column("recurring_date") <= latest)
    }

    static func hasExpense(
        on date: LocalDate,
        in db: Database
    ) throws -> Bool {
        let expenses = filter(Column("date") == date).filter(Column("type") == Kind.expense)
        return try expenses.fetchCount(db) > 0
    }
}

extension Entry.Kind: DatabaseValueConvertible {}
