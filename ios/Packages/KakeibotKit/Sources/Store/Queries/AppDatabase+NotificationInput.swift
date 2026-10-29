import Core
import GRDB

public extension AppDatabase {
    func notificationInputUpdates(
        from start: LocalDate
    ) -> some AsyncSequence<NotificationInput, any Error> {
        ValueObservation
            .tracking { db in
                try Self.notificationInput(from: start, in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func notificationInput(
        from start: LocalDate
    ) async throws -> NotificationInput {
        try await writer.read { db in
            try Self.notificationInput(from: start, in: db)
        }
    }
}

private extension AppDatabase {
    static func notificationInput(
        from start: LocalDate,
        in db: Database
    ) throws -> NotificationInput {
        let entryDateRequest = Entry
            .select(Column("date"))
            .filter(Column("date") >= start)
            .distinct()

        let entryDates = try LocalDate.fetchAll(db, entryDateRequest)
        let markedDates = try NoSpendDay.filter(Column("date") >= start).fetchAll(db).map(\.date)
        let recordedDates = Set(entryDates + markedDates)
        let namePairs = try EntryCategory.fetchAll(db).map { ($0.id, $0.name) }
        let recurrings = try recurrings(in: db)
        let reminderTime = try setting(.reminderTime, in: db)
        let names = Dictionary(namePairs, uniquingKeysWith: { first, _ in first })
        let shortages = try shortages(of: recurrings, from: start, in: db)

        return NotificationInput(
            recordedDates: recordedDates,
            recurrings: recurrings,
            reminderTime: reminderTime,
            names: names,
            shortages: shortages
        )
    }

    static func shortages(
        of recurrings: [Recurring],
        from start: LocalDate,
        in db: Database
    ) throws -> [NotificationPlan.Shortage] {
        let wallets = try Wallet.fetchAll(db)
        let entries = try Entry.fetchAll(db)
        let valuations = try Valuation.fetchAll(db)
        let yesterday = start.adding(days: -1)

        let bills = CardBill.upcoming(
            recurrings: recurrings,
            wallets: wallets,
            entries: entries,
            valuations: valuations,
            after: yesterday
        )

        return bills.filter { $0.shortage > 0 }.map { bill in
            let source = wallets.first { $0.id == bill.recurring.walletId }

            return NotificationPlan.Shortage(
                recurringId: bill.recurring.id,
                date: bill.date,
                walletName: source?.name ?? "口座",
                amount: bill.shortage
            )
        }
    }
}
