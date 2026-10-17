import Foundation
import UserNotifications

public protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]

    func add(
        identifier: String,
        title: String,
        body: String,
        at components: DateComponents
    ) async throws

    func remove(_ identifiers: [String]) async
    func needsAuthorization() async -> Bool
    func requestAuthorization() async -> Bool
}

public struct LiveNotificationCenter: NotificationCenterClient {
    public init() {}

    public func pendingIdentifiers() async -> [String] {
        await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
            .map(\.identifier)
    }

    public func add(
        identifier: String,
        title: String,
        body: String,
        at components: DateComponents
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    public func remove(_ identifiers: [String]) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func needsAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        return settings.authorizationStatus == .notDetermined
    }

    public func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: options)

        return granted ?? false
    }
}
