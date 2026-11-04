import Core
import Foundation
import GRDB

struct CardBillChange {
    var before: [Entry] = []
    var after: [Entry] = []
}

extension AppDatabase {
    static func recalculateCardBills(
        _ change: CardBillChange,
        in db: Database,
        at now: Date,
        visited: Set<Recurring.ID> = []
    ) throws {
        let changed = change.before + change.after
        let walletIds = changed.map(\.walletId)
        let cards = Set(walletIds)

        guard !cards.isEmpty else {
            return
        }

        let recurrings = try Recurring
            .filter(Column("closing_day") != nil)
            .filter(cards.contains(Column("to_wallet_id")))
            .fetchAll(db)
            .filter { !visited.contains($0.id) }

        var cascade = CardBillChange()

        for recurring in recurrings {
            guard
                let card = recurring.toWalletId,
                let until = recurring.generatedUntil
            else {
                continue
            }

            let entries = changed.filter { $0.walletId == card }

            for occurrence in recurring.occurrences(affectedBy: entries, through: until) {
                let billChange = try recalculateBill(
                    of: recurring,
                    on: occurrence,
                    after: change,
                    in: db,
                    at: now
                )

                cascade.before += billChange.before
                cascade.after += billChange.after
            }
        }

        let recurringIds = recurrings.map(\.id)
        let passed = visited.union(recurringIds)

        try recalculateCardBills(cascade, in: db, at: now, visited: passed)
    }

    static func billMonth(
        paidBy walletId: Wallet.ID,
        type: Entry.Kind,
        on date: LocalDate,
        shift: Int,
        in db: Database
    ) throws -> YearMonth? {
        guard
            type != .transfer,
            shift > 0
        else {
            return nil
        }

        let bill = try Recurring
            .filter(Column("archived_at") == nil)
            .filter(Column("type") == Entry.Kind.transfer)
            .filter(Column("closing_day") != nil)
            .filter(Column("to_wallet_id") == walletId)
            .order(Recurring.sortOrder, Column("created_at"))
            .fetchOne(db)

        return bill?.billMonth(for: date, shift: shift)
    }

    static func existingRows(
        of entries: [Entry],
        in db: Database
    ) throws -> [Entry] {
        let ids = entries.map(\.id)
        var rows = try Entry.fetchAll(db, keys: ids)

        for entry in entries {
            if let sameRecurrence = Entry.sameRecurrence(as: entry) {
                rows += try sameRecurrence.fetchAll(db)
            }
        }

        let rowIds = rows.map(\.id)
        let fees = try Entry.filter(rowIds.contains(Column("transfer_id"))).fetchAll(db)

        var seen = Set<Entry.ID>()

        return (rows + fees).filter { seen.insert($0.id).inserted }
    }
}

private extension AppDatabase {
    static func recalculateBill(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        after change: CardBillChange,
        in db: Database,
        at now: Date
    ) throws -> CardBillChange {
        let used = try billEntries(of: recurring, on: occurrence, in: db)
        let amount = recurring.amount(paidOn: occurrence.date, entries: used)
        let earliest = occurrence.scheduled.adding(days: -40)
        let latest = occurrence.scheduled.adding(days: 40)

        let bill = try Entry
            .filter(Column("recurring_id") == recurring.id)
            .filter(Column("recurring_date") >= earliest)
            .filter(Column("recurring_date") <= latest)
            .fetchAll(db)
            .first { recurring.isRecorded(by: $0, scheduled: occurrence.scheduled) }

        guard let bill else {
            let afterIds = change.after.map(\.id)
            let changedIds = Set(afterIds)
            let previous = used.filter { !changedIds.contains($0.id) } + change.before
            let previousAmount = recurring.amount(paidOn: occurrence.date, entries: previous)

            guard
                previousAmount == 0,
                amount > 0,
                recurring.archivedAt == nil,
                let inserted = try insertEntry(of: recurring, on: occurrence, in: db, at: now)
            else {
                return CardBillChange()
            }

            let fees = try Entry.filter(Column("transfer_id") == inserted.id).fetchAll(db)

            return CardBillChange(after: [inserted] + fees)
        }

        guard
            bill.updatedAt == bill.createdAt,
            bill.amount != amount
        else {
            return CardBillChange()
        }

        guard amount > 0 else {
            let fees = Entry.filter(Column("transfer_id") == bill.id)
            let removed = try fees.fetchAll(db)

            _ = try fees.deleteAll(db)
            try bill.delete(db)

            return CardBillChange(before: [bill] + removed)
        }

        var recalculated = bill

        recalculated.amount = amount

        try recalculated.update(db)

        return CardBillChange(before: [bill], after: [recalculated])
    }
}

private extension Recurring {
    static let maxPeriodDays = 31
    static let maxPaymentLagDays = 31
    static let maxHolidayShiftDays = 10
    static let billSearchDays = maxPeriodDays + maxPaymentLagDays + maxHolidayShiftDays

    func occurrences(
        affectedBy entries: [Entry],
        through until: LocalDate
    ) -> [Occurrence] {
        var found: [Occurrence] = []

        for entry in entries {
            for occurrence in candidates(for: entry, through: until)
                where !found.contains(occurrence) {
                found.append(occurrence)
            }
        }

        return found
    }

    func candidates(
        for entry: Entry,
        through until: LocalDate
    ) -> [Occurrence] {
        let shift = Self.maxHolidayShiftDays
        let paidStart = entry.date.adding(days: -shift)
        let searchEnd = entry.date.adding(days: Self.billSearchDays)
        let paidEnd = min(searchEnd, until)

        let paid = occurrences(from: paidStart, through: paidEnd)
            .filter { billingPeriod(paidOn: $0.date)?.contains(entry.date) == true }

        guard
            let month = entry.billMonth,
            let first = LocalDate(yearMonth: month, day: 1),
            let next = LocalDate(yearMonth: month.adding(months: 1), day: 1)
        else {
            return paid
        }

        let carriedStart = first.adding(days: -shift)
        let shiftedNext = next.adding(days: shift)
        let carriedEnd = min(shiftedNext, until)

        let carried = occurrences(from: carriedStart, through: carriedEnd)
            .filter { $0.scheduled.yearMonth == month }

        return paid + carried
    }
}

extension Entry {
    static func sameRecurrence(as entry: Entry) -> QueryInterfaceRequest<Entry>? {
        guard
            let recurringId = entry.recurringId,
            let month = entry.recurringDate?.yearMonth,
            let first = LocalDate(yearMonth: month, day: 1),
            let next = LocalDate(yearMonth: month.adding(months: 1), day: 1)
        else {
            return nil
        }

        return Entry
            .filter(Column("recurring_id") == recurringId)
            .filter(Column("recurring_date") >= first)
            .filter(Column("recurring_date") < next)
    }
}
