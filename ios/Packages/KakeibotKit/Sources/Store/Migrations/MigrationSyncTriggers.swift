import GRDB

enum MigrationSyncTriggers {
    static let events = [
        ("insert", "INSERT", "NEW"),
        ("update", "UPDATE", "NEW"),
        ("delete", "DELETE", "OLD")
    ]

    static let localSettingKeys = """
    'onboarding_completed', 'setup_card_closed', 'entry_opened', 'settings_opened', \
    'closed_hints', 'closed_hidden_lists', 'recent_searches', 'widget_entry'
    """

    static let ownRecording = "(SELECT enabled AND NOT applying FROM sync_state)"

    static let sharedRecording = """
    (SELECT (enabled OR EXISTS (SELECT 1 FROM sync_share)) AND NOT applying FROM sync_state)
    """

    static func create(
        on table: String,
        key: String,
        recording: String = sharedRecording,
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

    static func drop(
        on table: String,
        in db: Database
    ) throws {
        for (name, _, _) in events {
            try db.execute(sql: "DROP TRIGGER sync_\(table)_\(name)")
        }
    }
}
