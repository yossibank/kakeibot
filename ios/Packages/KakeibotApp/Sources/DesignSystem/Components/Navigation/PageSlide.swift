import SwiftUI

public struct PageSlide: Equatable, Sendable {
    public var offset: CGFloat
    public var opacity: Double
    public var isDragging = false

    public init() {
        self.init(offset: 0, opacity: 1)
    }
}

public extension PageSlide {
    static let distance: CGFloat = 56
    static let outDuration = 0.12
    static let fadeDistance: CGFloat = 400
    static let minimumOpacity = 0.4

    @MainActor
    static func follow(
        _ slide: Binding<PageSlide>,
        by x: CGFloat
    ) {
        let fade = Double(abs(x) / fadeDistance)

        var transaction = Transaction()

        transaction.disablesAnimations = true

        withTransaction(transaction) {
            slide.wrappedValue = PageSlide(
                offset: x,
                opacity: max(1 - fade, minimumOpacity),
                isDragging: true
            )
        }
    }

    @MainActor
    static func settle(_ slide: Binding<PageSlide>) {
        withAnimation(.snappy) {
            slide.wrappedValue = PageSlide()
        }
    }

    @MainActor
    static func run(
        _ slide: Binding<PageSlide>,
        forward: Bool,
        change: @escaping @MainActor () -> Void
    ) {
        let current = slide.wrappedValue.offset
        let start = forward ? min(current, 0) : max(current, 0)
        let out = start + (forward ? -distance : distance)
        let entry = forward ? distance : -distance

        withAnimation(.easeIn(duration: outDuration)) {
            slide.wrappedValue = PageSlide(offset: out, opacity: 0)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(outDuration))

            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                change()

                slide.wrappedValue = PageSlide(offset: entry, opacity: 0)
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
        opacity: Double,
        isDragging: Bool = false
    ) {
        self.offset = offset
        self.opacity = opacity
        self.isDragging = isDragging
    }
}
