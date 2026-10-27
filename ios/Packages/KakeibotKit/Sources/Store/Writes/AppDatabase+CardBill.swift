import Core
import Foundation
import GRDB

extension AppDatabase {
    static func recalculateCardBills(
        affectedBy changed: [Entry],
        in db: Database,
        at now: Date
    ) throws {
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
                try recalculateBill(of: recurring, on: occurrence, in: db, at: now)
            }
        }
    }
}

private extension AppDatabase {
    static func recalculateBill(
        of recurring: Recurring,
        on occurrence: Recurring.Occurrence,
        in db: Database,
        at now: Date
    ) throws {
        let amount = try billAmount(of: recurring, on: occurrence, in: db)

        let bill = try Entry
            .filter(Column("recurring_id") == recurring.id)
            .fetchAll(db)
            .first { recurring.isRecorded(by: $0, scheduled: occurrence.scheduled) }

        guard let bill else {
            if amount > 0, recurring.archivedAt == nil {
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
    func occurrences(
        affectedBy entries: [Entry],
        through until: LocalDate
    ) -> [Occurrence] {
        var found: [Occurrence] = []

        for entry in entries {
            let candidates = occurrences(
                from: entry.date.adding(days: -40),
                through: min(entry.date.adding(days: 130), until)
            )

            for occurrence in candidates where !found.contains(occurrence) {
                if isAffected(occurrence, by: entry) {
                    found.append(occurrence)
                }
            }
        }

        return found
    }

    func isAffected(
        _ occurrence: Occurrence,
        by entry: Entry
    ) -> Bool {
        let inPeriod = billingPeriod(paidOn: occurrence.date)?.contains(entry.date) == true

        return inPeriod || entry.billMonth == occurrence.scheduled.yearMonth
    }
}
