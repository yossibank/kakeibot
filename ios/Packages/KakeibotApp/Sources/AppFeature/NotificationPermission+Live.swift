import Features
import Notifications

extension NotificationPermission {
    static let live = Self {
        await LiveNotificationCenter().authorization()
    } request: {
        await LiveNotificationCenter().requestAuthorization()
    }
}
