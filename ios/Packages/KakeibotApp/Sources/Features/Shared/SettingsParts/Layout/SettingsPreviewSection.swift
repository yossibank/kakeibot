import SwiftUI

struct SettingsPreviewSection<Preview: View>: View {
    let note: String
    let dot: Color?
    @ViewBuilder let preview: () -> Preview

    init(
        note: String,
        dot: Color? = nil,
        @ViewBuilder preview: @escaping () -> Preview
    ) {
        self.note = note
        self.dot = dot
        self.preview = preview
    }

    var body: some View {
        VStack(spacing: 8) {
            preview()

            SettingsPreviewNote(note, dot: dot)
        }
    }
}
