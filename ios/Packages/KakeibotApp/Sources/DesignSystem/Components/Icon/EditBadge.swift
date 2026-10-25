import SwiftUI

public struct EditBadge: View {
    private let size: CGFloat

    public init(size: CGFloat = 18) {
        self.size = size
    }

    public var body: some View {
        Image(systemName: "pencil")
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(Palette.accent)
            .frame(width: size, height: size)
            .background(Palette.panel, in: Circle())
            .overlay {
                Circle()
                    .stroke(Palette.accent, lineWidth: 1)
            }
            .shadow(color: Palette.shadow, radius: 4, y: 2)
    }
}

#Preview {
    HStack(spacing: 16) {
        EditBadge()

        EditBadge(size: 16)

        Text("¥150,000")
            .editBadge()
    }
    .padding()
    .background(Palette.background)
}
