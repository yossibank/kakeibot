import Core
import SwiftUI

public struct EntryRouteChip: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let isDestination: Bool

    public init(
        _ title: String,
        isDestination: Bool
    ) {
        self.title = title
        self.isDestination = isDestination
    }

    public var body: some View {
        Text(title)
            .textFont(.caption)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(fill, in: shape)
            .overlay {
                if !isDestination {
                    shape.stroke(Palette.outline, lineWidth: 1)
                }
            }
    }
}

private extension EntryRouteChip {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(8))
    }

    var textColor: Color {
        isDestination ? Palette.accentStrong : Palette.subtext
    }

    var fill: Color {
        isDestination ? Palette.accent.opacity(.subtle) : Color.clear
    }
}

#Preview {
    HStack(spacing: 4) {
        EntryRouteChip("みずほ銀行", isDestination: false)

        Image(systemName: "arrow.right")

        EntryRouteChip("財布", isDestination: true)
    }
    .padding()
}
