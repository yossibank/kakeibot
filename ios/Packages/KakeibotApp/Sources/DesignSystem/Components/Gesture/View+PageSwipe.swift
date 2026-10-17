import SwiftUI

public enum PageSwipeDirection: Sendable {
    case forward
    case backward
}

public extension View {
    func onPageSwipe(
        perform action: @escaping (PageSwipeDirection) -> Void
    ) -> some View {
        gesture(
            SwipeGesture { _ in
            } onEnd: { x in
                if x < -pageSwipeThreshold {
                    action(.forward)
                } else if x > pageSwipeThreshold {
                    action(.backward)
                }
            }
        )
    }
}

private let pageSwipeThreshold: CGFloat = 60
