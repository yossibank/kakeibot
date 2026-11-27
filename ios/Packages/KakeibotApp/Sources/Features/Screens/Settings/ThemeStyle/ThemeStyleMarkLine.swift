import Core
import DesignSystem
import SwiftUI

struct ThemeStyleMarkLine: View {
    @Environment(\.themeStyle.corner) private var corner

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                cornerMark

                stampMark

                backdropMark
            }

            HStack(spacing: 8) {
                cornerMark

                stampMark
            }

            Color.clear
                .frame(width: 0, height: 0)
        }
    }
}

private extension ThemeStyleMarkLine {
    var cornerMark: some View {
        ThemeStyleCornerMark(corner: corner, color: Palette.subtext, size: Self.size)
    }

    var stampMark: some View {
        IconSeal(.styleSample(.star), size: Self.size)
    }

    var backdropMark: some View {
        let shape = RoundedRectangle(cornerRadius: 4)

        return Backdrop(scale: 0.3)
            .frame(width: Self.size, height: Self.size)
            .clipShape(shape)
            .overlay {
                shape
                    .strokeBorder(Palette.line, lineWidth: 1)
            }
    }
}

private extension ThemeStyleMarkLine {
    static let size: CGFloat = 18
}
