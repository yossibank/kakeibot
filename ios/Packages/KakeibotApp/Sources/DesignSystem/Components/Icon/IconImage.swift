import Core
import SwiftUI

public struct IconImage: View {
    let icon: Icon?
    let size: CGFloat

    public init(
        _ icon: Icon?,
        size: CGFloat = 22
    ) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        Group {
            if let glyph = icon?.glyph {
                Image(systemName: glyph.symbolName)
                    .font(.system(size: size, weight: .light))
            } else {
                Text(icon?.emoji ?? icon?.text ?? "")
                    .font(.system(size: size))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .accessibilityHidden(true)
    }
}

#Preview {
    let now = Date()
    let glyph = Icon(
        emoji: nil,
        text: nil,
        glyph: .transit,
        color: "#3D5A80",
        createdAt: now,
        updatedAt: now
    )

    let emoji = Icon(
        emoji: "🍙",
        text: nil,
        color: "#E07A5F",
        createdAt: now,
        updatedAt: now
    )

    HStack {
        IconImage(glyph)
        IconImage(emoji)
    }
    .padding()
}
