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
        _ draft: EntryCategoryDraft,
        tags: [EntryTagDraft],
        editing id: EntryCategory.ID? = nil,
        at now: Date
    ) async throws -> EntryCategory {
        try await writer.write { db in
            let category = if let id {
                try Self.updateIconBacked(id, with: draft, in: db, at: now)
            } else {
                try Self.insertIconBacked(draft, into: db, at: now)
            }

            try Self.saveTags(tags, for: category.id, in: db, at: now)

            return category
        }
    }

    func saveTags(
        _ drafts: [EntryTagDraft],
        for categoryId: EntryCategory.ID,
        at now: Date
    ) async throws -> [EntryTag] {
        try await writer.write { db in
            try Self.saveTags(drafts, for: categoryId, in: db, at: now)
        }
    }

    @discardableResult
    func deleteCategory(
        _ id: EntryCategory.ID,
        at now: Date
    ) async throws -> Deletion {
        try await writer.write { db in
            guard let category = try EntryCategory.fetchOne(db, key: id) else {
                throw CategoryWriteError.categoryNotFound
            }

            let column = Column("category_id")

            if try Entry.filter(column == id).fetchCount(db) > 0 {
                throw CategoryWriteError.hasEntries
            }

            let recurrings = Recurring.filter(column == id)
            let templates = EntryTemplate.filter(column == id)
            let budgets = Budget.filter(column == id)
            let tags = EntryTag.filter(column == id)
            let tagRecords = try tags.fetchAll(db)
            let recurringRecords = try recurrings.fetchAll(db)
            let templateRecords = try templates.fetchAll(db)
            let budgetRecords = try budgets.fetchAll(db)

            let deletion = Deletion(
                categories: [category],
                tags: tagRecords,
                recurrings: recurringRecords,
                templates: templateRecords,
                budgets: budgetRecords
            )

            try Self.deleteRecurrings(recurrings, in: db, at: now)
            try templates.deleteAll(db)
            try budgets.deleteAll(db)
            try tags.deleteAll(db)
            try category.delete(db)

            return deletion
        }
    }
}

private extension AppDatabase {
    @discardableResult
    static func saveTags(
        _ drafts: [EntryTagDraft],
        for categoryId: EntryCategory.ID,
        in db: Database,
        at now: Date
    ) throws -> [EntryTag] {
        let existing = try EntryTag.filter(Column("category_id") == categoryId).fetchAll(db)

        let names = drafts.map(\.name.trimmed)

        guard Set(names).count == names.count else {
            throw EntryTagDraft.Problem.duplicateName
        }

        var restorable = existing
            .filter { $0.archivedAt != nil }
            .sorted { ($0.createdAt, $0.id.description) < ($1.createdAt, $1.id.description) }

        let drafts = zip(drafts, names).map { draft, name in
            guard draft.id == nil else {
                return draft
            }

            let index = restorable.firstIndex { $0.name == name }

            guard let index else {
                return draft
            }

            var restored = draft

            restored.id = restorable.remove(at: index).id

            return restored
        }

        let keptIds = drafts.compactMap(\.id)
        let kept = Set(keptIds)

        for var tag in existing where !kept.contains(tag.id) {
            guard tag.archivedAt == nil else {
                continue
            }

            tag.archivedAt = now
            tag.updatedAt = now

            try tag.update(db)
        }

        return try drafts.enumerated().map { order, draft in
            guard let id = draft.id else {
                let tag = try draft.newTag(categoryId: categoryId, sortOrder: order, at: now)
                try tag.insert(db)
                return tag
            }

            guard let tag = existing.first(where: { $0.id == id }) else {
                throw CategoryWriteError.tagNotFound
            }

            let saved = try draft.applied(to: tag, sortOrder: order, at: now)

            try saved.update(db)

            return saved
        }
    }
}
