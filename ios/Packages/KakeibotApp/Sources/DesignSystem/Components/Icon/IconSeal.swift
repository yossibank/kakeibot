import Core
import SwiftUI

public struct IconSeal: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: Icon
    let size: CGFloat

    public init(
        _ icon: Icon,
        size: CGFloat
    ) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(tint)
            .frame(width: size, height: size)
            .overlay {
                IconImage(icon, size: size * 0.42)
                    .foregroundStyle(Palette.backgroundBottom)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        Palette.backgroundBottom,
                        lineWidth: size * 0.08
                    )
            }
            .shadow(color: tint.opacity(glow), radius: size * 0.2)
    }
}

private extension IconSeal {
    var tint: Color {
        Color(hex: icon.color) ?? Palette.accent
    }

    var glow: Double {
        colorScheme == .light ? 0.25 : 0.5
    }
}

#Preview {
    let now = Date()
    let star = Icon(
        emoji: nil,
        text: nil,
        glyph: .star,
        color: "#C9A465",
        createdAt: now,
        updatedAt: now
    )
    let cake = Icon(
        emoji: "🎂",
        text: nil,
        color: "#E5989B",
        createdAt: now,
        updatedAt: now
    )

    HStack(spacing: 16) {
        IconSeal(star, size: 18)
        IconSeal(cake, size: 18)
        IconSeal(star, size: 30)
    }
    .padding()
    .background(Palette.background)
}
