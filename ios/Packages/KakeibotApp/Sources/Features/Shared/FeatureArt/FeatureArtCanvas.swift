import DesignSystem
import SwiftUI

struct FeatureArtCanvas<Content: View>: View {
    let size: CGSize
    let content: Content

    init(
        width: CGFloat,
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.size = CGSize(width: width, height: height)
        self.content = content()
    }

    var body: some View {
        Color.clear
            .aspectRatio(size.width / size.height, contentMode: .fit)
            .frame(maxWidth: size.width * Self.maxScale)
            .overlay {
                GeometryReader { proxy in
                    content
                        .frame(width: size.width, height: size.height)
                        .environment(\.themeStyle.textSize, .standard)
                        .scaleEffect(proxy.size.width / size.width, anchor: .topLeading)
                }
            }
            .frame(maxWidth: .infinity)
    }
}

private extension FeatureArtCanvas {
    static var maxScale: CGFloat {
        1.15
    }
}
