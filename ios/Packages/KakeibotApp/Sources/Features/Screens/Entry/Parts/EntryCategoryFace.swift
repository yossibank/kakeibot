import Core
import DesignSystem
import SwiftUI

struct EntryCategoryFace: View {
    @Environment(\.themeStyle.corner) private var corner

    let category: EntryCategory
    let icon: Icon?
    let isLit: Bool
    let isLifted: Bool

    var body: some View {
        VStack(spacing: 4) {
            IconImage(icon, size: isLit ? 19 : 17)

            Text(category.name)
                .textFont(size: .caption)
                .lineLimit(1)
                .minimumScaleFactor(TextScale.floor)
        }
        .foregroundStyle(isLit ? Palette.accentStrong : Palette.subtext)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill, in: .rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
                .stroke(isLit ? Palette.outline : Color.clear, lineWidth: isLifted ? 1.2 : 1)
        }
        .contentShape(.rect)
    }
}

private extension EntryCategoryFace {
    var fill: Color {
        if isLifted {
            return Palette.panel
        }

        return isLit ? Palette.accent.opacity(.subtle) : Color.clear
    }
}
