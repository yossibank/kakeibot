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
        case home
        case entry(LocalDate)
        case recurring(Recurring.ID)
    }

    var identifier: String {
        [key, date.description, time.description, title, body]
            .joined(separator: "|")
    }
}

public extension PlannedNotification.Route {
    init?(link: String) {
        if link == "home" {
            self = .home
            return
        }

        let parts = link.split(separator: "/", maxSplits: 1).map(String.init)

        guard parts.count == 2 else {
            return nil
        }

        switch parts[0] {
        case "entry":
            guard let date = LocalDate(parts[1]) else {
                return nil
            }

            self = .entry(date)
        case "recurring":
            guard let id = Recurring.ID(parts[1]) else {
                return nil
            }

            self = .recurring(id)
        default:
            return nil
        }
    }

    var link: String {
        switch self {
        case .home: "home"
        case let .entry(date): "entry/\(date)"
        case let .recurring(id): "recurring/\(id)"
        }
    }
}
