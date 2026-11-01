import Core
import Foundation
import GRDB

public extension AppDatabase {
    func entryItems(of id: Entry.ID) async throws -> [EntryItem] {
        try await writer.read { db in
            try Self.entryItems(of: id, in: db)
        }
    }

    func entryItems(of ids: [Entry.ID]) async throws -> [EntryItem] {
        try await writer.read { db in
            try EntryItem
                .filter(ids.contains(Column("entry_id")))
                .order(Column("entry_id"), Column("sort_order"))
                .fetchAll(db)
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

    func rememberItemName(
        _ name: String,
        for raw: String,
        at store: String,
        on now: Date
    ) async throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            return
        }

        try await writer.write { db in
            let existing = try ItemName
                .filter(Column("store") == store)
                .filter(Column("raw") == raw)
                .fetchOne(db)

            var item = existing ?? ItemName(
                store: store,
                raw: raw,
                name: name,
                createdAt: now,
                updatedAt: now
            )

            guard existing == nil || item.name != name else {
                return
            }

            item.name = name
            item.updatedAt = now

            try item.save(db)
        }
    }
}

extension AppDatabase {
    static func entryItems(
        of id: Entry.ID,
        in db: Database
    ) throws -> [EntryItem] {
        try EntryItem
            .filter(Column("entry_id") == id)
            .order(Column("sort_order"), Column("created_at"))
            .fetchAll(db)
    }

    static func saveItems(
        _ drafts: [EntryItem.Draft]?,
        of entry: Entry,
        before: Entry?,
        in db: Database,
        at now: Date
    ) throws {
        let existing = try entryItems(of: entry.id, in: db)

        guard entry.type != .transfer else {
            _ = try EntryItem.deleteAll(db, keys: existing.map(\.id))
            return
        }

        if let drafts {
            try replaceItems(existing, with: drafts, of: entry.id, in: db, at: now)
        }

        if let before,
           before.walletId != entry.walletId || before.toWalletId != entry.toWalletId {
            try touchItems(of: [entry.id], in: db, at: now)
        }
    }

    static func restoreItems(
        _ items: [EntryItem]?,
        of ids: [Entry.ID],
        in db: Database
    ) throws {
        guard let items else {
            return
        }

        let keptIDs = items.map(\.id)

        _ = try EntryItem
            .filter(ids.contains(Column("entry_id")))
            .filter(!keptIDs.contains(Column("id")))
            .deleteAll(db)

        for item in items where try Entry.exists(db, key: item.entryId) {
            try item.save(db)
        }
    }

    static func touchItems(
        of ids: [Entry.ID],
        in db: Database,
        at now: Date
    ) throws {
        let updatedAt = now.formatted(.iso8601)

        try EntryItem
            .filter(ids.contains(Column("entry_id")))
            .updateAll(db, Column("updated_at").set(to: updatedAt))
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

    static func replaceItems(
        _ existing: [EntryItem],
        with drafts: [EntryItem.Draft],
        of entryID: Entry.ID,
        in db: Database,
        at now: Date
    ) throws {
        for (index, draft) in drafts.enumerated() {
            let old = existing.indices.contains(index) ? existing[index] : nil

            var item = old ?? EntryItem(
                entryId: entryID,
                name: draft.trimmedName,
                quantity: draft.quantity,
                amount: draft.amount,
                sortOrder: index,
                createdAt: now,
                updatedAt: now
            )

            item.name = draft.trimmedName
            item.quantity = draft.quantity
            item.amount = draft.amount
            item.sortOrder = index

            guard item != old else {
                continue
            }

            item.updatedAt = now

            try item.save(db)
        }

        let removed = existing.dropFirst(drafts.count).map(\.id)

        _ = try EntryItem.deleteAll(db, keys: removed)
    }
}
