import Notifications

public enum AppLaunch {}

public extension AppLaunch {
    @MainActor
    static func prepare() {
        NotificationRouter.shared.listen()
    }
}
