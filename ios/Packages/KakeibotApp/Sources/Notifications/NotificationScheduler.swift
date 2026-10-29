import Core
import Foundation

public struct NotificationScheduler: Sendable {
    private let client: any NotificationCenterClient

    public init(client: any NotificationCenterClient = LiveNotificationCenter()) {
        self.client = client
    }
}

public extension NotificationScheduler {
    static let prefix = "kakeibot."

    func apply(
        _ plan: [PlannedNotification],
        now: Date,
        timeZone: TimeZone
    ) async {
        guard await client.authorization() == .allowed else {
            return
        }

        let upcoming = plan.filter { notification in
            Self.fireDate(of: notification, in: timeZone) > now
        }

        let entries = upcoming.map { (Self.prefix + $0.identifier, $0) }
        let wanted = Dictionary(entries, uniquingKeysWith: { first, _ in first })
        let pending = await client.pendingIdentifiers().filter { $0.hasPrefix(Self.prefix) }
        let stale = pending.filter { wanted[$0] == nil }

        if !stale.isEmpty {
            await client.remove(stale)
        }

        for (identifier, notification) in wanted where !pending.contains(identifier) {
            let components = Self.components(of: notification)

            try? await client.add(
                identifier: identifier,
                title: notification.title,
                body: notification.body,
                link: notification.route.link,
                at: components
            )
        }
    }
}

private extension NotificationScheduler {
    static func components(of notification: PlannedNotification) -> DateComponents {
        DateComponents(
            year: notification.date.year,
            month: notification.date.month,
            day: notification.date.day,
            hour: notification.time.hour,
            minute: notification.time.minute
        )
    }

    static func fireDate(
        of notification: PlannedNotification,
        in timeZone: TimeZone
    ) -> Date {
        var components = components(of: notification)

        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = timeZone

        return components.date ?? .distantPast
    }
}
