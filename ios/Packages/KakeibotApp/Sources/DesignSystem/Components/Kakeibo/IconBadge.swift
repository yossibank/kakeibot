import Core
import SwiftUI

@MainActor
public struct IconBadge {
    let icon: Icon?
    let size: CGFloat

    public init(
        _ icon: Icon?,
        size: CGFloat = 40
    ) {
        self.icon = icon
        self.size = size
    }
}

extension IconBadge: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(tint.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                Text(label)
                    .font(.system(size: size * 0.5))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(tint)
                    .padding(size * 0.1)
            }
            .accessibilityHidden(true)
    }
}

private extension IconBadge {
    var tint: Color {
        icon.flatMap { Color(hex: $0.color) } ?? .secondary
    }

    var label: String {
        icon?.emoji ?? icon?.text ?? ""
    }
}

#Preview {
    let now = Date()
    let emoji = Icon(emoji: "🍙", text: nil, color: "#E07A5F", createdAt: now, updatedAt: now)
    let text = Icon(emoji: nil, text: "給料", color: "#2A9D8F", createdAt: now, updatedAt: now)

    HStack {
        IconBadge(emoji)
        IconBadge(text)
        IconBadge(nil)
    }
    .padding()
}
