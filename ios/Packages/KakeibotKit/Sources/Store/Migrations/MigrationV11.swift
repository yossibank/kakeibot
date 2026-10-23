import GRDB

enum MigrationV11 {
    static func migrate(_ db: Database) throws {
        try db.execute(sql: keepLatestPerDay)

        try db.create(
            index: "calendar_stamp_date",
            on: "calendar_stamp",
            columns: ["date"],
            unique: true
        )
    }
}

private extension MigrationV11 {
    static let keepLatestPerDay = """
    DELETE FROM calendar_stamp WHERE id NOT IN (
        SELECT id FROM calendar_stamp AS kept
        WHERE kept.date = calendar_stamp.date
        ORDER BY kept.created_at DESC, kept.id DESC
        LIMIT 1
    )
    """
}
