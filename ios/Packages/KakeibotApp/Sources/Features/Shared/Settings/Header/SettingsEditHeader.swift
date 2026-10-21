import DesignSystem
import SwiftUI

struct SettingsEditHeader: View {
    @Environment(\.isSettingsEditPushed) private var isPushed

    let title: String
    let isEditing: Bool
    let isHidden: Bool
    let onClose: () -> Void
    let onHide: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            RingButton(systemImage: closeImage, action: onClose)
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

extension EnvironmentValues {
    @Entry var isSettingsEditPushed = false
}

private extension SettingsEditHeader {
    static let sideWidth: CGFloat = 104

    var closeImage: String {
        isPushed ? "chevron.left" : "xmark"
    }
}
