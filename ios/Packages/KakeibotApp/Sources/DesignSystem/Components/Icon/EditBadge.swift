import SwiftUI

public struct EditBadge: View {
    private let size: CGFloat

    public init(size: CGFloat = 24) {
        self.size = size
    }

    public var body: some View {
        Image(systemName: "pencil")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Palette.accent)
            .frame(width: size, height: size)
            .background(Palette.panel, in: Circle())
            .overlay {
                Circle()
                    .stroke(Palette.outline, lineWidth: 1)
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        EditBadge()

        EditBadge(size: 20)
    }
    .padding()
    .background(Palette.background)
}
