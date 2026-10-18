import DesignSystem
import SwiftUI

struct SettingsField<Field: Hashable>: View {
    @Binding private var text: String

    private let prompt: String
    private let font: Font
    private let focus: FocusState<Field?>.Binding
    private let field: Field

    init(
        _ prompt: String,
        text: Binding<String>,
        font: Font,
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
            prompt: Text(prompt).foregroundStyle(Palette.dusk)
        )
        .font(font)
        .foregroundStyle(Palette.ink)
        .tint(Palette.gold)
        .submitLabel(.done)
        .focused(focus, equals: field)
        .onSubmit {
            focus.wrappedValue = nil
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Palette.drawer, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
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
        isFocused ? Palette.gold : Palette.gold.opacity(.muted)
    }
}
