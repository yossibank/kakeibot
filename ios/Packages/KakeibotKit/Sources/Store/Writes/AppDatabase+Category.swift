import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum CategoryWriteError: Error, Equatable {
        case categoryNotFound
        case iconNotFound
    }

    @discardableResult
    func saveCategory(
        _ draft: CategoryDraft,
        editing id: EntryCategory.ID? = nil,
        at now: Date
    ) async throws -> EntryCategory {
        try await writer.write { db in
            guard let id else {
                return try Self.insertCategory(draft, into: db, at: now)
            }

            return try Self.updateCategory(id, with: draft, in: db, at: now)
        }
    }

    func reorderCategories(
        _ ids: [EntryCategory.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            for (order, id) in ids.enumerated() {
                let found = try EntryCategory.fetchOne(db, key: id)

                guard var category = found else {
                    throw CategoryWriteError.categoryNotFound
                }

                guard category.sortOrder != order else {
                    continue
                }

                category.sortOrder = order
                category.updatedAt = now
                try category.update(db)
            }
        }
    }

    func setCategoryHidden(
        _ id: EntryCategory.ID,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var category = try EntryCategory.fetchOne(db, key: id) else {
                throw CategoryWriteError.categoryNotFound
            }

            category.archivedAt = isHidden ? now : nil
            category.updatedAt = now
            try category.update(db)
        }
    }
}

private extension AppDatabase {
    static func insertCategory(
        _ draft: CategoryDraft,
        into db: Database,
        at now: Date
    ) throws -> EntryCategory {
        let icon = try draft.newIcon(at: now)
        let sortOrder = try nextSortOrder(for: draft.kind, in: db)

        let category = try draft.newCategory(
            iconId: icon.id,
            sortOrder: sortOrder,
            at: now
        )

        try icon.insert(db)
        try category.insert(db)
        return category
    }

    static func updateCategory(
        _ id: EntryCategory.ID,
        with draft: CategoryDraft,
        in db: Database,
        at now: Date
    ) throws -> EntryCategory {
        guard let existing = try EntryCategory.fetchOne(db, key: id) else {
            throw CategoryWriteError.categoryNotFound
        }

        guard let icon = try Icon.fetchOne(db, key: existing.iconId) else {
            throw CategoryWriteError.iconNotFound
        }

        let category = try draft.applied(to: existing, at: now)
        try draft.applied(to: icon, at: now).update(db)
        try category.update(db)
        return category
    }

    static func nextSortOrder(
        for kind: EntryCategory.Kind,
        in db: Database
    ) throws -> Int {
        let maxOrder = try EntryCategory
            .filter(Column("kind") == kind.rawValue)
            .select(max(Column("sort_order")), as: Int?.self)
            .fetchOne(db)

        return (maxOrder ?? nil).map { $0 + 1 } ?? 0
    }
}
