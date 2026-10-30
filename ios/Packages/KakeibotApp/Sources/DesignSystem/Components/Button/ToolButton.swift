import SwiftUI

public struct ToolButton: View {
    private let systemImage: String
    private let action: () -> Void

    public init(
        systemImage: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 32, height: 32)
                .overlay {
                    Circle()
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }
                .frame(width: 40, height: 40)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 16) {
        ToolButton(systemImage: "plus") {}

        ToolButton(systemImage: "pencil") {}
    }
    .padding()
    .background(Palette.background)
}
