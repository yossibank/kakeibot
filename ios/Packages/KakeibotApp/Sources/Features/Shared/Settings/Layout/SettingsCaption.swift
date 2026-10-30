import DesignSystem
import SwiftUI

struct SettingsCaption: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .padding(.leading, 8)
    }
}
