import SwiftUI

public struct SearchField: View {
    @Binding var text: String

    let prompt: String
    let focus: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    public init(
        _ prompt: String,
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        onSubmit: @escaping () -> Void = {}
    ) {
        _text = text

        self.prompt = prompt
        self.focus = focus
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            TextField(
                prompt,
                text: $text,
                prompt: Text(prompt)
                    .foregroundStyle(Palette.hint)
            )
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .tint(Palette.accent)
            .submitLabel(.search)
            .focused(focus)
            .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.hint)
                        .frame(width: 32, height: 32)
                        .tapArea(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, text.isEmpty ? 16 : 8)
        .frame(height: 44)
        .background(Palette.faint, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Palette.outline, lineWidth: 1)
        }
    }
}

#Preview {
    @Previewable @State var text = "コンビニ"
    @Previewable @FocusState var isFocused: Bool

    SearchField("名前で探す", text: $text, focus: $isFocused)
        .padding()
        .background(Palette.background)
}
