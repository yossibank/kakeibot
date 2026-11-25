import SwiftUI

public struct PageSlideReader<Content: View>: View {
    @State private var slide = PageSlide()

    let content: (PageSlideProxy) -> Content

    public init(@ViewBuilder content: @escaping (PageSlideProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(PageSlideProxy(value: slide, binding: $slide))
    }
}
