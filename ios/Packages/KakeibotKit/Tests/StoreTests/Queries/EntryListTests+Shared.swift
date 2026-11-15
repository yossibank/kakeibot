import Core
import Foundation
import GRDB
@testable import Store
import Testing

extension EntryListTests {
    @Test
    func listsSharedWallets() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let shared = options.wallets[0]
        let other = options.wallets[1]

        try await database.writer.write { db in
            try db.execute(
                sql: "INSERT INTO sync_share (wallet_id) VALUES (?)",
                arguments: [shared.id]
            )
        }

        let list = try await database.entryList()
        let updated = try await database.entryOptions()

        #expect(list.isShared(shared))
        #expect(!list.isShared(other))
        #expect(updated.sharedWalletIds == [shared.id])
    }
}
