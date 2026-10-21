import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum CategoryWriteError: Error, Equatable {
        case categoryNotFound
        case iconNotFound
        case tagNotFound
        case hasEntries
    }

    @discardableResult
    func saveCategory(
        _ draft: CategoryDraft,
        tags: [EntryTagDraft],
        editing id: EntryCategory.ID? = nil,
        at now: Date
    ) async throws -> EntryCategory {
        try await writer.write { db in
            let category = if let id {
                try Self.updateCategory(id, with: draft, in: db, at: now)
            } else {
                try Self.insertCategory(draft, into: db, at: now)
            }

            try Self.saveTags(tags, for: category.id, in: db, at: now)
            return category
        }
    }

    func reorderCategories(
        _ ids: [EntryCategory.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try EntryCategory.reorder(
                ids,
                orThrow: CategoryWriteError.categoryNotFound,
                in: db,
                at: now
            )
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

    func deleteCategory(_ id: EntryCategory.ID) async throws {
        try await writer.write { db in
            guard let category = try EntryCategory.fetchOne(db, key: id) else {
                throw CategoryWriteError.categoryNotFound
            }

            let column = Column("category_id")

            if try Entry.filter(column == id).fetchCount(db) > 0 {
                throw CategoryWriteError.hasEntries
            }

            try Self.deleteRecurrings(
                Recurring.filter(column == id),
                in: db
            )

            try EntryTemplate.filter(column == id).deleteAll(db)
            try Budget.filter(column == id).deleteAll(db)
            try EntryTag.filter(column == id).deleteAll(db)
            try category.delete(db)
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

        let sameKind = EntryCategory
            .filter(Column("kind") == draft.kind.rawValue)

        let sortOrder = try EntryCategory.nextSortOrder(of: sameKind, in: db)

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

    static func saveTags(
        _ drafts: [EntryTagDraft],
        for categoryId: EntryCategory.ID,
        in db: Database,
        at now: Date
    ) throws {
        let existing = try EntryTag
            .filter(Column("category_id") == categoryId)
            .fetchAll(db)

        let kept = Set(drafts.compactMap(\.id))

        for var tag in existing where !kept.contains(tag.id) {
            guard tag.archivedAt == nil else {
                continue
            }

            tag.archivedAt = now
            tag.updatedAt = now
            try tag.update(db)
        }

        for (order, draft) in drafts.enumerated() {
            guard let id = draft.id else {
                let tag = try draft.newTag(
                    categoryId: categoryId,
                    sortOrder: order,
                    at: now
                )

                try tag.insert(db)
                continue
            }

            guard let tag = existing.first(where: { $0.id == id }) else {
                throw CategoryWriteError.tagNotFound
            }

            try draft.applied(to: tag, sortOrder: order, at: now).update(db)
        }
    }
}
