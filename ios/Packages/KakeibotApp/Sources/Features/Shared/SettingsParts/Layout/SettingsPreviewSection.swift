import SwiftUI

struct SettingsPreviewSection<Preview: View>: View {
    let note: String
    let colorNote: String?
    let dot: Color?
    @ViewBuilder let preview: () -> Preview

    init(
        note: String,
        colorNote: String? = nil,
        dot: Color? = nil,
        @ViewBuilder preview: @escaping () -> Preview
    ) {
        self.note = note
        self.colorNote = colorNote
        self.dot = dot
        self.preview = preview
    }

    var body: some View {
        VStack(spacing: 8) {
            preview()

            if let colorNote {
                VStack(spacing: 4) {
                    SettingsPreviewNote(note)
                    SettingsPreviewNote(colorNote, dot: dot)
                }
            } else {
                SettingsPreviewNote(note, dot: dot)
            }
        }
    }
}
