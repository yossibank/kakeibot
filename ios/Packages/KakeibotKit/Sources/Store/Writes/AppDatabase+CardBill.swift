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
        at now: Date
    ) throws {
        let changed = change.before + change.after
        let cards = Set(changed.map(\.walletId))

        guard !cards.isEmpty else {
            return
        }

        let recurrings = try Recurring
            .filter(Column("closing_day") != nil)
            .filter(cards.contains(Column("to_wallet_id")))
            .fetchAll(db)

        for recurring in recurrings {
            guard
                let card = recurring.toWalletId,
                let until = recurring.generatedUntil
            else {
                continue
            }

            let entries = changed.filter { $0.walletId == card }

            for occurrence in recurring.occurrences(affectedBy: entries, through: until) {
                try recalculateBill(
                    of: recurring,
                    on: occurrence,
                    after: change,
                    in: db,
                    at: now
                )
            }
        }
    }

    static func existingRows(
        of entries: [Entry],
        in db: Database
    ) throws -> [Entry] {
        let ids = entries.map(\.id)
        var rows = try Entry.fetchAll(db, keys: ids)

        for entry in entries {
            guard
                let recurringId = entry.recurringId,
                let recurringDate = entry.recurringDate
            else {
                continue
            }

            let duplicates = try Entry
                .filter(Column("recurring_id") == recurringId)
                .filter(Column("recurring_date") == recurringDate)
                .fetchAll(db)

            rows += duplicates
        }

        let fees = try Entry
            .filter(rows.map(\.id).contains(Column("transfer_id")))
            .fetchAll(db)

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
    ) throws {
        let used = try billEntries(of: recurring, on: occurrence, in: db)
        let amount = recurring.amount(paidOn: occurrence.date, entries: used)

        let bill = try Entry
            .filter(Column("recurring_id") == recurring.id)
            .filter(Column("recurring_date") >= occurrence.scheduled.adding(days: -40))
            .filter(Column("recurring_date") <= occurrence.scheduled.adding(days: 40))
            .fetchAll(db)
            .first { recurring.isRecorded(by: $0, scheduled: occurrence.scheduled) }

        guard let bill else {
            let changedIds = Set(change.after.map(\.id))
            let previous = used.filter { !changedIds.contains($0.id) } + change.before

            let previousAmount = recurring.amount(
                paidOn: occurrence.date,
                entries: previous
            )

            if previousAmount == 0, amount > 0, recurring.archivedAt == nil {
                try insertEntry(of: recurring, on: occurrence, in: db, at: now)
            }

            return
        }

        guard
            bill.updatedAt == bill.createdAt,
            bill.amount != amount
        else {
            return
        }

        guard amount > 0 else {
            _ = try Entry.filter(Column("transfer_id") == bill.id).deleteAll(db)
            try bill.delete(db)
            return
        }

        var recalculated = bill

        recalculated.amount = amount

        try recalculated.update(db)
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

        let paid = occurrences(
            from: entry.date.adding(days: -shift),
            through: min(entry.date.adding(days: Self.billSearchDays), until)
        )
        .filter { billingPeriod(paidOn: $0.date)?.contains(entry.date) == true }

        guard
            let month = entry.billMonth,
            let first = LocalDate(yearMonth: month, day: 1),
            let next = LocalDate(yearMonth: month.adding(months: 1), day: 1)
        else {
            return paid
        }

        let carried = occurrences(
            from: first.adding(days: -shift),
            through: min(next.adding(days: shift), until)
        )
        .filter { $0.scheduled.yearMonth == month }

        return paid + carried
    }
}
