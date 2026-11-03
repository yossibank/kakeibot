import GRDB

extension AppDatabase {
    static func conflictLosers(
        against record: SyncRecord,
        columns: Set<String>,
        in db: Database
    ) throws -> [String]? {
        let table = record.key.table
        let created = columns.contains("created_at") ? "created_at" : "NULL"
        var losers: [String] = []

        for unique in table.uniqueKeys {
            let values = unique.columns.map { record.values[$0] ?? .null }

            guard unique.matchesNull || !values.contains(.null) else {
                continue
            }

            let conditions = unique.columns.map { "\($0) IS ?" }.joined(separator: " AND ")
            let databaseValues = values.map(\.databaseValue) + [record.key.id.databaseValue]
            let arguments = StatementArguments(databaseValues)

            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT \(table.keyColumn) AS id, \(created) AS created_at FROM \(table.rawValue)
                WHERE \(conditions) AND \(table.keyColumn) <> ?
                """,
                arguments: arguments
            )

            for row in rows {
                let id: String = row["id"]
                let createdAt: String? = row["created_at"]

                guard record.wins(over: id, createdAt: createdAt) else {
                    return nil
                }

                losers.append(id)
            }
        }

        return losers
    }

    static func remove(
        _ ids: [String],
        of table: SyncTable,
        in db: Database
    ) throws {
        guard !ids.isEmpty else {
            return
        }

        try setApplying(false, in: db)

        for id in ids {
            try db.execute(
                sql: "DELETE FROM \(table.rawValue) WHERE \(table.keyColumn) = ?",
                arguments: [id]
            )
        }

        try setApplying(true, in: db)
    }
}

private extension SyncRecord {
    func wins(
        over id: String,
        createdAt: String?
    ) -> Bool {
        if case let .text(incoming) = values["created_at"],
           let createdAt,
           incoming != createdAt {
            return incoming < createdAt
        }

        return key.id < id
    }
}
