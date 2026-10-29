import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncConflictTests {
    @Test
    func uniqueKeyConflictOnBothDevicesLosesBothRows() async throws {
        let a = try await SyncTests.Setup()
        let b = try await SyncTests.Setup()
        let keyA = SyncKey(table: .budget, id: "bA")
        let keyB = SyncKey(table: .budget, id: "bB")

        try await a.execute(
            "INSERT INTO budget (id, category_id, from_month, amount) VALUES ('bA', NULL, '2026-11', 50000)"
        )

        try await b.execute(
            "INSERT INTO budget (id, category_id, from_month, amount) VALUES ('bB', NULL, '2026-11', 60000)"
        )

        for _ in 0..<2 {
            let fromA = try await a.outgoing()
            let fromB = try await b.outgoing()

            try await b.receive(fromA)
            try await a.receive(fromB)
        }

        let budgetsA = try await a
            .value("SELECT group_concat(id) FROM budget WHERE from_month = '2026-11'")
        let budgetsB = try await b
            .value("SELECT group_concat(id) FROM budget WHERE from_month = '2026-11'")

        #expect(budgetsA == keyA.id)
        #expect(budgetsB == keyA.id)
    }

    @Test
    func keepsOlderLocalRowWhenNewerConflictArrives() async throws {
        let setup = try await SyncTests.Setup()
        let iconID = try await setup.iconID()

        try await setup.execute("""
        INSERT INTO calendar_stamp (id, date, icon_id, created_at)
        VALUES ('local', '2026-10-01', '\(iconID)', '2026-10-01T00:00:00Z')
        """)

        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let remote = SyncRecord(
            key: SyncKey(table: .calendarStamp, id: "remote"),
            values: [
                "date": .text("2026-10-01"),
                "icon_id": .text(iconID),
                "created_at": .text("2026-10-02T00:00:00Z")
            ]
        )

        try await setup.database.applySyncChanges(saved: [remote], deleted: [])

        let stamps = try await setup.value("SELECT group_concat(id) FROM calendar_stamp")

        #expect(stamps == "local")
        #expect(try await setup.pendingKeys() == [])
    }
}

extension SyncConflictTests {
    struct Changes {
        var saved: [SyncRecord] = []
        var deleted: [SyncRecordID] = []
        var systemFields: [SyncRecordID: Data] = [:]
    }
}

extension SyncTests.Setup {
    func outgoing() async throws -> SyncConflictTests.Changes {
        let pending = try await database.pendingSyncChanges()
        var changes = SyncConflictTests.Changes()

        for change in pending {
            if let record = try await database.syncRecord(for: change.key) {
                changes.saved.append(record)
                changes.systemFields[change.key.own] = Data([1])
            } else {
                changes.deleted.append(change.key.own)
            }
        }

        try await database.removeSyncChanges(pending)

        return changes
    }

    func receive(_ changes: SyncConflictTests.Changes) async throws {
        try await database.applySyncChanges(
            saved: changes.saved,
            deleted: changes.deleted,
            systemFields: changes.systemFields
        )
    }
}
