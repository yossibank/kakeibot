import SwiftUI

struct PageSlide: Equatable {
    var offset: CGFloat
    var opacity: Double
    var isDragging = false
    var animation: Animation?

    init() {
        self.init(offset: 0, opacity: 1)
    }
}

public struct PageSlideProxy {
    let value: PageSlide
    let binding: Binding<PageSlide>
}

public extension PageSlideProxy {
    @MainActor
    func run(
        forward: Bool,
        change: @escaping @MainActor () -> Void
    ) {
        PageSlide.run(binding, forward: forward, change: change)
    }
}

extension PageSlide {
    static let distance: CGFloat = 40
    static let outDuration = 0.15
    static let fadeDistance: CGFloat = 400
    static let minimumOpacity = 0.4

    @MainActor
    static func follow(
        _ slide: Binding<PageSlide>,
        by x: CGFloat
    ) {
        let fade = Double(abs(x) / fadeDistance)
        let opacity = max(1 - fade, minimumOpacity)

        slide.wrappedValue = PageSlide(offset: x, opacity: opacity, isDragging: true)
    }

    @MainActor
    static func settle(_ slide: Binding<PageSlide>) {
        slide.wrappedValue = PageSlide(
            offset: 0,
            opacity: 1,
            animation: .smooth(duration: inDuration)
        )
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

        slide.wrappedValue = PageSlide(
            offset: out,
            opacity: 0,
            animation: .easeIn(duration: outDuration)
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(outDuration))

            change()
            slide.wrappedValue = PageSlide(offset: entry, opacity: 0)

            try? await Task.sleep(for: .seconds(frameDuration))

            slide.wrappedValue = PageSlide(
                offset: 0,
                opacity: 1,
                animation: .smooth(duration: inDuration)
            )
        }
    }
}

private extension PageSlide {
    static let frameDuration = 1.0 / 60
    static let inDuration = 0.5

    init(
        offset: CGFloat,
        opacity: Double,
        isDragging: Bool = false,
        animation: Animation? = nil
    ) {
        self.offset = offset
        self.opacity = opacity
        self.isDragging = isDragging
        self.animation = animation
    }
}

public extension View {
    func pageSlide(_ slide: PageSlideProxy) -> some View {
        animation(slide.value.animation) { content in
            content
                .offset(x: slide.value.offset)
                .opacity(slide.value.opacity)
        }
    }

    func pageSlide(
        _ slide: PageSlideProxy,
        page: some Hashable
    ) -> some View {
        id(page)
            .transition(.identity)
            .pageSlide(slide)
    }
}
