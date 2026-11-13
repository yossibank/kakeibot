import Core
import SwiftUI

public struct IconTile: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?
    let size: CGFloat

    public init(
        _ icon: Icon?,
        size: CGFloat
    ) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(size / 4))
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        IconImage(icon, size: size * 0.44)
            .frame(width: size, height: size)
            .background(color.opacity(.subtle), in: shape)
            .overlay {
                shape
                    .strokeBorder(color.opacity(.medium), lineWidth: 1)
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        IconTile(nil, size: 32)
        IconTile(nil, size: 40)
    }
    .padding()
    .background(Palette.background)
}
