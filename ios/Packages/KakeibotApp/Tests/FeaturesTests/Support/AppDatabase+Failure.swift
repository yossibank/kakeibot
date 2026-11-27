@testable import Store

extension AppDatabase {
    func failWrites(to table: String) async throws {
        try await writer.write { db in
            for event in ["INSERT", "UPDATE", "DELETE"] {
                try db.execute(
                    sql: """
                    CREATE TRIGGER fail_\(table)_\(event.lowercased()) BEFORE \(event) ON \(table)
                    BEGIN SELECT RAISE(ABORT, 'failing for tests'); END
                    """
                )
            }
        }
    }

    func failReads(of table: String) async throws {
        try await writer.write { db in
            try db.execute(sql: "DROP TABLE \(table)")
        }
    }

    func failUpdates(
        to table: String,
        changing column: String
    ) async throws {
        try await writer.write { db in
            try db.execute(
                sql: """
                CREATE TRIGGER fail_\(table)_\(column) BEFORE UPDATE ON \(table)
                WHEN NEW.\(column) IS NOT OLD.\(column)
                BEGIN SELECT RAISE(ABORT, 'failing for tests'); END
                """
            )
        }
    }

    func fillStorage() async throws {
        try await writer.writeWithoutTransaction { db in
            let pages = try Int.fetchOne(db, sql: "PRAGMA page_count") ?? 0
            try db.execute(sql: "PRAGMA max_page_count = \(pages)")
        }
    }
}
