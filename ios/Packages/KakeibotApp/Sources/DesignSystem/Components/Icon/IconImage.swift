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
                    .font(.system(size: textSize))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(width: size * 1.4, height: size * 1.4)
    }
}

private extension IconImage {
    var textSize: CGFloat {
        guard icon?.emoji == nil, let text = icon?.text else {
            return size
        }

        switch text.count {
        case ...1: return size
        case 2: return size * 0.7
        default: return size * 0.55
        }
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
