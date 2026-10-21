import DesignSystem
import SwiftUI

struct SettingsEditHeader: View {
    let title: String
    let isEditing: Bool
    let isHidden: Bool
    let onClose: () -> Void
    let onHide: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            RingButton(systemImage: "xmark", action: onClose)
                .frame(width: Self.sideWidth, alignment: .leading)

            Spacer()

            SettingsSheetTitle(title)

            Spacer()

            ZStack {
                if isEditing {
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
            .frame(width: Self.sideWidth, alignment: .trailing)
        }
    }
}

private extension SettingsEditHeader {
    static let sideWidth: CGFloat = 104
}
