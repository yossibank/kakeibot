import Core
import SwiftUI

public struct IconBadge: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?
    let systemImage: String?
    let size: CGFloat

    public init(
        _ icon: Icon?,
        size: CGFloat = 40
    ) {
        self.icon = icon
        self.systemImage = nil
        self.size = size
    }

    public init(
        systemImage: String,
        size: CGFloat = 40
    ) {
        self.icon = nil
        self.systemImage = systemImage
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(
            cornerRadius: corner.radius(size * 0.3),
            style: .continuous
        )
        .fill(tint.opacity(0.18))
        .frame(width: size, height: size)
        .overlay {
            mark
                .foregroundStyle(tint)
        }
    }
}

private extension IconBadge {
    var tint: Color {
        if systemImage != nil {
            return Palette.accent
        }

        return icon.flatMap { Color(hex: $0.color) } ?? .secondary
    }

    @ViewBuilder
    var mark: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.45, weight: .light))
        } else {
            IconImage(icon, size: size * 0.45)
        }
    }
}

#Preview {
    let now = Date()
    let emoji = Icon(
        emoji: "🍙",
        text: nil,
        color: "#E07A5F",
        createdAt: now,
        updatedAt: now
    )
    let text = Icon(
        emoji: nil,
        text: "給料",
        color: "#2A9D8F",
        createdAt: now,
        updatedAt: now
    )

    HStack {
        IconBadge(emoji)
        IconBadge(text)
        IconBadge(nil)
    }
    .padding()
}
