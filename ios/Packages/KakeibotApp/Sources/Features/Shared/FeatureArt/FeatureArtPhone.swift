import Core
import DesignSystem
import SwiftUI

struct FeatureArtPhone<Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(Palette.text.opacity(0.7))
                .frame(width: 22, height: 5)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 7)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(width: 84, height: 150)
        .background(Palette.background, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.text.opacity(0.75), lineWidth: 2.5)
        }
        .shadow(color: Palette.shadow.opacity(0.5), radius: 5, y: 2)
    }
}
