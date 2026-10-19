import DesignSystem
import SwiftUI

struct SettingsHiddenTitle: View {
    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            SettingsSectionTitle(title)

            Spacer()

            Text("長押しで上に動かすと戻せます")
                .font(.caption2)
                .foregroundStyle(Palette.mist)
        }
    }
}
