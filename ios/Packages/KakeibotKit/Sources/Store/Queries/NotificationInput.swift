import Core

public struct NotificationInput: Equatable, Sendable {
    public let recordedDates: Set<LocalDate>
    public let recurrings: [Recurring]
    public let reminderTime: ReminderTime?
    public let names: [EntryCategory.ID: String]
    public let shortages: [NotificationPlan.Shortage]

    public init(
        recordedDates: Set<LocalDate>,
        recurrings: [Recurring],
        reminderTime: ReminderTime?,
        names: [EntryCategory.ID: String],
        shortages: [NotificationPlan.Shortage] = []
    ) {
        self.recordedDates = recordedDates
        self.recurrings = recurrings
        self.reminderTime = reminderTime
        self.names = names
        self.shortages = shortages
    }
}
