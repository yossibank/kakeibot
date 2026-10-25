import SwiftUI

public enum PageSwipeDirection: Sendable {
    case forward
    case backward
}

public extension View {
    func onPageSwipe(
        following slide: Binding<PageSlide>,
        canMove: @escaping (PageSwipeDirection) -> Bool = { _ in true },
        perform action: @escaping (PageSwipeDirection) -> Void
    ) -> some View {
        gesture(
            SwipeGesture { x in
                let direction: PageSwipeDirection = x < 0 ? .forward : .backward
                let reach = canMove(direction) ? x : x * pageSwipeResistance
                PageSlide.follow(slide, by: reach)
            } onEnd: { x in
                if let direction = PageSwipeDirection(swipe: x) {
                    action(direction)
                }

                if slide.wrappedValue.isDragging {
                    PageSlide.settle(slide)
                }
            }
        )
    }
}

private extension PageSwipeDirection {
    init?(swipe x: CGFloat) {
        if x < -pageSwipeThreshold {
            self = .forward
        } else if x > pageSwipeThreshold {
            self = .backward
        } else {
            return nil
        }
    }
}

private let pageSwipeThreshold: CGFloat = 60
private let pageSwipeResistance: CGFloat = 0.25
