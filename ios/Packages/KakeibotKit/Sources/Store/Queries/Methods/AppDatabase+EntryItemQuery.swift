import Core
import GRDB

public extension AppDatabase {
    func entryItems(of id: Entry.ID) async throws -> [EntryItem] {
        try await writer.read { db in
            try Self.entryItems(of: id, in: db)
        }
    }

    func entryItems(of ids: [Entry.ID]) async throws -> [EntryItem] {
        try await writer.read { db in
            try Self.entryItems(where: ids.contains(Column("entry_id")), in: db)
        }
    }

    func recentItemNames(limit: Int) async throws -> [String] {
        try await writer.read { db in
            try String.fetchAll(db, sql: Self.recentItemNamesSQL, arguments: [limit])
        }
    }

    func itemNames(at store: String) async throws -> [String: String] {
        try await writer.read { db in
            let names = try ItemName.filter(Column("store") == store).fetchAll(db)
            let pairs = names.map { ($0.raw, $0.name) }
            return Dictionary(pairs) { _, last in last }
        }
    }
}

extension AppDatabase {
    static func entryItems(
        where entries: some SQLSpecificExpressible,
        in db: Database
    ) throws -> [EntryItem] {
        try EntryItem
            .filter(entries)
            .order(Column("entry_id"), Column("sort_order"))
            .fetchAll(db)
    }

    static func entryItems(
        of id: Entry.ID,
        in db: Database
    ) throws -> [EntryItem] {
        try EntryItem
            .filter(Column("entry_id") == id)
            .order(Column("sort_order"), Column("created_at"))
            .fetchAll(db)
    }
}

private extension AppDatabase {
    static let recentItemNamesSQL = """
    SELECT name FROM entry_item
    WHERE amount > 0
    GROUP BY name
    ORDER BY MAX(updated_at) DESC
    LIMIT ?
    """
}
