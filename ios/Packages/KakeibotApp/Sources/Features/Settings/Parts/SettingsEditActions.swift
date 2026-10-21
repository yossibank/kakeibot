import DesignSystem
import SwiftUI

struct SettingsEditActions: View {
    let isHidden: Bool
    let onHide: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SettingsHideButton(isHidden: isHidden, action: onHide)

            RingButton(
                systemImage: "trash",
                style: .destructive,
                label: "削除",
                action: onDelete
            )
        }
    }
}

extension SettingsEditActions {
    static let width: CGFloat = 104
}
