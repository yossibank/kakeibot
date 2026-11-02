import Core
import Foundation
import GRDB
import Store
import Testing

struct ReceiptWriteTests {
    @Test
    func countsReceiptSaves() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.receiptSavedCount)
        try await database.countReceiptSave()
        try await database.countReceiptSave()
        let counted = try await database.setting(.receiptSavedCount)
        let text = try await countText(in: database)

        #expect(initial == 0)
        #expect(counted == 2)
        #expect(text == "2")
    }

    @Test
    func readsBrokenCountAsZero() async throws {
        let database = try AppDatabase.inMemory()

        try await database.writer.write { db in
            try db.execute(
                sql: "INSERT INTO setting (key, value) VALUES ('receipt_saved_count', '-3')"
            )
        }

        let count = try await database.setting(.receiptSavedCount)

        #expect(count == 0)
    }
}

private extension ReceiptWriteTests {
    func countText(in database: AppDatabase) async throws -> String? {
        try await database.writer.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT value FROM setting WHERE key = 'receipt_saved_count'"
            )
        }
    }
}
