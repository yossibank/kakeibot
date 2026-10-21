import Core
import GRDB

public extension AppDatabase {
    func restore(_ deletion: Deletion) async throws {
        try await writer.write { db in
            for record in deletion.records {
                try record.insert(db)
            }
        }
    }
}

private extension Deletion {
    var records: [any StoreRecord] {
        let tables: [[any StoreRecord]] = [
            wallets,
            categories,
            tags,
            recurrings,
            templates,
            budgets,
            valuations,
            shelfIcons
        ]

        return tables.flatMap(\.self)
    }
}
