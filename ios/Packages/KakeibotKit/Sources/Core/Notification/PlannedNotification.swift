public struct PlannedNotification: Hashable, Sendable {
    public let key: String
    public let date: LocalDate
    public let time: ReminderTime
    public let title: String
    public let body: String
    public let route: Route

    public init(
        key: String,
        date: LocalDate,
        time: ReminderTime,
        title: String,
        body: String,
        route: Route
    ) {
        self.key = key
        self.date = date
        self.time = time
        self.title = title
        self.body = body
        self.route = route
    }
}

public extension PlannedNotification {
    enum Route: Hashable, Sendable {
        case entry(LocalDate)
        case recurring(Recurring.ID)
    }

    var identifier: String {
        [key, date.description, time.description, title, body]
            .joined(separator: "|")
    }
}
