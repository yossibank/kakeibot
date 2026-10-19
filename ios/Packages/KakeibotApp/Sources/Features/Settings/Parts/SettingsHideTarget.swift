import SwiftUI

struct SettingsHideTarget: View {
    @Binding var zones: SettingsDropZones

    let state: SettingsHideHover.State

    var body: some View {
        SettingsHideZone(state: state, height: 50)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                zones.hide = frame
            }
            .transition(.opacity)
            .sensoryFeedback(
                .impact(weight: .heavy),
                trigger: state
            ) { _, new in
                new == .armed
            }
    }
}
