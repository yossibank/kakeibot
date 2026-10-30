import Core
import DesignSystem
import SwiftUI

struct ThemeStyleMarks: View {
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

private extension ThemeStyleMarks {
    static let size: CGFloat = 18

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

struct ThemeStyleCornerMark: View {
    let corner: ThemeCorner
    let color: Color
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: corner.radius(size * 2 / 3))
            .stroke(color, lineWidth: size / 12)
            .frame(width: size * 2, height: size * 2)
            .frame(width: size, height: size, alignment: .topLeading)
            .offset(x: size * 0.15, y: size * 0.15)
            .frame(width: size, height: size)
            .clipped()
    }
}
