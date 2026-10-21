import DesignSystem
import SwiftUI

struct SettingsHideButton: View {
    let isHidden: Bool
    let action: () -> Void

    var body: some View {
        RingButton(
            systemImage: systemImage,
            style: style,
            label: label,
            action: action
        )
    }
}

private extension SettingsHideButton {
    var systemImage: String {
        isHidden ? "eye" : "eye.slash"
    }

    var label: String {
        isHidden ? "表示に戻す" : "非表示"
    }

    var style: RingButton.Style {
        isHidden ? .prominent : .plain
    }
}
