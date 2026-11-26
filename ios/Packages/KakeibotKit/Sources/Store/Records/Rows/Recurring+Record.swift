import Core
import GRDB

extension Recurring {
    static func cardBills() -> QueryInterfaceRequest<Recurring> {
        filter(Column("closing_day") != nil)
    }

    static func shownCardBills() -> QueryInterfaceRequest<Recurring> {
        cardBills()
            .filter(Column("archived_at") == nil)
            .filter(Column("type") == Entry.Kind.transfer)
            .order(sortOrder, Column("created_at"))
    }
}

extension Recurring: StoreRecord {
    public static let databaseTableName = "recurring"
}

extension Recurring.Frequency: DatabaseValueConvertible {}

extension Recurring: SortableRecord {
    public static var notFound: any Error {
        AppDatabase.RecurringWriteError.recurringNotFound
    }
}

extension HolidayShift: DatabaseValueConvertible {}
