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
        try await saveEntryResult(draft, editing: id, at: now).entry
    }

    func saveEntryResult(
        _ draft: EntryDraft,
        editing id: Entry.ID? = nil,
        at now: Date
    ) async throws -> SavedEntry {
        try await writer.write { db in
            try Self.saveEntry(draft, editing: id, in: db, at: now)
        }
    }

    func saveEntries(
        _ drafts: [EntryDraft],
        at now: Date
    ) async throws {
        try await writer.write { db in
            for draft in drafts {
                try Self.saveEntry(draft, editing: nil, in: db, at: now)
            }
        }
    }

    func fee(of id: Entry.ID) async throws -> Entry? {
        try await writer.read { db in
            try Self.fee(of: id, in: db)
        }
    }

    func restoreEntry(
        _ entry: Entry,
        fee: Entry? = nil,
        restoringNoSpend days: [NoSpendDay] = []
    ) async throws {
        try await writer.write { db in
            try Self.restore([entry], in: db)

            _ = try Entry
                .filter(Column("transfer_id") == entry.id)
                .filter(Column("id") != fee?.id)
                .deleteAll(db)

            if let fee {
                try Self.restore([fee], in: db)
            }

            try Self.restoreNoSpendDays(days, in: db)
        }
    }

    func restoreEntries(_ entries: [Entry]) async throws {
        try await writer.write { db in
            try Self.restore(entries, in: db)
        }
    }

    @discardableResult
    func deleteEntry(
        _ id: Entry.ID,
        restoringNoSpend days: [NoSpendDay] = []
    ) async throws -> [Entry] {
        try await deleteEntries([id], restoringNoSpend: days)
    }

    func deleteEntries(
        _ ids: [Entry.ID],
        restoringNoSpend days: [NoSpendDay] = []
    ) async throws -> [Entry] {
        try await writer.write { db in
            let entries = try Entry.fetchAll(db, keys: ids)

            let fees = try Entry
                .filter(ids.contains(Column("transfer_id")))
                .filter(!ids.contains(Column("id")))
                .fetchAll(db)

            _ = try Entry.deleteAll(db, keys: ids)

            try Self.restoreNoSpendDays(days, in: db)

            return entries + fees
        }
    }

    func changeEntries(
        _ ids: [Entry.ID],
        to change: EntryBatchChange,
        at now: Date
    ) async throws -> [Entry] {
        try await writer.write { db in
            let entries = try Entry.fetchAll(db, keys: ids)
                .filter { $0.type != .transfer }

            let changed = try entries.filter { entry in
                try Self.canChange(entry, to: change, in: db)
            }

            for var entry in changed {
                switch change {
                case let .category(id):
                    entry.categoryId = id
                    entry.tagId = nil
                case let .wallet(id):
                    entry.walletId = id
                    entry.billMonth = nil
                }

                entry.updatedAt = now

                try entry.update(db)
            }

            return changed
        }
    }
}

extension AppDatabase {
    @discardableResult
    static func saveEntry(
        _ draft: EntryDraft,
        editing id: Entry.ID?,
        in db: Database,
        at now: Date
    ) throws -> SavedEntry {
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

        var cleared: [NoSpendDay] = []

        if entry.type == .expense {
            cleared += try clearNoSpendDay(on: entry.date, in: db)
        }

        cleared += try saveFee(draft.fee, for: entry, in: db, at: now)

        return SavedEntry(entry: entry, clearedNoSpendDays: cleared)
    }

    @discardableResult
    static func clearNoSpendDay(
        on date: LocalDate,
        in db: Database
    ) throws -> [NoSpendDay] {
        guard let day = try NoSpendDay.fetchOne(db, key: date) else {
            return []
        }

        _ = try NoSpendDay.deleteOne(db, key: date)

        return [day]
    }

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

    static func fee(
        of id: Entry.ID,
        in db: Database
    ) throws -> Entry? {
        try Entry
            .filter(Column("transfer_id") == id)
            .fetchOne(db)
    }

    @discardableResult
    static func saveFee(
        _ amount: Int,
        for transfer: Entry,
        in db: Database,
        at now: Date
    ) throws -> [NoSpendDay] {
        let existing = try fee(of: transfer.id, in: db)

        guard
            transfer.type == .transfer,
            amount > 0
        else {
            try existing?.delete(db)
            return []
        }

        var fee = try existing ?? Entry(
            type: .expense,
            amount: amount,
            date: transfer.date,
            categoryId: feeCategoryId(in: db, at: now),
            walletId: transfer.walletId,
            transferId: transfer.id,
            createdAt: now,
            updatedAt: now
        )

        fee.amount = amount
        fee.date = transfer.date
        fee.walletId = transfer.walletId
        fee.billMonth = nil
        fee.updatedAt = now

        try fee.save(db)

        return try clearNoSpendDay(on: fee.date, in: db)
    }
}

private extension AppDatabase {
    static func restore(
        _ entries: [Entry],
        in db: Database
    ) throws {
        let ordered = entries.filter { $0.transferId == nil }
            + entries.filter { $0.transferId != nil }

        for var entry in ordered {
            if let templateId = entry.templateId,
               try !EntryTemplate.exists(db, key: templateId) {
                entry.templateId = nil
            }

            if let transferId = entry.transferId,
               try !Entry.exists(db, key: transferId) {
                entry.transferId = nil
            }

            try entry.save(db)

            if entry.type == .expense {
                try clearNoSpendDay(on: entry.date, in: db)
            }
        }
    }

    static func canChange(
        _ entry: Entry,
        to change: EntryBatchChange,
        in db: Database
    ) throws -> Bool {
        switch change {
        case let .category(id):
            let category = try EntryCategory.fetchOne(db, key: id)

            return category?.kind.rawValue == entry.type.rawValue
        case let .wallet(id):
            return try entry.transferId == nil && Wallet.exists(db, key: id)
        }
    }

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
