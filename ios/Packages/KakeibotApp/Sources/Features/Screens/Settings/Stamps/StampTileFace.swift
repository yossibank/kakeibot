import Core
import DesignSystem
import SwiftUI

struct StampTileFace: View {
    let icon: Icon?
    let isHidden: Bool

    var body: some View {
        let opacity: Double = isHidden ? 0.6 : 1

        IconBadge(icon, size: 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .settingsTileFace(isHidden: isHidden)
            .opacity(opacity)
    }
}
