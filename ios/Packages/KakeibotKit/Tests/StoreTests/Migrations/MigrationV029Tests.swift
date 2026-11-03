import GRDB
@testable import Store
import Testing

struct MigrationV029Tests {
    @Test
    func keepsSyncRecordsInOwnZone() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v28")

        try queue.write { db in
            try db.execute(sql: """
            INSERT INTO sync_record (table_name, record_id, system_fields)
            VALUES ('wallet', 'w1', x'01'), ('icon', 'i1', x'02')
            """)
        }

        try migrator.migrate(queue)

        let rows = try queue.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT table_name, zone_name FROM sync_record ORDER BY table_name"
            ).map { "\($0["table_name"] as String):\($0["zone_name"] as String)" }
        }

        #expect(rows == ["icon:Kakeibot", "wallet:Kakeibot"])
    }
}
