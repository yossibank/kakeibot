import Core
import DesignSystem
import SwiftUI

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
