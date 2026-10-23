import Core
import Foundation

public struct NotificationScheduler: Sendable {
    private let client: any NotificationCenterClient

    public init(
        client: any NotificationCenterClient = LiveNotificationCenter()
    ) {
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
        let upcoming = plan.filter { notification in
            Self.fireDate(of: notification, in: timeZone) > now
        }

        if !upcoming.isEmpty,
           await client.authorization() == .notDetermined {
            _ = await client.requestAuthorization()
        }

        let wanted = Dictionary(
            upcoming.map { (Self.prefix + $0.identifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let pending = await client.pendingIdentifiers()
            .filter { $0.hasPrefix(Self.prefix) }

        let stale = pending.filter { wanted[$0] == nil }

        if !stale.isEmpty {
            await client.remove(stale)
        }

        for (identifier, notification) in wanted
            where !pending.contains(identifier) {
            try? await client.add(
                identifier: identifier,
                title: notification.title,
                body: notification.body,
                link: notification.route.link,
                at: Self.components(of: notification, in: timeZone)
            )
        }
    }
}

private extension NotificationScheduler {
    static func components(
        of notification: PlannedNotification,
        in timeZone: TimeZone
    ) -> DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: timeZone,
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
        let components = components(of: notification, in: timeZone)

        return components.date ?? .distantPast
    }
}
