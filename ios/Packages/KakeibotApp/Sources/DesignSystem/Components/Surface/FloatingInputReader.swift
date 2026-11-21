import SwiftUI

public struct FloatingInputReader<Content: View>: View {
    let content: (GeometryProxy) -> Content

    public init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            content(proxy)
        }
        .ignoresSafeArea(.keyboard)
    }
}
