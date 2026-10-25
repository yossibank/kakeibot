import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum WriteError: Error, Equatable {
        case entryNotFound
        case tagMismatch
    }

    @discardableResult
    func saveEntry(
        _ draft: EntryDraft,
        editing id: Entry.ID? = nil,
        at now: Date
    ) async throws -> Entry {
        try await writer.write { db in
            try Self.saveEntry(draft, editing: id, in: db, at: now)
        }
    }

    func saveEntries(
        _ drafts: [EntryDraft],
        at now: Date
    ) async throws {
        try await writer.write { db in
            for draft in drafts {
                try Self.saveEntry(draft, editing: nil, in: db, at: now)
            }
        }
    }

    func restoreEntry(_ entry: Entry) async throws {
        try await restoreEntries([entry])
    }

    func restoreEntries(_ entries: [Entry]) async throws {
        try await writer.write { db in
            for var entry in entries {
                if let templateId = entry.templateId,
                   try !EntryTemplate.exists(db, key: templateId) {
                    entry.templateId = nil
                }

                try entry.save(db)

                if entry.type == .expense {
                    try NoSpendDay.deleteOne(db, key: entry.date)
                }
            }
        }
    }

    func deleteEntry(_ id: Entry.ID) async throws {
        try await writer.write { db in
            _ = try Entry.deleteOne(db, key: id)
        }
    }

    func deleteEntries(_ ids: [Entry.ID]) async throws -> [Entry] {
        try await writer.write { db in
            let entries = try Entry.fetchAll(db, keys: ids)

            _ = try Entry.deleteAll(db, keys: ids)

            return entries
        }
    }

    func changeEntries(
        _ ids: [Entry.ID],
        to change: EntryBatchChange,
        at now: Date
    ) async throws -> [Entry] {
        try await writer.write { db in
            let entries = try Entry.fetchAll(db, keys: ids)
                .filter { $0.type != .transfer }

            let changed = try entries.filter { entry in
                try Self.canChange(entry, to: change, in: db)
            }

            for var entry in changed {
                switch change {
                case let .category(id):
                    entry.categoryId = id
                    entry.tagId = nil
                case let .wallet(id):
                    entry.walletId = id
                    entry.billMonth = nil
                }

                entry.updatedAt = now

                try entry.update(db)
            }

            return changed
        }
    }
}

extension AppDatabase {
    @discardableResult
    static func saveEntry(
        _ draft: EntryDraft,
        editing id: Entry.ID?,
        in db: Database,
        at now: Date
    ) throws -> Entry {
        let entry = try Self.entry(
            from: draft,
            editing: id,
            in: db,
            at: now
        )

        let belongs = try Self.tag(
            entry.tagId,
            belongsTo: entry.categoryId,
            in: db
        )

        guard belongs else {
            throw WriteError.tagMismatch
        }

        try entry.save(db)

        if entry.type == .expense {
            try NoSpendDay.deleteOne(db, key: entry.date)
        }

        return entry
    }
}

private extension AppDatabase {
    static func canChange(
        _ entry: Entry,
        to change: EntryBatchChange,
        in db: Database
    ) throws -> Bool {
        switch change {
        case let .category(id):
            let category = try EntryCategory.fetchOne(db, key: id)

            return category?.kind.rawValue == entry.type.rawValue
        case let .wallet(id):
            return try Wallet.exists(db, key: id)
        }
    }

    static func entry(
        from draft: EntryDraft,
        editing id: Entry.ID?,
        in db: Database,
        at now: Date
    ) throws -> Entry {
        guard let id else {
            return try draft.newEntry(at: now)
        }

        guard let existing = try Entry.fetchOne(db, key: id) else {
            throw WriteError.entryNotFound
        }

        return try draft.applied(to: existing, at: now)
    }
}
