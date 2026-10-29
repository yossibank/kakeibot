import Foundation
import GRDB

public extension AppDatabase {
    func isSyncEnabled() async throws -> Bool {
        try await writer.read { db in
            try Bool.fetchOne(db, sql: "SELECT enabled FROM sync_state") ?? false
        }
    }

    func syncEnabledUpdates() -> some AsyncSequence<Bool, any Error> {
        ValueObservation
            .tracking { db in
                try Bool.fetchOne(db, sql: "SELECT enabled FROM sync_state") ?? false
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func syncActivityUpdates() -> some AsyncSequence<SyncActivity, any Error> {
        ValueObservation
            .tracking { db in
                let enabled = try Bool.fetchOne(db, sql: "SELECT enabled FROM sync_state")
                let sharing = try Bool.fetchOne(db, sql: "SELECT EXISTS (SELECT 1 FROM sync_share)")

                return SyncActivity(
                    isSyncEnabled: enabled ?? false,
                    isSharing: sharing ?? false
                )
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func hasEntries() async throws -> Bool {
        try await writer.read { db in
            try Bool.fetchOne(db, sql: "SELECT EXISTS (SELECT 1 FROM entry)") ?? false
        }
    }

    func queueAllForSync() async throws {
        try await writer.write { db in
            try Self.queueAll(in: db)
        }
    }

    func turnOnSync() async throws {
        try await writer.write { db in
            try Self.clearOwnSync(in: db)
            try db.execute(sql: "UPDATE sync_state SET enabled = 1")
            try Self.queueAll(in: db)
        }
    }

    func turnOnSyncReplacingLocal() async throws {
        try await writer.write { db in
            try Self.setApplying(true, in: db)

            for table in SyncTable.allCases.reversed() {
                let ids = try Self.localIDs(in: table, db: db)

                for id in ids {
                    try db.execute(
                        sql: "DELETE FROM \(table.rawValue) WHERE \(table.keyColumn) = ?",
                        arguments: [id]
                    )
                }
            }

            try Self.clearSync(in: db)
            try db.execute(sql: "UPDATE sync_state SET enabled = 1")
            try Self.setApplying(false, in: db)
        }
    }

    func turnOffSync() async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET enabled = 0")
            try Self.clearOwnSync(in: db)
        }
    }

    func syncSaveZone(for key: SyncKey) async throws -> String {
        try await writer.read { db in
            try Self.saveZone(for: key, in: db)
        }
    }

    func pendingSyncChanges() async throws -> [SyncChange] {
        try await writer.read { db in
            try Self.pendingChanges(in: db)
        }
    }

    func pendingSyncCountUpdates() -> some AsyncSequence<Int, any Error> {
        ValueObservation
            .tracking(regions: Self.syncChangeRegions) { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM sync_change") ?? 0
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func syncChangeUpdates() -> some AsyncSequence<Void, any Error> {
        ValueObservation
            .tracking(regions: Self.syncChangeRegions) { db in
                try String.fetchAll(
                    db,
                    sql: "SELECT table_name || '/' || record_id || '/' || version FROM sync_change"
                )
            }
            .removeDuplicates()
            .values(in: writer)
            .map { _ in }
    }

    func removeSyncChanges(_ changes: [SyncChange]) async throws {
        try await writer.write { db in
            for change in changes {
                try db.execute(
                    sql: """
                    DELETE FROM sync_change
                    WHERE table_name = ? AND record_id = ? AND version = ?
                    """,
                    arguments: [change.key.table.rawValue, change.key.id, change.version]
                )
            }

            try db.notifyChanges(in: Table("sync_change"))
        }
    }

    func syncRecord(for key: SyncKey) async throws -> SyncRecord? {
        try await writer.read { db in
            try Self.localRow(for: key, in: db).map { row in
                let values = Dictionary(
                    uniqueKeysWithValues: row.columnNames.map { ($0, SyncValue(row[$0])) }
                )

                return SyncRecord(key: key, values: values)
            }
        }
    }

    func applySyncChanges(
        saved: [SyncRecord],
        deleted: [SyncRecordID],
        systemFields: [SyncRecordID: Data] = [:]
    ) async throws {
        try await writer.write { db in
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
            try Self.joinSharedWallets(in: Array(systemFields.keys), db: db)
            try Self.setApplying(false, in: db)
        }
    }

    func syncEngineState() async throws -> Data? {
        try await writer.read { db in
            try Data.fetchOne(db, sql: "SELECT engine_state FROM sync_state")
        }
    }

    func saveSyncEngineState(_ state: Data?) async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET engine_state = ?", arguments: [state])
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

    func resetSync() async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET engine_state = NULL")
            try db.execute(sql: "DELETE FROM sync_record")
        }
    }
}

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

    func setSyncEnabled(_ enabled: Bool) async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET enabled = ?", arguments: [enabled])
        }
    }
}

private extension AppDatabase {
    enum Outcome {
        case applied
        case skipped
        case blocked
    }

    static var syncChangeRegions: [Table<Row>] {
        (SyncTable.allCases.map(\.rawValue) + ["sync_change"]).map { Table($0) }
    }

