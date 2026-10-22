import DesignSystem
import SwiftUI

struct SettingsHideTarget: View {
    @Binding var zones: SettingsDropZones

    let isArmed: Bool

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: SettingsDropZones.hideHeight)
            .overlay(alignment: .bottom) {
                SettingsZoneBox(
                    isOn: isArmed,
                    closedHeight: SettingsDropZones.hideHeight,
                    tint: Palette.rose,
                    offLabel: .init(
                        systemImage: "eye.slash",
                        title: "ここに置くと非表示にできます"
                    ),
                    onLabel: .init(
                        systemImage: "eye.slash.fill",
                        title: "離すと非表示になります"
                    )
                )
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    zones.hide = frame
                }
            }
            .transition(.opacity)
            .sensoryFeedback(
                .impact(weight: .heavy),
                trigger: isArmed
            ) { _, new in
                new
            }
    }
}
