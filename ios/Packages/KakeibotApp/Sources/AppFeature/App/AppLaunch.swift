import Notifications

public enum AppLaunch {
    @MainActor
    public static func prepare() {
        NotificationRouter.shared.listen()
    }
}
