import Core

public struct NotificationInput: Equatable, Sendable {
    public let recordedDates: Set<LocalDate>
    public let recurrings: [Recurring]
    public let reminderTime: ReminderTime?
    public let names: [EntryCategory.ID: String]

    public init(
        recordedDates: Set<LocalDate>,
        recurrings: [Recurring],
        reminderTime: ReminderTime?,
        names: [EntryCategory.ID: String]
    ) {
        self.recordedDates = recordedDates
        self.recurrings = recurrings
        self.reminderTime = reminderTime
        self.names = names
    }
}
