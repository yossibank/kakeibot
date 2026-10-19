import SwiftUI

public struct Chip: View {
    let title: String
    let systemImage: String
    let isHighlighted: Bool

    public init(
        _ title: String,
        systemImage: String,
        isHighlighted: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isHighlighted = isHighlighted
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)

            Text(title)
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.sans(.micro, weight: .semibold))
                .foregroundStyle(Palette.subtext)
        }
        .font(.caption)
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            isHighlighted ? Palette.accent.opacity(.subtle) : Color.clear,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    isHighlighted ? Palette.accent : Palette.line,
                    lineWidth: 1
                )
        }
    }
}

private extension Chip {
    var foreground: Color {
        isHighlighted ? Palette.accentLight : Palette.text.opacity(.strong)
    }
}

#Preview {
    HStack {
        Chip("財布", systemImage: "wallet.bifold")
        Chip("9/10（木）", systemImage: "calendar", isHighlighted: true)
    }
    .padding()
    .background(Palette.background)
}
