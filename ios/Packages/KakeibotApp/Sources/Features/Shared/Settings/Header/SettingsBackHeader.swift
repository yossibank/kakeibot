import DesignSystem
import SwiftUI

struct SettingsBackHeader: View {
    @Environment(\.dismiss) private var dismiss

    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text(title)
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }
}
