import GRDB

enum MigrationV15 {
    static let walletKinds = [
        "cash",
        "bank",
        "card",
        "emoney",
        "point",
        "other",
        "investment",
        "loan"
    ]

    private static let columns = """
    id, name, kind, icon_id, initial_balance, sort_order, archived_at,
    created_at, updated_at
    """

    private static let copyRows = """
    INSERT INTO new_wallet (\(columns))
    SELECT \(columns) FROM wallet
    """

    static func migrate(_ db: Database) throws {
        try db.create(table: "new_wallet") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()
            table.column("kind", .text).notNull().check { walletKinds.contains($0) }
            table.column("icon_id", .text).notNull().references("icon")
            table.column("initial_balance", .integer).notNull()
            table.column("sort_order", .integer).notNull()
            table.column("archived_at", .text)
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }

        try db.execute(sql: copyRows)
        try db.drop(table: "wallet")
        try db.rename(table: "new_wallet", to: "wallet")
    }
}
