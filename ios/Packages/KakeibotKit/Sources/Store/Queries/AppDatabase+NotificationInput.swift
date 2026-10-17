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

    func reminderTime() async throws -> ReminderTime? {
        try await writer.read(Self.reminderTime)
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

        return try NotificationInput(
            recordedDates: Set(entryDates + markedDates),
            recurrings: recurrings(in: db),
            reminderTime: reminderTime(in: db),
            names: Dictionary(names, uniquingKeysWith: { first, _ in first })
        )
    }

    static func reminderTime(in db: Database) throws -> ReminderTime? {
        let key = Setting.Key.reminderTime
        let setting = try Setting.fetchOne(db, key: key)
        return setting.flatMap { ReminderTime($0.value) }
    }
}
