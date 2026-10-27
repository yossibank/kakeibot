import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum WidgetEntryError: Error, Equatable {
        case templateNotFound
        case amountMissing
    }

    @discardableResult
    func recordFromWidget(
        _ id: EntryTemplate.ID,
        on date: LocalDate,
        at now: Date
    ) async throws -> Entry {
        try await writer.write { db in
            guard let template = try EntryTemplate.fetchOne(db, key: id) else {
                throw WidgetEntryError.templateNotFound
            }

            guard let draft = try Self.entryDraft(for: template, on: date, in: db) else {
                throw WidgetEntryError.amountMissing
            }

            let saved = try Self.saveEntry(draft, editing: nil, in: db, at: now)

            let record = WidgetRecord(
                entryId: saved.entry.id,
                clearedNoSpendDate: saved.clearedNoSpendDays.first?.date
            )

            try Self.setSetting(.widgetEntry, to: record, in: db)

            return saved.entry
        }
    }

    func entryDraft(
        for template: EntryTemplate,
        on date: LocalDate
    ) async throws -> EntryDraft? {
        try await writer.read { db in
            try Self.entryDraft(for: template, on: date, in: db)
        }
    }

    func undoWidgetEntry(
        _ id: Entry.ID,
        at now: Date = Date()
    ) async throws {
        try await writer.write { db in
            _ = try Entry.deleteOne(db, key: id)

            guard let record = try Self.setting(.widgetEntry, in: db),
                  record.entryId == id
            else {
                return
            }

            let days = record.clearedNoSpendDate.map {
                [NoSpendDay(date: $0, createdAt: now)]
            } ?? []

            try Self.restoreNoSpendDays(days, in: db)
            try Self.setSetting(.widgetEntry, to: nil, in: db)
        }
    }
}

extension AppDatabase {
    static func entryDraft(
        for template: EntryTemplate,
        on date: LocalDate,
        in db: Database
    ) throws -> EntryDraft? {
        guard var draft = template.entryDraft(on: date) else {
            return nil
        }

        let tag = try draft.tagId.flatMap { try EntryTag.fetchOne(db, key: $0) }

        if tag?.archivedAt != nil {
            draft.tagId = nil
        }

        return draft
    }
}
