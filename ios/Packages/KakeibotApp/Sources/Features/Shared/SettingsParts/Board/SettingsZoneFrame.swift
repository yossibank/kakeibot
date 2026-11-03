import Core
import DesignSystem
import SwiftUI

struct SettingsZoneFrame: View {
    @Environment(\.themeStyle.corner) private var corner

    let color: Color
    let fill: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        shape
            .fill(Palette.backgroundBottom.opacity(.strong))
            .overlay {
                shape
                    .fill(fill)
            }
            .overlay {
                shape
                    .stroke(color.opacity(0.6), style: .dashed)
            }
    }
}
