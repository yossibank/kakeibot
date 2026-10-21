import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum TemplateWriteError: Error, Equatable {
        case templateNotFound
        case tagMismatch
    }

    @discardableResult
    func saveTemplate(
        _ draft: EntryTemplateDraft,
        editing id: EntryTemplate.ID? = nil,
        at now: Date
    ) async throws -> EntryTemplate {
        try await writer.write { db in
            let template = try Self.template(
                from: draft,
                editing: id,
                in: db,
                at: now
            )

            let belongs = try Self.tag(
                template.tagId,
                belongsTo: template.categoryId,
                in: db
            )

            guard belongs else {
                throw TemplateWriteError.tagMismatch
            }

            try template.save(db)
            return template
        }
    }

    func setTemplateHidden(
        _ id: EntryTemplate.ID,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var template = try EntryTemplate.fetchOne(db, key: id) else {
                throw TemplateWriteError.templateNotFound
            }

            template.archivedAt = isHidden ? now : nil
            template.updatedAt = now
            try template.update(db)
        }
    }

    @discardableResult
    func deleteTemplate(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await writer.write { db in
            let templates = EntryTemplate.filter(id: id)
            let entries = Entry.filter(Column("template_id") == id)

            let deletion = try Deletion(
                templates: templates.fetchAll(db),
                entries: entries.fetchAll(db)
            )

            try templates.deleteAll(db)
            return deletion
        }
    }

    func reorderTemplates(
        _ ids: [EntryTemplate.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try EntryTemplate.reorder(
                ids,
                orThrow: TemplateWriteError.templateNotFound,
                in: db,
                at: now
            )
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
