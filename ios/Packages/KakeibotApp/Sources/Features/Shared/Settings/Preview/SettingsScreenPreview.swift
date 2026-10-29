import DesignSystem
import SwiftUI

struct SettingsScreenPreview<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(
                width: Self.screenSize.width,
                height: Self.screenSize.height,
                alignment: .top
            )
            .background(Palette.background)
            .allowsHitTesting(false)
            .scaleEffect(Self.scale)
            .frame(
                width: Self.screenSize.width * Self.scale,
                height: Self.screenSize.height * Self.scale
            )
            .clipShape(Self.screenShape)
            .overlay {
                Self.screenShape
                    .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
            }
            .shadow(color: Palette.shadow.opacity(.muted), radius: 16, y: 6)
    }
}

private extension SettingsScreenPreview {
    static var screenShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28)
    }
}

private extension SettingsScreenPreview {
    static var screenSize: CGSize {
        CGSize(width: 393, height: 780)
    }

    static var scale: CGFloat {
        0.5
    }
}
