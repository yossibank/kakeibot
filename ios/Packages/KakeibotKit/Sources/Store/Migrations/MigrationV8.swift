import GRDB

enum MigrationV8 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "sort_order", .integer).notNull().defaults(to: 0)
        }

        try db.execute(sql: orderByDay)
    }
}

private extension MigrationV8 {
    static let orderByDay = """
    UPDATE recurring SET sort_order = (
        SELECT COUNT(*) FROM recurring AS other
        WHERE other.day < recurring.day
            OR (other.day = recurring.day
                AND other.created_at < recurring.created_at)
    )
    """
}
