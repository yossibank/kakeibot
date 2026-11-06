import SwiftUI

public struct TwoColumnStack<Content: View>: View {
    @State private var isWide = false

    let spacing: CGFloat
    let minWidth: CGFloat
    let content: Content

    public init(
        spacing: CGFloat,
        minWidth: CGFloat = 560,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.minWidth = minWidth
        self.content = content()
    }

    public var body: some View {
        Group {
            if isWide {
                TwoColumnLayout(spacing: spacing, minWidth: minWidth) {
                    content
                }
            } else {
                LazyVStack(alignment: .leading, spacing: spacing) {
                    content
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width >= minWidth
        } action: { isWide in
            self.isWide = isWide
        }
    }
}
