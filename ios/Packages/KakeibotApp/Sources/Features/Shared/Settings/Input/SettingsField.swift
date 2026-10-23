import DesignSystem
import SwiftUI

struct SettingsField<Field: Hashable>: View {
    @Environment(\.themeStyle.corner) private var corner
    @Environment(\.themeStyle.textFont) private var textFont
    @Environment(\.themeStyle.textSize.scale) private var textScale

    @Binding private var text: String

    private let prompt: String
    private let font: Font?
    private let focus: FocusState<Field?>.Binding
    private let field: Field

    init(
        _ prompt: String,
        text: Binding<String>,
        font: Font? = nil,
        focus: FocusState<Field?>.Binding,
        field: Field
    ) {
        _text = text

        self.prompt = prompt
        self.font = font
        self.focus = focus
        self.field = field
    }

    var body: some View {
        TextField(
            prompt,
            text: $text,
            prompt: Text(prompt).foregroundStyle(Palette.hint)
        )
        .font(font ?? .text(.body, in: textFont, scale: textScale))
        .foregroundStyle(Palette.text)
        .tint(Palette.accent)
        .submitLabel(.done)
        .focused(focus, equals: field)
        .onSubmit {
            focus.wrappedValue = nil
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(Palette.panel, in: .rect(cornerRadius: corner.radius(16)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(16))
                .stroke(stroke, lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: isFocused)
    }
}

private extension SettingsField {
    var isFocused: Bool {
        focus.wrappedValue == field
    }

    var stroke: Color {
        isFocused ? Palette.accent : Palette.accent.opacity(.muted)
    }
}
