#if DEBUG
    import UIKit

    extension UIWindow {
        override open func motionEnded(
            _ motion: UIEvent.EventSubtype,
            with event: UIEvent?
        ) {
            super.motionEnded(motion, with: event)

            if motion == .motionShake {
                NotificationCenter.default.post(name: .deviceDidShake, object: nil)
            }
        }
    }

    extension Notification.Name {
        static let deviceDidShake = Notification.Name("deviceDidShake")
    }
#endif
