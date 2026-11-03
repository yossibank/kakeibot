import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncDeletionTests {
    @Test
    func recurringDeletionWithDetachedEntriesIsResent() async throws {
        let device = try await SyncTests.Setup()
        let walletID = try await device.walletID()
        let entry = try await device.insertRecurringEntry(wallet: walletID)
        let recurring = SyncKey(table: .recurring, id: "r1")

        try await device.database.saveSyncSystemFields([
            recurring.own: Data([1]),
            entry.own: Data([1])
        ])
        try await device.database.removeSyncChanges(device.database.pendingSyncChanges())

        let current = try #require(try await device.database.syncRecord(for: entry))
        var values = current.values
        values["recurring_id"] = .null
        values["recurring_date"] = .null
        values["updated_at"] = .text("y")

        try await device.database.applySyncChanges(
            saved: [SyncRecord(key: entry, values: values)],
            deleted: [recurring.own]
        )

        #expect(try await device.database.syncRecord(for: recurring) == nil)
        #expect(try await device.pendingKeys() == [])
    }
}
