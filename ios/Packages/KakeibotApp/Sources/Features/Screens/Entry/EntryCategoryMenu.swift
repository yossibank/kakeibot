import Core
import DesignSystem
import SwiftUI

struct EntryCategoryMenu: View {
    let icon: Icon?
    let name: String
    let onEdit: () -> Void
    let onHide: () -> Void

    var body: some View {
        MenuPanel(width: Self.width) {
            MenuHeader(name) {
                IconImage(icon, size: 15)
            }

            MenuDivider()

            MenuRow(
                "このカテゴリを編集",
                systemImage: "square.and.pencil",
                action: onEdit
            )

            MenuDivider()

            MenuRow(
                "非表示にする",
                note: "設定のカテゴリから戻せます",
                systemImage: "eye.slash",
                action: onHide
            )
        }
    }
}

extension EntryCategoryMenu {
    static let width: CGFloat = 236
}
