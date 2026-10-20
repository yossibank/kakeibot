import SwiftUI

public struct FittedSheet<Content: View>: View {
    @State private var contentHeight: CGFloat = 0

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(max(contentHeight, 120))])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.panel)
    }
}
