import SwiftUI

public struct FittedSheet<Content: View>: View {
    @State private var detent: PresentationDetent = .height(Self.minHeight)

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
                    detent = .height(max(height, Self.minHeight))
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([detent], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.drawer)
        .preferredColorScheme(.dark)
    }
}

private extension FittedSheet {
    static var minHeight: CGFloat {
        120
    }
}
