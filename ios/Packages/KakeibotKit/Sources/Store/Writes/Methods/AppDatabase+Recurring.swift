import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum RecurringWriteError: Error, Equatable {
        case recurringNotFound
    }

    @discardableResult
    func saveRecurring(
        _ draft: RecurringDraft,
        editing id: Recurring.ID? = nil,
        today: LocalDate,
        at now: Date
    ) async throws -> Recurring {
        try await writer.write { db in
            var change = CardBillChange()
            var recurring: Recurring

            if let id {
                guard let current = try Recurring.fetchOne(db, key: id) else {
                    throw RecurringWriteError.recurringNotFound
                }

                recurring = try draft.applied(to: current, at: now)

                try recurring.update(db)

                try Self.generateEarlierEntries(
                    of: recurring,
                    before: current.startDate,
                    through: today,
                    change: &change,
                    in: db,
                    at: now
                )
            } else {
                recurring = try draft.newRecurring(at: now)
                recurring.sortOrder = try Recurring.nextSortOrder(in: db)
                try recurring.insert(db)
            }

            try Self.generateEntries(
                of: recurring,
                through: today,
                change: &change,
                in: db,
                at: now
            )

            try Self.recalculateCardBills(change, in: db, at: now)

            return try Recurring.fetchOne(db, key: recurring.id) ?? recurring
        }
    }

    func setRecurringHidden(
        _ id: Recurring.ID,
        isHidden: Bool,
        today: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var recurring = try Recurring.fetchOne(db, key: id) else {
                throw RecurringWriteError.recurringNotFound
            }

            recurring.archivedAt = isHidden ? now : nil
            recurring.updatedAt = now

            if !isHidden {
                let yesterday = today.adding(days: -1)
                let generated = recurring.generatedUntil ?? yesterday
                recurring.generatedUntil = max(generated, yesterday)
            }

            try recurring.update(db)

            var change = CardBillChange()

            try Self.generateEntries(
                of: recurring,
                through: today,
                change: &change,
                in: db,
                at: now
            )

            try Self.recalculateCardBills(change, in: db, at: now)
        }
    }

    @discardableResult
    func deleteRecurring(
        _ id: Recurring.ID,
        at now: Date
    ) async throws -> Deletion {
        try await writer.write { db in
            let recurrings = Recurring.filter(id: id)

            return try Self.deleteRecurrings(recurrings, in: db, at: now)
        }
    }

    func reorderRecurrings(
        _ ids: [Recurring.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try Recurring.reorder(
                ids,
                orThrow: RecurringWriteError.recurringNotFound,
                in: db,
                at: now
            )
        }
    }

    @discardableResult
    func recordRecurring(
        _ id: Recurring.ID,
        on date: LocalDate,
        at now: Date
    ) async throws -> Entry? {
        try await writer.write { db in
            guard let recurring = try Recurring.fetchOne(db, key: id) else {
                return nil
            }

            let occurrence = recurring.occurrence(on: date)

            var change = CardBillChange()

            let entry = try Self.generateEntry(
                of: recurring,
                on: occurrence,
                change: &change,
                in: db,
                at: now
            )

            try Self.recalculateCardBills(change, in: db, at: now)

            return entry
        }
    }

    func generateRecurringEntries(
        through today: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            var change = CardBillChange()

            for recurring in try Recurring.fetchAll(db) {
                try Self.generateEntries(
                    of: recurring,
                    through: today,
                    change: &change,
                    in: db,
                    at: now
                )
            }

            try Self.recalculateCardBills(change, in: db, at: now)
        }
    }
}

extension AppDatabase {
    @discardableResult
    static func insertEntry(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        in db: Database,
        at now: Date
    ) throws -> Entry? {
        let date = occurrence.date
        let earliest = occurrence.scheduled.adding(days: -40)
        let latest = occurrence.scheduled.adding(days: 40)

        let exists = try Entry
            .filter(Column("recurring_id") == recurring.id)
            .filter(Column("recurring_date") >= earliest)
            .filter(Column("recurring_date") <= latest)
            .fetchAll(db)
            .contains { recurring.isRecorded(by: $0, scheduled: occurrence.scheduled) }

        let amount = try billAmount(of: recurring, on: occurrence, in: db)

        guard
            !exists,
            amount > 0
        else {
            return nil
        }

        let billMonth = try billMonth(
            paidBy: recurring.walletId,
            type: recurring.type,
            on: date,
            shift: recurring.billShift,
            in: db
        )

        var entry = Entry(
            type: recurring.type,
            amount: amount,
            date: date,
            categoryId: recurring.categoryId,
            walletId: recurring.walletId,
            toWalletId: recurring.toWalletId,
            memo: recurring.memo,
            recurringId: recurring.id,
            recurringDate: occurrence.scheduled,
            billMonth: billMonth,
            createdAt: now,
            updatedAt: now
        )

        try fitCategory(of: &entry, in: db)
        try prepareSharedTransfer(entry, in: db, at: now)
        try entry.insert(db)

        if entry.type == .expense {
            try NoSpendDay.deleteOne(db, key: date)
        }

        try saveFee(recurring.fee ?? 0, for: entry, in: db, at: now)

        return entry
    }

    static func billAmount(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        in db: Database
    ) throws -> Int {
        guard
            recurring.billingPeriod(paidOn: occurrence.date) != nil,
            recurring.toWalletId != nil
        else {
            return recurring.amount
        }

        let entries = try billEntries(of: recurring, on: occurrence, in: db)

        return recurring.amount(paidOn: occurrence.date, entries: entries)
    }

    static func billEntries(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        in db: Database
    ) throws -> [Entry] {
        guard
            let period = recurring.billingPeriod(paidOn: occurrence.date),
            let card = recurring.toWalletId
        else {
            return []
        }

        let inPeriod = Column("date") >= period.lowerBound
            && Column("date") <= period.upperBound

        return try Entry
            .filter(Column("wallet_id") == card)
            .filter(inPeriod || Column("bill_month") == occurrence.scheduled.yearMonth)
            .fetchAll(db)
    }
}

private extension AppDatabase {
    static func generateEntries(
        of recurring: Recurring,
        through today: LocalDate,
        change: inout CardBillChange,
        in db: Database,
        at now: Date
    ) throws {
        let occurrences = recurring.archivedAt == nil
            ? recurring.pendingOccurrences(through: today)
            : []

        for occurrence in occurrences {
            try generateEntry(of: recurring, on: occurrence, change: &change, in: db, at: now)
        }

        guard recurring.startDate <= today else {
            return
        }

        var updated = recurring

        _ = try updated.updateChanges(db) {
            $0.generatedUntil = today
        }
    }

    static func generateEarlierEntries(
        of recurring: Recurring,
        before previousStart: LocalDate,
        through today: LocalDate,
        change: inout CardBillChange,
        in db: Database,
        at now: Date
    ) throws {
        guard
            recurring.archivedAt == nil,
            recurring.startDate < previousStart
        else {
            return
        }

        let dayBefore = previousStart.adding(days: -1)
        let last = min(dayBefore, today)

        for occurrence in recurring.occurrences(from: recurring.startDate, through: last) {
            try generateEntry(of: recurring, on: occurrence, change: &change, in: db, at: now)
        }
    }

    @discardableResult
    static func generateEntry(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        change: inout CardBillChange,
        in db: Database,
        at now: Date
    ) throws -> Entry? {
        let entry = try insertEntry(of: recurring, on: occurrence, in: db, at: now)

        if let entry {
            change.after.append(entry)

            if let fee = try fee(of: entry.id, in: db) {
                change.after.append(fee)
            }
        }

        return entry
    }
}
