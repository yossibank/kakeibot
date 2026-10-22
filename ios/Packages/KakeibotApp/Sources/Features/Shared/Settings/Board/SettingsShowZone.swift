import DesignSystem
import SwiftUI

struct SettingsShowZone: View {
    let isTargeted: Bool

    var body: some View {
        SettingsZoneBox(
            isOn: isTargeted,
            closedHeight: SettingsDropZones.showHeight,
            tint: Palette.accent,
            offLabel: .init(
                systemImage: "eye",
                title: "ここに置くと表示に戻ります"
            ),
            onLabel: .init(
                systemImage: "eye",
                title: "離すと表示に戻ります"
            )
        )
    }
}
