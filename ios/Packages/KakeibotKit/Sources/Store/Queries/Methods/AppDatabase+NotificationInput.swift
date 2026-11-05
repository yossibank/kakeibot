import Core
import GRDB

public extension AppDatabase {
    func notificationInputUpdates(
        from start: LocalDate
    ) -> some AsyncSequence<NotificationInput, any Error> {
        EntryListJoin.updates(in: self) { db in
            try Self.notificationPart(from: start, in: db)
        } join: { list, part in
            part.input(with: list)
        }
    }

    func notificationInput(from start: LocalDate) async throws -> NotificationInput {
        try await writer.read { db in
            let list = try Self.entryList(in: db, includesItems: false)
            let part = try Self.notificationPart(from: start, in: db)

            return part.input(with: list)
        }
    }
}

private struct NotificationPart: Equatable, Sendable {
    let start: LocalDate
    let markedDates: [LocalDate]
    let recurrings: [Recurring]
    let reminderTime: ReminderTime?
}

private extension NotificationPart {
    func input(with list: EntryList) -> NotificationInput {
        let entryDates = list.days.map(\.date).filter { $0 >= start }
        let recordedDates = Set(entryDates + markedDates)
        let names = list.categories.mapValues(\.name)
        let billShortages = shortages(in: list)

        return NotificationInput(
            recordedDates: recordedDates,
            recurrings: recurrings,
            reminderTime: reminderTime,
            names: names,
            shortages: billShortages
        )
    }

    func shortages(in list: EntryList) -> [NotificationPlan.Shortage] {
        let wallets = Array(list.wallets.values)
        let yesterday = start.adding(days: -1)
        let entries = list.days.flatMap(\.entries)

        let bills = CardBill.upcoming(
            recurrings: recurrings,
            wallets: wallets,
            entries: entries,
            valuations: list.valuations,
            adjustments: list.adjustments,
            after: yesterday
        )

        return bills.filter { $0.shortage > 0 }.map { bill in
            let source = list.wallets[bill.recurring.walletId]

            return NotificationPlan.Shortage(
                recurringId: bill.recurring.id,
                date: bill.date,
                walletName: source?.name ?? "口座",
                amount: bill.shortage
            )
        }
    }
}

private extension AppDatabase {
    static func notificationPart(
        from start: LocalDate,
        in db: Database
    ) throws -> NotificationPart {
        let markedDates = try NoSpendDay.filter(Column("date") >= start).fetchAll(db).map(\.date)
        let recurrings = try recurrings(in: db)
        let reminderTime = try setting(.reminderTime, in: db)

        return NotificationPart(
            start: start,
            markedDates: markedDates,
            recurrings: recurrings,
            reminderTime: reminderTime
        )
    }
}
