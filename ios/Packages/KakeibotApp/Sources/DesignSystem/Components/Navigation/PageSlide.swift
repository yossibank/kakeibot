import SwiftUI

public struct PageSlide: Equatable, Sendable {
    public var offset: CGFloat
    public var opacity: Double

    public init() {
        self.init(offset: 0, opacity: 1)
    }
}

public extension PageSlide {
    static let distance: CGFloat = 56

    @MainActor
    static func run(
        _ slide: Binding<PageSlide>,
        forward: Bool,
        change: @escaping () -> Void
    ) {
        let out = forward ? -distance : distance

        withAnimation(.easeIn(duration: 0.12)) {
            slide.wrappedValue = PageSlide(offset: out, opacity: 0)
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                change()
                slide.wrappedValue = PageSlide(offset: -out, opacity: 0)
            }

            withAnimation(.snappy(duration: 0.28)) {
                slide.wrappedValue = PageSlide()
            }
        }
    }
}

public extension View {
    func pageSlide(_ slide: PageSlide) -> some View {
        offset(x: slide.offset)
            .opacity(slide.opacity)
    }
}

private extension PageSlide {
    init(
        offset: CGFloat,
        opacity: Double
    ) {
        self.offset = offset
        self.opacity = opacity
    }
}
