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

    func deleteTemplate(_ id: EntryTemplate.ID) async throws {
        try await writer.write { db in
            _ = try EntryTemplate.deleteOne(db, key: id)
        }
    }

    func reorderTemplates(
        _ ids: [EntryTemplate.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            for (order, id) in ids.enumerated() {
                let found = try EntryTemplate.fetchOne(db, key: id)

                guard var template = found else {
                    throw TemplateWriteError.templateNotFound
                }

                guard template.sortOrder != order else {
                    continue
                }

                template.sortOrder = order
                template.updatedAt = now
                try template.update(db)
            }
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
            let sortOrder = try nextTemplateOrder(in: db)
            return try draft.newTemplate(sortOrder: sortOrder, at: now)
        }

        guard let existing = try EntryTemplate.fetchOne(db, key: id) else {
            throw TemplateWriteError.templateNotFound
        }

        return try draft.applied(to: existing, at: now)
    }

    static func nextTemplateOrder(in db: Database) throws -> Int {
        let maxOrder = try EntryTemplate
            .select(max(Column("sort_order")), as: Int?.self)
            .fetchOne(db)

        return (maxOrder ?? nil).map { $0 + 1 } ?? 0
    }
}
