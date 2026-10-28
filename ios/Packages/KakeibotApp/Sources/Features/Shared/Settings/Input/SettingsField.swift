import Core
import DesignSystem
import SwiftUI

struct SettingsField<Field: Hashable>: View {
    @Environment(\.themeStyle.corner) private var corner
    @Environment(\.themeStyle.textFont) private var textFont
    @Environment(\.themeStyle.textSize.scale) private var textScale

    @Binding private var text: String

    private let prompt: String
    private let font: Font?
    private let isInvalid: Bool
    private let focus: FocusState<Field?>.Binding
    private let field: Field
    private let onSubmit: (() -> Void)?

    init(
        _ prompt: String,
        text: Binding<String>,
        font: Font? = nil,
        isInvalid: Bool = false,
        focus: FocusState<Field?>.Binding,
        field: Field,
        onSubmit: (() -> Void)? = nil
    ) {
        _text = text

        self.prompt = prompt
        self.font = font
        self.isInvalid = isInvalid
        self.focus = focus
        self.field = field
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 8) {
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
                if let onSubmit {
                    onSubmit()
                } else {
                    focus.wrappedValue = nil
                }
            }

            Button {
                focus.wrappedValue = field
            } label: {
                EditBadge(size: 16)
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .opacity(badgeOpacity)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
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

    var badgeOpacity: Double {
        isFocused ? 0 : 1
    }

    var stroke: Color {
        if isInvalid {
            return Palette.rose
        }

        return isFocused ? Palette.accent : Palette.accent.opacity(.muted)
    }
}
