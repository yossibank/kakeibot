import Core
import Foundation
import GRDB

public extension AppDatabase {
    func restore(_ deletion: Deletion) async throws {
        try await writer.write { db in
            for record in deletion.records {
                try record.insert(db)
            }

            for entry in deletion.entries where try Entry.exists(db, key: entry.id) {
                try entry.update(db)
            }

            if let choice = deletion.themeChoice {
                try Self.setSetting(.theme, to: choice, in: db)
            }
        }
    }
}

extension AppDatabase {
    @discardableResult
    static func deleteRecurrings(
        _ recurrings: QueryInterfaceRequest<Recurring>,
        in db: Database,
        at now: Date
    ) throws -> Deletion {
        let deleted = try recurrings.fetchAll(db)
        let ids = deleted.map(\.id)
        let linked = Entry.filter(ids.contains(Column("recurring_id")))
        let entries = try linked.fetchAll(db)

        try linked.updateAll(
            db,
            Column("recurring_id").set(to: nil),
            Column("recurring_date").set(to: nil),
            Column("updated_at").set(to: now.formatted(.iso8601))
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
            rewardLogs,
            themes
        ]

        return tables.flatMap(\.self)
    }
}
