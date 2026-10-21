import DesignSystem
import SwiftUI

struct SettingsBackHeader: View {
    @Environment(\.dismiss) private var dismiss

    private let title: String
    private let hint: SettingsScreenFlag?

    init(
        _ title: String,
        hint: SettingsScreenFlag? = nil
    ) {
        self.title = title
        self.hint = hint
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

            ZStack {
                if let hint,
                   hint.isLoaded,
                   hint.isOn {
                    RingButton(systemImage: "questionmark") {
                        withAnimation(.snappy) {
                            hint.set(false)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: 44, height: 44)
        }
    }
}
