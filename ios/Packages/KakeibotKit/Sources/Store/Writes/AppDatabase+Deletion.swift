import Core
import GRDB

public extension AppDatabase {
    func restore(_ deletion: Deletion) async throws {
        try await writer.write { db in
            for record in deletion.records {
                try record.insert(db)
            }

            for entry in deletion.entries {
                try entry.update(db)
            }
        }
    }
}

extension AppDatabase {
    @discardableResult
    static func deleteRecurrings(
        _ recurrings: QueryInterfaceRequest<Recurring>,
        in db: Database
    ) throws -> Deletion {
        let deleted = try recurrings.fetchAll(db)
        let ids = deleted.map(\.id)
        let linked = Entry.filter(ids.contains(Column("recurring_id")))
        let entries = try linked.fetchAll(db)

        try linked.updateAll(
            db,
            Column("recurring_id").set(to: nil),
            Column("recurring_date").set(to: nil)
        )

        try recurrings.deleteAll(db)
        return Deletion(recurrings: deleted, entries: entries)
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
            shelfIcons,
            rewardRules,
            rewardLogs
        ]

        return tables.flatMap(\.self)
    }
}
