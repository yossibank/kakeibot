import Core
import DesignSystem
import SwiftUI

struct BuddyOption: View {
    @Environment(\.themeStyle.corner) private var corner

    let buddy: Buddy?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let lineWidth: CGFloat = isSelected ? 1.5 : 1

        Button(action: action) {
            VStack(spacing: 8) {
                face
                    .frame(width: 64, height: 64)

                Text(title)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(stroke, lineWidth: lineWidth)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension BuddyOption {
    @ViewBuilder
    var face: some View {
        if let buddy {
            BuddyFace(buddy, size: 64)
        } else {
            Image(systemName: "eye.slash")
                .sansFont(.title, weight: .ultraLight)
                .foregroundStyle(Palette.subtext)
        }
    }

    var title: String {
        buddy?.defaultName ?? "出さない"
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(18))
    }
}
