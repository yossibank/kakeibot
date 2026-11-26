import Core
import Foundation
import GRDB

public extension AppDatabase {
    func rememberItemName(
        _ name: String,
        for raw: String,
        at store: String,
        on now: Date
    ) async throws {
        let name = name.trimmed

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

    func forgetItemName(
        for raw: String,
        at store: String
    ) async throws {
        try await writer.write { db in
            _ = try ItemName
                .filter(Column("store") == store)
                .filter(Column("raw") == raw)
                .deleteAll(db)
        }
    }
}

extension AppDatabase {
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
                taxRate: draft.taxRate,
                sortOrder: index,
                createdAt: now,
                updatedAt: now
            )

            item.name = draft.trimmedName
            item.quantity = draft.quantity
            item.amount = draft.amount
            item.taxRate = draft.taxRate
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
