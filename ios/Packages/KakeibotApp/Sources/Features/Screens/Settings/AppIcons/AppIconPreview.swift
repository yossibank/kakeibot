import DesignSystem
import SwiftUI

struct AppIconPreview: View {
    let choice: AppIconChoice
    let size: CGFloat

    var body: some View {
        let look = choice.look

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(Self.gradient(look.background))

            Image("AppIconDial", bundle: .main)
                .resizable()
                .foregroundStyle(Self.gradient(look.dial))

            Image("AppIconYen", bundle: .main)
                .resizable()
                .foregroundStyle(Self.gradient(look.yen))
        }
        .frame(width: size, height: size)
    }
}

private extension AppIconPreview {
    static func gradient(_ hexes: [String]) -> LinearGradient {
        LinearGradient(
            colors: hexes.compactMap { Color(hex: $0) },
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
