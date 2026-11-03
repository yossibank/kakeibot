import Core
import Foundation
import GRDB

public extension AppDatabase {
    func restoreEntry(
        _ entry: Entry,
        fee: Entry? = nil,
        items: [EntryItem]? = nil,
        restoringNoSpend days: [NoSpendDay] = [],
        at now: Date = Date()
    ) async throws {
        try await writer.write { db in
            let restored = [entry] + [fee].compactMap(\.self)

            var change = CardBillChange()

            change.before = try Self.existingRows(of: restored, in: db)
            change.after = restored

            try Self.restore([entry], in: db, at: now)
            try Self.restoreItems(items, of: [entry.id], in: db)

            _ = try Entry
                .filter(Column("transfer_id") == entry.id)
                .filter(Column("id") != fee?.id)
                .deleteAll(db)

            if let fee {
                try Self.restore([fee], in: db, at: now)
            }

            try Self.restoreNoSpendDays(days, in: db)
            try Self.recalculateCardBills(change, in: db, at: now)
        }
    }

    func restoreEntries(
        _ entries: [Entry],
        items: [EntryItem]? = nil,
        at now: Date = Date()
    ) async throws {
        try await writer.write { db in
            var change = CardBillChange()

            change.before = try Self.existingRows(of: entries, in: db)
            change.after = entries

            try Self.restore(entries, in: db, at: now)
            try Self.restoreItems(items, of: entries.map(\.id), in: db)
            try Self.recalculateCardBills(change, in: db, at: now)
        }
    }
}

extension AppDatabase {
    static func restoreNoSpendDays(
        _ days: [NoSpendDay],
        in db: Database
    ) throws {
        for day in days {
            let expenses = try Entry
                .filter(Column("date") == day.date)
                .filter(Column("type") == Entry.Kind.expense)
                .fetchCount(db)

            if expenses == 0 {
                try day.save(db)
            }
        }
    }
}

private extension AppDatabase {
    static func restore(
        _ entries: [Entry],
        in db: Database,
        at now: Date
    ) throws {
        let ordered = entries.filter { $0.transferId == nil }
            + entries.filter { $0.transferId != nil }

        for var entry in ordered {
            try removeRecordedDuplicates(of: entry, in: db)

            if let templateId = entry.templateId,
               try !EntryTemplate.exists(db, key: templateId) {
                entry.templateId = nil
            }

            if let transferId = entry.transferId,
               try !Entry.exists(db, key: transferId) {
                entry.transferId = nil
            }

            let existing = try Entry.fetchOne(db, key: entry.id)

            try entry.save(db)

            if let existing,
               existing.walletId != entry.walletId || existing.toWalletId != entry.toWalletId {
                try touchItems(of: [entry.id], in: db, at: now)
            }

            if entry.type == .expense {
                try clearNoSpendDay(on: entry.date, in: db)
            }
        }
    }

    static func removeRecordedDuplicates(
        of entry: Entry,
        in db: Database
    ) throws {
        guard let sameRecurrence = Entry.sameRecurrence(as: entry) else {
            return
        }

        let duplicates = sameRecurrence.filter(Column("id") != entry.id)
        let ids = try duplicates.fetchAll(db).map(\.id)

        _ = try Entry.filter(ids.contains(Column("transfer_id"))).deleteAll(db)
        _ = try duplicates.deleteAll(db)
    }
}
