import Core
import Foundation
import GRDB

public extension AppDatabase {
    func syncSystemFields(for id: SyncRecordID) async throws -> Data? {
        try await writer.read { db in
            try Data.fetchOne(
                db,
                sql: """
                SELECT system_fields FROM sync_record
                WHERE table_name = ? AND record_id = ? AND zone_name = ?
                    AND length(system_fields) > 0
                """,
                arguments: [id.key.table.rawValue, id.key.id, id.zoneName]
            )
        }
    }

    func noteSyncSends(_ ids: [SyncRecordID]) async throws {
        try await writer.write { db in
            for id in ids {
                try db.execute(
                    sql: """
                    INSERT INTO sync_record (table_name, record_id, zone_name, system_fields)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT (table_name, record_id, zone_name) DO NOTHING
                    """,
                    arguments: [id.key.table.rawValue, id.key.id, id.zoneName, Data()]
                )
            }
        }
    }

    func saveSyncSystemFields(_ fields: [SyncRecordID: Data]) async throws {
        try await writer.write { db in
            for (id, data) in fields {
                try Self.saveSystemFields(data, of: id, in: db)
            }
        }
    }

    func removeSyncSystemFields(_ ids: [SyncRecordID]) async throws {
        try await writer.write { db in
            for id in ids {
                try Self.removeSystemFields(of: id, in: db)
            }
        }
    }
}

extension AppDatabase {
    static func saveSystemFields(
        _ data: Data,
        of id: SyncRecordID,
        in db: Database
    ) throws {
        try db.execute(
            sql: """
            INSERT INTO sync_record (table_name, record_id, zone_name, system_fields)
            VALUES (?, ?, ?, ?)
            ON CONFLICT (table_name, record_id, zone_name)
            DO UPDATE SET system_fields = excluded.system_fields
            """,
            arguments: [id.key.table.rawValue, id.key.id, id.zoneName, data]
        )
    }

    static func removeSystemFields(
        of id: SyncRecordID,
        in db: Database
    ) throws {
        try db.execute(
            sql: """
            DELETE FROM sync_record
            WHERE table_name = ? AND record_id = ? AND zone_name = ?
            """,
            arguments: [id.key.table.rawValue, id.key.id, id.zoneName]
        )
    }
}
