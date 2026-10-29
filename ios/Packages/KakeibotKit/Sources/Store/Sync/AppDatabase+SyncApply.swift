import Foundation
import GRDB

public extension AppDatabase {
    func applySyncChanges(
        saved: [SyncRecord],
        deleted: [SyncRecordID],
        systemFields: [SyncRecordID: Data] = [:]
    ) async throws {
        try await writer.write { db in
            let joinedIDs = Array(systemFields.keys)

            try Self.setApplying(true, in: db)

            for id in Self.parentsLast(deleted) {
                if try Self.canApplyDeletion(of: id, in: db) {
                    try Self.applyDeletion(of: id.key, in: db)
                }

                try Self.removeSystemFields(of: id, in: db)
            }

            for record in Self.parentsFirst(saved) {
                try Self.applySave(of: record, in: db)
            }

            for (id, data) in systemFields {
                try Self.saveSystemFields(data, of: id, in: db)
            }

            try Self.retryWaiting(in: db)
            try Self.joinSharedWallets(in: joinedIDs, db: db)
            try Self.setApplying(false, in: db)
        }
    }

    func syncSystemFields(for id: SyncRecordID) async throws -> Data? {
        try await writer.read { db in
            try Data.fetchOne(
                db,
                sql: """
                SELECT system_fields FROM sync_record
                WHERE table_name = ? AND record_id = ? AND zone_name = ?
                """,
                arguments: [id.key.table.rawValue, id.key.id, id.zoneName]
            )
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

private extension AppDatabase {
    enum Outcome {
        case applied
        case skipped
        case blocked
    }

    static func parentsFirst(_ records: [SyncRecord]) -> [SyncRecord] {
        let pairs = SyncTable.allCases.enumerated().map { ($1, $0) }
        let order = Dictionary(uniqueKeysWithValues: pairs)
        return records.sorted { order[$0.key.table, default: 0] < order[$1.key.table, default: 0] }
    }

    static func parentsLast(_ ids: [SyncRecordID]) -> [SyncRecordID] {
        let pairs = SyncTable.allCases.enumerated().map { ($1, $0) }
        let order = Dictionary(uniqueKeysWithValues: pairs)
        return ids.sorted { order[$0.key.table, default: 0] > order[$1.key.table, default: 0] }
    }

    static func canApplyDeletion(
        of id: SyncRecordID,
        in db: Database
    ) throws -> Bool {
        let zones = try String.fetchAll(
            db,
            sql: "SELECT zone_name FROM sync_record WHERE table_name = ? AND record_id = ?",
            arguments: [id.key.table.rawValue, id.key.id]
        )

        return zones.isEmpty || zones.contains(id.zoneName)
    }

    static func joinSharedWallets(
        in ids: [SyncRecordID],
        db: Database
    ) throws {
        let zoneWalletIDs = ids.compactMap { SyncZone.walletID(of: $0.zoneName) }
        let walletIDs = Set(zoneWalletIDs)

        for walletID in walletIDs {
            try db.execute(
                sql: """
                INSERT INTO sync_share (wallet_id, owner_name)
                SELECT id, NULL FROM wallet WHERE id = ?
                ON CONFLICT DO NOTHING
                """,
                arguments: [walletID.description]
            )
        }
    }

    static func applyDeletion(
        of key: SyncKey,
        in db: Database
    ) throws {
        try removeWaiting(key, in: db)

        do {
            try db.inSavepoint {
                try db.execute(
                    sql: "DELETE FROM \(key.table.rawValue) WHERE \(key.table.keyColumn) = ?",
                    arguments: [key.id]
                )

                return .commit
            }
        } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
            try queue(key, in: db)
        }
    }

    static func applySave(
        of record: SyncRecord,
        in db: Database
    ) throws {
        guard try save(record, in: db) == .blocked else {
            try removeWaiting(record.key, in: db)
            return
        }

        let data = try JSONEncoder().encode(record.values)
        let fields = String(decoding: data, as: UTF8.self)

        try db.execute(
            sql: """
            INSERT INTO sync_waiting (table_name, record_id, fields) VALUES (?, ?, ?)
            ON CONFLICT (table_name, record_id) DO UPDATE SET fields = excluded.fields
            """,
            arguments: [
                record.key.table.rawValue,
                record.key.id,
                fields
            ]
        )
    }

    static func retryWaiting(in db: Database) throws {
        var progressed = true

        while progressed {
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT table_name, record_id, fields FROM sync_waiting"
            )

            let waiting = rows.compactMap(SyncRecord.init(waiting:))
            let records = parentsFirst(waiting)

            progressed = false

            for record in records {
                guard try save(record, in: db) != .blocked else {
                    continue
                }

                try removeWaiting(record.key, in: db)

                progressed = true
            }
        }
    }

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

    static func removeWaiting(
        _ key: SyncKey,
        in db: Database
    ) throws {
        try db.execute(
            sql: "DELETE FROM sync_waiting WHERE table_name = ? AND record_id = ?",
            arguments: [key.table.rawValue, key.id]
        )
    }

    static func save(
        _ record: SyncRecord,
        in db: Database
    ) throws -> Outcome {
        let table = record.key.table
        let names = try db.columns(in: table.rawValue).map(\.name)
        let columns = Set(names)
        let values = record.values.filter { columns.contains($0.key) && $0.key != table.keyColumn }

        guard try isNewer(record, in: db) else {
            return .skipped
        }

        do {
            try db.inSavepoint {
                try removeConflicts(with: record, in: db)
                try upsert(record.key, values: values, in: db)
                return .commit
            }

            return .applied
        } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
            return .blocked
        }
    }

