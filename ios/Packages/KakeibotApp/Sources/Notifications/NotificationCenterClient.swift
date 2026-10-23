import Core
import Foundation
import UserNotifications

public protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]

    func add(
        identifier: String,
        title: String,
        body: String,
        link: String,
        at components: DateComponents
    ) async throws

    func remove(_ identifiers: [String]) async
    func authorization() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
}

public struct LiveNotificationCenter: NotificationCenterClient {
    public static let linkKey = "link"

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
        link: String,
        at components: DateComponents
    ) async throws {
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [Self.linkKey: link]

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

    public func authorization() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        default: return .allowed
        }
    }

    public func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: options)

        return granted ?? false
    }
}
