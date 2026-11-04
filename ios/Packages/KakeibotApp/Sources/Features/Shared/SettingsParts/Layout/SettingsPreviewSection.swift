import SwiftUI

struct SettingsPreviewSection<Preview: View>: View {
    let note: String
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        VStack(spacing: 8) {
            preview()

            SettingsPreviewNote(note)
        }
    }
}
