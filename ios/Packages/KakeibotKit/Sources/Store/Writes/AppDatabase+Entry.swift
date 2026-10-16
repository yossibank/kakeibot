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

    func restoreEntry(_ entry: Entry) async throws {
        try await writer.write { db in
            var entry = entry

            if
                let templateId = entry.templateId,
                try !EntryTemplate.exists(db, key: templateId) {
                entry.templateId = nil
            }

            try entry.save(db)

            if entry.type == .expense {
                try NoSpendDay.deleteOne(db, key: entry.date)
            }
        }
    }

    func deleteEntry(_ id: Entry.ID) async throws {
        try await writer.write { db in
            _ = try Entry.deleteOne(db, key: id)
        }
    }
}

private extension AppDatabase {
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
