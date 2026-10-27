import Core
import Foundation
import GRDB

enum MigrationV25 {
    static func migrate(_ db: Database) throws {
        let recurrings = try Row
            .fetchAll(db, sql: recurringSQL)
            .compactMap(Self.recurring)

        try moveRecurringDates(of: recurrings, in: db)
        try moveBillMonths(of: recurrings, in: db)
    }
}

private extension MigrationV25 {
    static let recurringSQL = """
    SELECT id, to_wallet_id, frequency, month, day, holiday_shift, \
    closing_day, start_date
    FROM recurring
    """

    static let recurringEntrySQL = """
    SELECT id, recurring_id, recurring_date FROM entry
    WHERE recurring_id IS NOT NULL
    """

    static let billEntrySQL = """
    SELECT id, wallet_id, bill_month FROM entry
    WHERE bill_month IS NOT NULL AND updated_at < '\(billMonthCutoff)'
    """

    static let billMonthCutoff = "2026-10-27T09:28:13"

    static let sameOccurrenceSQL = """
    SELECT EXISTS (
        SELECT 1 FROM entry
        WHERE recurring_id = ? AND recurring_date = ? AND id <> ?
    )
    """

    static func recurring(_ row: Row) -> Recurring? {
        guard
            let id = Recurring.ID(row["id"] as String),
            let frequency = Recurring.Frequency(rawValue: row["frequency"]),
            let holidayShift = Recurring.HolidayShift(rawValue: row["holiday_shift"]),
            let startDate = row["start_date"] as LocalDate?
        else {
            return nil
        }

        let now = Date(timeIntervalSince1970: 0)

        return Recurring(
            id: id,
            type: .expense,
            amount: 0,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: (row["to_wallet_id"] as String?).flatMap(Wallet.ID.init),
            frequency: frequency,
            month: row["month"],
            day: row["day"],
            holidayShift: holidayShift,
            closingDay: row["closing_day"],
            startDate: startDate,
            createdAt: now,
            updatedAt: now
        )
    }

    static func moveRecurringDates(
        of recurrings: [Recurring],
        in db: Database
    ) throws {
        let byID = Dictionary(uniqueKeysWithValues: recurrings.map { ($0.id, $0) })

        for row in try Row.fetchAll(db, sql: recurringEntrySQL) {
            guard
                let recurring = (row["recurring_id"] as String?)
                .flatMap(Recurring.ID.init)
                .flatMap({ byID[$0] }),
                let recorded = row["recurring_date"] as LocalDate?,
                let scheduled = recurring.scheduledDate(shiftedTo: recorded),
                scheduled != recorded
            else {
                continue
            }

            let id = row["id"] as String

            let taken = try Bool.fetchOne(
                db,
                sql: sameOccurrenceSQL,
                arguments: [recurring.id.description, scheduled, id]
            ) ?? false

            guard !taken else {
                continue
            }

            try db.execute(
                sql: "UPDATE entry SET recurring_date = ? WHERE id = ?",
                arguments: [scheduled, id]
            )
        }
    }

    static func moveBillMonths(
        of recurrings: [Recurring],
        in db: Database
    ) throws {
        for row in try Row.fetchAll(db, sql: billEntrySQL) {
            guard let month = row["bill_month"] as YearMonth? else {
                continue
            }

            let wallet = (row["wallet_id"] as String?).flatMap(Wallet.ID.init)

            let bills = recurrings.filter {
                $0.toWalletId == wallet && $0.closingDay != nil
            }

            guard let bill = bills.first, bills.count == 1 else {
                continue
            }

            let scheduled = bill.scheduledDates(shiftedInto: month)

            guard let first = scheduled.first, scheduled.count == 1 else {
                continue
            }

            try db.execute(
                sql: "UPDATE entry SET bill_month = ? WHERE id = ?",
                arguments: [first.yearMonth, row["id"] as String]
            )
        }
    }
}
