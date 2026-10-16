import DesignSystem
import SwiftUI

struct SettingsHideButton: View {
    let isHidden: Bool
    let action: () -> Void

    var body: some View {
        RingButton(systemImage: systemImage, style: style, action: action)
    }
}

private extension SettingsHideButton {
    var systemImage: String {
        isHidden ? "eye" : "eye.slash"
    }

    var style: RingButton.Style {
        isHidden ? .prominent : .plain
    }
}
