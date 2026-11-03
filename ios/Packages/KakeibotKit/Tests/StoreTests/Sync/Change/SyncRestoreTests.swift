import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncRestoreTests {
    @Test
    func restoringBackupWhileSharingQueuesDeletionsForSharedZone() async throws {
        let owner = try await SyncTests.Setup(enabled: false)
        let walletID = try await owner.walletID()
        let categoryID = try await owner.categoryID()
        let id = try #require(Wallet.ID(walletID))
        let app = ExportV1.App(platform: .ios, version: "1")
        let backup = try await ExportV1(json: owner.database.backup(at: Date(), app: app))
        let key = SyncKey(table: .entry, id: "11111111-1111-4111-8111-111111111111")

        try await owner.database.startSharing(id)

        try await owner.execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES ('\(key.id)', 'expense', 1, '\(categoryID)', '\(walletID)', '2026-10-12',
            '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
        """)

        try await owner.database
            .saveSyncSystemFields([key.recordID(in: SyncZone.wallet(id)): Data([1])])
        try await owner.database.removeSyncChanges(owner.database.pendingSyncChanges())

        await #expect(throws: AppDatabase.RestoreError.sharing) {
            try await owner.database.restoreBackup(backup, stashingAt: Date(), app: app) { _ in }
        }

        let change = try await owner.database.pendingSyncChanges().first { $0.key == key }

        #expect(change == nil)
        #expect(try await owner.database.syncRecord(for: key) != nil)
    }
}
