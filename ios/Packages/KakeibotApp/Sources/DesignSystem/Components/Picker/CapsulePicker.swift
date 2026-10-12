import SwiftUI

public struct CapsulePicker<Value: Hashable>: View {
    @Binding var selection: Value

    let options: [Option]

    public init(
        selection: Binding<Value>,
        options: [Option]
    ) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                button(for: option)
            }
        }
        .padding(3)
        .background(Palette.gold.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(Palette.gold.opacity(0.3), lineWidth: 1))
    }
}

public extension CapsulePicker {
    struct Option {
        public let title: String
        public let value: Value

        public init(
            _ title: String,
            value: Value
        ) {
            self.title = title
            self.value = value
        }
    }
}

private extension CapsulePicker {
    func button(for option: Option) -> some View {
        let isSelected = selection == option.value

        return Button(option.title) {
            selection = option.value
        }
        .font(.footnote.weight(isSelected ? .bold : .regular))
        .foregroundStyle(isSelected ? Palette.nightBottom : Palette.mist)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(isSelected ? Palette.gold : Color.clear, in: Capsule())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = 0

    CapsulePicker(
        selection: $selection,
        options: [
            .init("支出", value: 0),
            .init("収入", value: 1)
        ]
    )
    .padding()
    .background(Palette.night)
}