    static func setApplying(
        _ applying: Bool,
        in db: Database
    ) throws {
        try db.execute(sql: "UPDATE sync_state SET applying = ?", arguments: [applying])
    }

    static func parentsFirst(_ records: [SyncRecord]) -> [SyncRecord] {
        let order = Dictionary(uniqueKeysWithValues: SyncTable.allCases.enumerated()
            .map { ($1, $0) })
        return records.sorted { order[$0.key.table, default: 0] < order[$1.key.table, default: 0] }
    }

    static func parentsLast(_ ids: [SyncRecordID]) -> [SyncRecordID] {
        let order = Dictionary(uniqueKeysWithValues: SyncTable.allCases.enumerated()
            .map { ($1, $0) })
        return ids.sorted {
            order[$0.key.table, default: 0] > order[$1.key.table, default: 0]
        }
    }

    static func localIDs(
        in table: SyncTable,
        db: Database
    ) throws -> [String] {
        let ids = try String.fetchAll(
            db,
            sql: "SELECT \(table.keyColumn) FROM \(table.rawValue)"
        )

        guard table == .setting else {
            return ids
        }

        return ids.filter { !SyncTable.localSettingKeys.contains($0) }
    }

    static func queueAll(in db: Database) throws {
        for table in SyncTable.allCases {
            let ids = try localIDs(in: table, db: db)

            for id in ids {
                try queue(SyncKey(table: table, id: id), in: db)
            }
        }
    }

    static func clearSync(in db: Database) throws {
        try db.execute(sql: "UPDATE sync_state SET engine_state = NULL")
        try db.execute(sql: "DELETE FROM sync_record")
        try db.execute(sql: "DELETE FROM sync_change")
        try db.execute(sql: "DELETE FROM sync_waiting")
        try db.notifyChanges(in: Table("sync_change"))
    }

    static func clearOwnSync(in db: Database) throws {
        let ownOnly = try pendingChanges(in: db).filter { change in
            (change.saveZone ?? SyncZone.own) == SyncZone.own
                && change.deleteZones.allSatisfy { $0 == SyncZone.own }
        }

        for change in ownOnly {
            try db.execute(
                sql: "DELETE FROM sync_change WHERE table_name = ? AND record_id = ?",
                arguments: [change.key.table.rawValue, change.key.id]
            )
        }

        try db.execute(sql: "UPDATE sync_state SET engine_state = NULL")
        try db.execute(
            sql: "DELETE FROM sync_record WHERE zone_name = ?",
            arguments: [SyncZone.own]
        )
        try db.execute(sql: "DELETE FROM sync_waiting")
        try db.notifyChanges(in: Table("sync_change"))
    }

    static func saveZone(
        for key: SyncKey,
        in db: Database
    ) throws -> String {
        try syncSharedWallet(for: key, in: db).map(SyncZone.wallet) ?? SyncZone.own
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
        let walletIDs = Set(ids.compactMap { SyncZone.walletID(of: $0.zoneName) })

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

    static func pendingChanges(in db: Database) throws -> [SyncChange] {
        try Row
            .fetchAll(db, sql: "SELECT table_name, record_id, version FROM sync_change")
            .compactMap { try SyncChange($0, in: db) }
    }

    static func localRow(
        for key: SyncKey,
        in db: Database
    ) throws -> Row? {
        try Row.fetchOne(
            db,
            sql: "SELECT * FROM \(key.table.rawValue) WHERE \(key.table.keyColumn) = ?",
            arguments: [key.id]
        )
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

        try db.execute(
            sql: """
            INSERT INTO sync_waiting (table_name, record_id, fields) VALUES (?, ?, ?)
            ON CONFLICT (table_name, record_id) DO UPDATE SET fields = excluded.fields
            """,
            arguments: [
                record.key.table.rawValue,
                record.key.id,
                String(decoding: JSONEncoder().encode(record.values), as: UTF8.self)
            ]
        )
    }

    static func retryWaiting(in db: Database) throws {
        var progressed = true

        while progressed {
            progressed = false

            let rows = try Row.fetchAll(
                db,
                sql: "SELECT table_name, record_id, fields FROM sync_waiting"
            )

            let records = parentsFirst(rows.compactMap(SyncRecord.init(waiting:)))

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
        let columns = try Set(db.columns(in: table.rawValue).map(\.name))
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
            let arguments = StatementArguments(values
                .map(\.databaseValue) + [record.key.id.databaseValue])

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
        let arguments = [key.id.databaseValue] + values.keys.sorted()
            .compactMap { values[$0]?.databaseValue }

        try db.execute(
            sql: """
            INSERT INTO \(key.table.rawValue) (\(names.joined(separator: ", ")))
            VALUES (\(placeholders))
            ON CONFLICT (\(key.table.keyColumn)) DO \(action)
            """,
            arguments: StatementArguments(arguments)
        )
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

        self.init(
            key: key,
            isDeletion: isDeletion,
            saveZone: saveZone,
            deleteZones: zones.filter { $0 != saveZone },
            version: row["version"]
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

        self.init(key: SyncKey(table: table, id: row["record_id"]), values: values)
    }
}
