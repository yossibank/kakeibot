import Core
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
        let regions = Self.syncChangeRegions + [Table("sync_state"), Table("sync_share")]

        return ValueObservation
            .tracking(regions: regions) { db in
                let enabled = try Bool.fetchOne(db, sql: "SELECT enabled FROM sync_state")

                let sharing = try Bool.fetchOne(
                    db,
                    sql: """
                    SELECT EXISTS (SELECT 1 FROM sync_share)
                        OR (NOT enabled AND EXISTS (SELECT 1 FROM sync_change))
                    FROM sync_state
                    """
                )

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

    func turnOffSyncForAccountChange() async throws {
        try await writer.write { db in
            try db.execute(
                sql: """
                DELETE FROM sync_record WHERE zone_name IN (
                    SELECT \(SyncZone.walletZoneSQL) FROM sync_share WHERE owner_name IS NULL
                )
                """
            )

            try db.execute(sql: "DELETE FROM sync_share WHERE owner_name IS NULL")
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
                SyncRecord(key: key, row: row)
            }
        }
    }

    func syncEngineState(isShared: Bool) async throws -> Data? {
        try await writer.read { db in
            try Data.fetchOne(db, sql: "SELECT \(Self.engineStateColumn(isShared)) FROM sync_state")
        }
    }

    func saveSyncEngineState(
        _ state: Data?,
        isShared: Bool
    ) async throws {
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE sync_state SET \(Self.engineStateColumn(isShared)) = ?",
                arguments: [state]
            )
        }
    }

    func syncShareOwners() async throws -> [String: String] {
        try await writer.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT wallet_id, owner_name FROM sync_share WHERE owner_name IS NOT NULL"
            )

            let pairs = rows.map { row in
                (SyncZone.wallet(row["wallet_id"]), row["owner_name"] as String)
            }

            return Dictionary(uniqueKeysWithValues: pairs)
        }
    }

    func resetSync(isShared: Bool) async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET \(Self.engineStateColumn(isShared)) = NULL")

            try db.execute(
                sql: """
                DELETE FROM sync_record
                WHERE (zone_name IN (\(Self.foreignZones))) = ?
                """,
                arguments: [isShared]
            )
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

    static func setApplying(
        _ applying: Bool,
        in db: Database
    ) throws {
        try db.execute(sql: "UPDATE sync_state SET applying = ?", arguments: [applying])
    }

    static func saveZone(
        for key: SyncKey,
        in db: Database
    ) throws -> String {
        try syncSharedWallet(for: key, in: db).map(SyncZone.wallet) ?? SyncZone.own
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

    func setSyncEnabled(_ enabled: Bool) async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE sync_state SET enabled = ?", arguments: [enabled])
        }
    }
}

private extension AppDatabase {
    static let foreignZones = """
    SELECT \(SyncZone.walletZoneSQL) FROM sync_share WHERE owner_name IS NOT NULL
    """

    static let removeOwnWaitingSQL = """
    DELETE FROM sync_waiting
    WHERE NOT EXISTS (
        SELECT 1 FROM sync_share WHERE sync_waiting.fields LIKE '%' || sync_share.wallet_id || '%'
    ) AND NOT EXISTS (
        SELECT 1 FROM category JOIN sync_share ON sync_share.wallet_id = category.wallet_id
        WHERE sync_waiting.fields LIKE '%' || category.id || '%'
    )
    """

    static var syncChangeRegions: [Table<Row>] {
        let names = SyncTable.allCases.map(\.rawValue) + ["sync_change"]
        return names.map { Table($0) }
    }

    static func engineStateColumn(_ isShared: Bool) -> String {
        isShared ? "shared_engine_state" : "engine_state"
    }

    static func localIDs(
        in table: SyncTable,
        db: Database
    ) throws -> [String] {
        let ids = try String.fetchAll(db, sql: "SELECT \(table.keyColumn) FROM \(table.rawValue)")

        guard table == .setting else {
            return ids
        }

        return ids.filter { !SyncTable.localSettingKeys.contains($0) }
    }

    static func queueAll(in db: Database) throws {
        for table in SyncTable.allCases {
            let ids = try localIDs(in: table, db: db)

            for id in ids {
                let key = SyncKey(table: table, id: id)
                try queue(key, in: db)
            }
        }
    }

    static func clearSync(in db: Database) throws {
        try db.execute(sql: "UPDATE sync_state SET engine_state = NULL, shared_engine_state = NULL")
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

        try db.execute(sql: removeOwnWaitingSQL)
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
