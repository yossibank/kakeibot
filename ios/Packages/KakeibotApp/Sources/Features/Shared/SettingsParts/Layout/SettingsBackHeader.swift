import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsBackHeader: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSettingsSheetRoot) private var isSheetRoot

    private let title: String
    private let hint: SettingsFold?

    init(
        _ title: String,
        hint: SettingsFold? = nil
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
                   hint.isClosed {
                    RingButton(systemImage: "questionmark") {
                        withAnimation(.snappy) {
                            hint.setClosed(false)
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
