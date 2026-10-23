import Core
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
public final class NotificationRouter: NSObject {
    public static let shared = NotificationRouter()

    public private(set) var route: PlannedNotification.Route?
}

public extension NotificationRouter {
    func listen() {
        UNUserNotificationCenter.current().delegate = self
    }

    func open(_ route: PlannedNotification.Route) {
        self.route = route
    }

    func open(_ url: URL) {
        if let route = PlannedNotification.Route(url: url) {
            open(route)
        }
    }

    func finish() {
        route = nil
    }
}

extension NotificationRouter: UNUserNotificationCenterDelegate {
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let link = userInfo[LiveNotificationCenter.linkKey] as? String
        let route = link.flatMap(PlannedNotification.Route.init(link:))

        MainActor.assumeIsolated {
            if let route {
                open(route)
            }
        }

        completionHandler()
    }
}
