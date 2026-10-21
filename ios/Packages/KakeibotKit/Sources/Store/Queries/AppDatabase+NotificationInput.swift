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
        let entryDates = try LocalDate.fetchAll(
            db,
            Entry
                .select(Column("date"))
                .filter(Column("date") >= start)
                .distinct()
        )

        let markedDates = try NoSpendDay
            .filter(Column("date") >= start)
            .fetchAll(db)
            .map(\.date)

        let names = try EntryCategory.fetchAll(db).map { ($0.id, $0.name) }
        let recurrings = try recurrings(in: db)

        return try NotificationInput(
            recordedDates: Set(entryDates + markedDates),
            recurrings: recurrings,
            reminderTime: setting(.reminderTime, in: db),
            names: Dictionary(names, uniquingKeysWith: { first, _ in first }),
            shortages: shortages(of: recurrings, from: start, in: db)
        )
    }

    static func shortages(
        of recurrings: [Recurring],
        from start: LocalDate,
        in db: Database
    ) throws -> [NotificationPlan.Shortage] {
        let wallets = try Wallet.fetchAll(db)

        let bills = try CardBill.upcoming(
            recurrings: recurrings,
            wallets: wallets,
            entries: Entry.fetchAll(db),
            after: start.adding(days: -1)
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
