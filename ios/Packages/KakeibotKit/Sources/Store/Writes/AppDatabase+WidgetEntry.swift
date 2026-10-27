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

            guard let draft = template.entryDraft(on: date) else {
                throw WidgetEntryError.amountMissing
            }

            let entry = try Self.saveEntry(draft, editing: nil, in: db, at: now)

            try Self.setSetting(.widgetEntry, to: entry.id, in: db)

            return entry
        }
    }

    func undoWidgetEntry(
        _ id: Entry.ID,
        at now: Date = Date()
    ) async throws {
        try await writer.write { db in
            let entry = try Entry.fetchOne(db, key: id)

            _ = try Entry.deleteOne(db, key: id)

            if let entry {
                let change = CardBillChange(before: [entry])

                try Self.recalculateCardBills(change, in: db, at: now)
            }

            if try Self.setting(.widgetEntry, in: db) == id {
                try Self.setSetting(.widgetEntry, to: nil, in: db)
            }
        }
    }
}
