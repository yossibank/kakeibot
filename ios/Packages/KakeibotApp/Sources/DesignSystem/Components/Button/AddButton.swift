import SwiftUI

public struct AddButton: View {
    private let title: String
    private let isLocked: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        isLocked: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLocked = isLocked
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Label(title, systemImage: "plus")

                if isLocked {
                    ProMark()
                }
            }
            .textFont(.subheadline)
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
    VStack(spacing: 12) {
        AddButton("口座を追加") {}

        AddButton("テーマを追加", isLocked: true) {}
    }
    .padding()
    .background(Palette.background)
}
