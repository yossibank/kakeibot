import Features
import SwiftUI
import UIKit

extension View {
    func debugMenuOnShake() -> some View {
        #if DEBUG
        modifier(DebugMenuOnShake())
        #else
        self
        #endif
    }
}

#if DEBUG
private struct DebugMenuOnShake: ViewModifier {
    @State private var isShowing = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                isShowing = true
            }
            .sheet(isPresented: $isShowing) {
                DebugMenu()
            }
    }
}

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

private extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}
#endif
