import GRDB

enum MigrationV26 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "sync_state") { table in
            table.primaryKey("id", .integer).check { $0 == 1 }
            table.column("enabled", .boolean).notNull().defaults(to: false)
            table.column("applying", .boolean).notNull().defaults(to: false)
            table.column("engine_state", .blob)
        }

        try db.execute(sql: "INSERT INTO sync_state (id) VALUES (1)")

        try db.create(table: "sync_change", options: .withoutRowID) { table in
            table.column("table_name", .text).notNull()
            table.column("record_id", .text).notNull()
            table.column("version", .integer).notNull()
            table.primaryKey(["table_name", "record_id"])
        }

        try db.create(table: "sync_waiting", options: .withoutRowID) { table in
            table.column("table_name", .text).notNull()
            table.column("record_id", .text).notNull()
            table.column("fields", .text).notNull()
            table.primaryKey(["table_name", "record_id"])
        }

        for (table, key) in tables {
            try createTriggers(on: table, key: key, in: db)
        }
    }
}

extension MigrationV26 {
    static let tables = [
        ("icon", "id"),
        ("wallet", "id"),
        ("category", "id"),
        ("tag", "id"),
        ("theme", "id"),
        ("recurring", "id"),
        ("template", "id"),
        ("entry", "id"),
        ("valuation", "id"),
        ("budget", "id"),
        ("reward_rule", "id"),
        ("reward_log", "id"),
        ("reward_goal", "id"),
        ("calendar_stamp", "id"),
        ("shelf_icon", "id"),
        ("no_spend_day", "date"),
        ("setting", "key")
    ]

    static let events = [
        ("insert", "INSERT", "NEW"),
        ("update", "UPDATE", "NEW"),
        ("delete", "DELETE", "OLD")
    ]

    static let localSettingKeys = """
    'onboarding_completed', 'setup_card_closed', 'entry_opened', 'settings_opened', \
    'closed_hints', 'closed_hidden_lists', 'recent_searches', 'widget_entry'
    """

    static let recording = "(SELECT enabled AND NOT applying FROM sync_state)"

    static func createTriggers(
        on table: String,
        key: String,
        recording: String = recording,
        in db: Database
    ) throws {
        for (name, event, row) in events {
            let local = table == "setting" ? " AND \(row).key NOT IN (\(localSettingKeys))" : ""

            try db.execute(sql: """
            CREATE TRIGGER sync_\(table)_\(name) AFTER \(event) ON \(table)
            WHEN \(recording)\(local)
            BEGIN
                INSERT INTO sync_change (table_name, record_id, version)
                VALUES ('\(table)', \(row).\(key), 1)
                ON CONFLICT (table_name, record_id) DO UPDATE SET version = version + 1;
            END
            """)
        }
    }
}