    static func isNewer(
        _ record: SyncRecord,
        in db: Database
    ) throws -> Bool {
        guard let row = try localRow(for: record.key, in: db) else {
            return try !isPending(record.key, in: db)
        }

        guard
            record.key.table.hasUpdatedAt,
            case let .text(incoming) = record.values["updated_at"],
            let local = row["updated_at"] as String?
        else {
            return true
        }

        return incoming >= local
    }

    static func isPending(
        _ key: SyncKey,
        in db: Database
    ) throws -> Bool {
        try Bool.fetchOne(
            db,
            sql: "SELECT EXISTS (SELECT 1 FROM sync_change WHERE table_name = ? AND record_id = ?)",
            arguments: [key.table.rawValue, key.id]
        ) ?? false
    }

    static func removeConflicts(
        with record: SyncRecord,
        in db: Database
    ) throws {
        let table = record.key.table

        for unique in table.uniqueKeys {
            let values = unique.columns.map { record.values[$0] ?? .null }

            guard unique.matchesNull || !values.contains(.null) else {
                continue
            }

            let conditions = unique.columns.map { "\($0) IS ?" }.joined(separator: " AND ")
            let databaseValues = values.map(\.databaseValue) + [record.key.id.databaseValue]
            let arguments = StatementArguments(databaseValues)

            try setApplying(false, in: db)

            try db.execute(
                sql: """
                DELETE FROM \(table.rawValue)
                WHERE \(conditions) AND \(table.keyColumn) <> ?
                """,
                arguments: arguments
            )

            try setApplying(true, in: db)
        }
    }

    static func upsert(
        _ key: SyncKey,
        values: [String: SyncValue],
        in db: Database
    ) throws {
        let names = [key.table.keyColumn] + values.keys.sorted()
        let placeholders = Array(repeating: "?", count: names.count).joined(separator: ", ")
        let updates = values.keys.sorted().map { "\($0) = excluded.\($0)" }
        let action = updates.isEmpty ? "NOTHING" : "UPDATE SET " + updates.joined(separator: ", ")
        let sortedValues = values.keys.sorted().compactMap { values[$0]?.databaseValue }
        let databaseValues = [key.id.databaseValue] + sortedValues
        let arguments = StatementArguments(databaseValues)

        try db.execute(
            sql: """
            INSERT INTO \(key.table.rawValue) (\(names.joined(separator: ", ")))
            VALUES (\(placeholders))
            ON CONFLICT (\(key.table.keyColumn)) DO \(action)
            """,
            arguments: arguments
        )
    }
}

private extension SyncRecord {
    init?(waiting row: Row) {
        guard
            let table = SyncTable(rawValue: row["table_name"]),
            let fields = (row["fields"] as String).data(using: .utf8),
            let values = try? JSONDecoder().decode([String: SyncValue].self, from: fields)
        else {
            return nil
        }

        let key = SyncKey(table: table, id: row["record_id"])

        self.init(key: key, values: values)
    }
}
