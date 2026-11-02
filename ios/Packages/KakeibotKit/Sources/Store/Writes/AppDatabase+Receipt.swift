import Core
import GRDB

public extension AppDatabase {
    func countReceiptSave() async throws {
        try await writer.write { db in
            let count = try Self.setting(.receiptSavedCount, in: db)
            try Self.setSetting(.receiptSavedCount, to: count + 1, in: db)
        }
    }
}
