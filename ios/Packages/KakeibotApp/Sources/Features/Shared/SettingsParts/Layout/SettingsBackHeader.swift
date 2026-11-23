import DesignSystem
import SwiftUI

struct SettingsBackHeader: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSettingsSheetRoot) private var isSheetRoot

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
            RingButton(systemImage: closeImage) {
                dismiss()
            }

            Spacer()

            SheetTitle(title)

            Spacer()

            ZStack {
                if let hint,
                   hint.isLoaded,
                   hint.isOn {
                    RingButton(systemImage: "questionmark") {
                        withAnimation(.snappy) {
                            _ = hint.set(false)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: 44, height: 44)
        }
    }
}

public extension EnvironmentValues {
    @Entry var isSettingsSheetRoot = false
}

private extension SettingsBackHeader {
    var closeImage: String {
        isSheetRoot ? "xmark" : "chevron.left"
    }
}
