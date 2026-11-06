import Core
import SwiftUI

public struct IconSeal: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeStyle.stampShape) private var stampShape
    @Environment(\.themeStyle.corner) private var corner

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
        switch stampShape {
        case .circle, .rounded:
            shape
                .fill(tint)
                .glow(tint.opacity(glow), radius: size * 0.2)
                .frame(width: size, height: size)
                .overlay {
                    IconImage(icon, size: size * 0.42)
                        .foregroundStyle(Palette.backgroundBottom)
                }
                .overlay {
                    shape
                        .strokeBorder(Palette.backgroundBottom, lineWidth: size * 0.08)
                }

        case .seal:
            Circle()
                .strokeBorder(tint, lineWidth: size * 0.06)
                .padding(size * 0.12)
                .overlay {
                    Circle()
                        .strokeBorder(tint, lineWidth: size * 0.06)
                }
                .frame(width: size, height: size)
                .overlay {
                    IconImage(icon, size: size * 0.36)
                        .foregroundStyle(tint)
                }
        }
    }
}

private extension IconSeal {
    var tint: Color {
        Color(hex: icon.color) ?? Palette.accent
    }

    var glow: Double {
        colorScheme == .light ? 0.25 : 0.5
    }

    var shape: RoundedRectangle {
        switch stampShape {
        case .circle, .seal:
            RoundedRectangle(cornerRadius: size / 2, style: .circular)

        case .rounded:
            RoundedRectangle(cornerRadius: corner.radius(size * 0.3), style: .continuous)
        }
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
