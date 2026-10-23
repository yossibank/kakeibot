import Core
import GRDB

enum MigrationV13 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "new_recurring") { table in
            table.primaryKey("id", .text)

            table.column("type", .text)
                .notNull()
                .check { Entry.Kind.allCases.contains($0) }

            table.column("amount", .integer).notNull().check { $0 >= 0 }
            table.column("category_id", .text).references("category")
            table.column("wallet_id", .text).notNull().references("wallet")
            table.column("to_wallet_id", .text).references("wallet")
            table.column("memo", .text)

            table.column("frequency", .text)
                .notNull()
                .check { Recurring.Frequency.allCases.contains($0) }

            table.column("month", .integer).check { (1...12).contains($0) }

            table.column("day", .integer)
                .notNull()
                .check { (1...31).contains($0) }

            table.column("holiday_shift", .text)
                .notNull()
                .defaults(to: "none")

            table.column("closing_day", .integer)
                .check { (1...31).contains($0) }

            table.column("start_date", .text).notNull()
            table.column("end_date", .text)
            table.column("remind_days_before", .integer).check { $0 >= 0 }
            table.column("generated_until", .text)
            table.column("sort_order", .integer).notNull().defaults(to: 0)
            table.column("archived_at", .text)
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
            table.check(sql: "(type = 'transfer') = (category_id IS NULL)")
            table.check(sql: "(type = 'transfer') = (to_wallet_id IS NOT NULL)")

            let distinctWallets = "to_wallet_id IS NULL OR to_wallet_id <> wallet_id"

            table.check(sql: distinctWallets)
            table.check(sql: "(frequency = 'yearly') = (month IS NOT NULL)")
            table.check(sql: "closing_day IS NULL OR type = 'transfer'")
            table.check(sql: "amount >= 1 OR closing_day IS NOT NULL")
        }

        try db.execute(sql: copyRows)
        try db.drop(table: "recurring")
        try db.rename(table: "new_recurring", to: "recurring")
    }
}

private extension MigrationV13 {
    static let columns = """
    id, type, amount, category_id, wallet_id, to_wallet_id, memo,
    frequency, month, day, holiday_shift, start_date, end_date,
    remind_days_before, generated_until, sort_order, archived_at,
    created_at, updated_at
    """

    static let copyRows = """
    INSERT INTO new_recurring (\(columns))
    SELECT \(columns) FROM recurring
    """
}
