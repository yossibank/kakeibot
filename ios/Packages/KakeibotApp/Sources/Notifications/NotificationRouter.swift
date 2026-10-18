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

    func finish() {
        route = nil
    }
}

extension NotificationRouter: UNUserNotificationCenterDelegate {
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let link = userInfo[LiveNotificationCenter.linkKey] as? String

        guard let route = link.flatMap(PlannedNotification.Route.init(link:))
        else {
            return
        }

        await open(route)
    }
}
