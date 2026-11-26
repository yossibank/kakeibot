import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum TemplateWriteError: Error, Equatable {
        case templateNotFound
        case tagMismatch
    }
}

public extension AppDatabase {
    @discardableResult
    func saveTemplate(
        _ draft: EntryTemplateDraft,
        editing id: EntryTemplate.ID? = nil,
        at now: Date
    ) async throws -> EntryTemplate {
        try await writer.write { db in
            let template = try Self.template(from: draft, editing: id, in: db, at: now)

            guard try Self.tag(template.tagId, belongsTo: template.categoryId, in: db) else {
                throw TemplateWriteError.tagMismatch
            }

            try template.save(db)

            return template
        }
    }

    @discardableResult
    func deleteTemplate(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await writer.write { db in
            let templates = EntryTemplate.filter(id: id)
            let entries = Entry.filter(Column("template_id") == id)
            let templateRecords = try templates.fetchAll(db)
            let entryRecords = try entries.fetchAll(db)
            let deletion = Deletion(templates: templateRecords, entries: entryRecords)

            try templates.deleteAll(db)

            return deletion
        }
    }
}

private extension AppDatabase {
    static func template(
        from draft: EntryTemplateDraft,
        editing id: EntryTemplate.ID?,
        in db: Database,
        at now: Date
    ) throws -> EntryTemplate {
        guard let id else {
            let sortOrder = try EntryTemplate.nextSortOrder(in: db)
            return try draft.newTemplate(sortOrder: sortOrder, at: now)
        }

        guard let existing = try EntryTemplate.fetchOne(db, key: id) else {
            throw TemplateWriteError.templateNotFound
        }

        return try draft.applied(to: existing, at: now)
    }
}
