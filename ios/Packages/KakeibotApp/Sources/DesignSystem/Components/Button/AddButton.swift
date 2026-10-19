import SwiftUI

public struct AddButton: View {
    private let title: String
    private let action: () -> Void

    public init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus")
                .font(.subheadline)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.faint, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.outline, style: .dashed)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddButton("口座を追加") {}
        .padding()
        .background(Palette.background)
}
