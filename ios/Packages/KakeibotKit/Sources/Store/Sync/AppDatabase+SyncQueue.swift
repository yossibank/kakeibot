import Core
import Foundation
import GRDB

extension AppDatabase {
    static func queue(
        _ key: SyncKey,
        in db: Database
    ) throws {
        try db.execute(
            sql: """
            INSERT INTO sync_change (table_name, record_id, version) VALUES (?, ?, 1)
            ON CONFLICT (table_name, record_id) DO UPDATE SET version = version + 1
            """,
            arguments: [key.table.rawValue, key.id]
        )

        try db.notifyChanges(in: Table("sync_change"))
    }

    static func pendingChanges(in db: Database) throws -> [SyncChange] {
        try Row
            .fetchAll(db, sql: "SELECT table_name, record_id, version FROM sync_change")
            .compactMap { try SyncChange($0, in: db) }
    }
}

private extension SyncChange {
    init?(
        _ row: Row,
        in db: Database
    ) throws {
        guard let table = SyncTable(rawValue: row["table_name"]) else {
            return nil
        }

        let key = SyncKey(table: table, id: row["record_id"])
        let isDeletion = try AppDatabase.localRow(for: key, in: db) == nil
        let saveZone = try isDeletion ? nil : AppDatabase.saveZone(for: key, in: db)

        let zones = try String.fetchAll(
            db,
            sql: """
            SELECT zone_name FROM sync_record
            WHERE table_name = ? AND record_id = ?
            ORDER BY zone_name
            """,
            arguments: [table.rawValue, key.id]
        )

        let deleteZones = zones.filter { $0 != saveZone }

        self.init(
            key: key,
            isDeletion: isDeletion,
            saveZone: saveZone,
            deleteZones: deleteZones,
            version: row["version"]
        )
    }
}
