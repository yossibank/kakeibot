import SwiftUI
import UIKit

struct SwipeGesture: UIGestureRecognizerRepresentable {
    private let onMove: (CGFloat) -> Void
    private let onEnd: (CGFloat) -> Void

    init(
        onMove: @escaping (CGFloat) -> Void,
        onEnd: @escaping (CGFloat) -> Void
    ) {
        self.onMove = onMove
        self.onEnd = onEnd
    }
}

extension SwipeGesture {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(
            _ recognizer: UIGestureRecognizer
        ) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else {
                return false
            }

            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(
        context: Context
    ) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        let x = recognizer.translation(in: recognizer.view).x

        switch recognizer.state {
        case .began, .changed:
            onMove(x)
        case .ended:
            onEnd(x)
        case .cancelled, .failed:
            onEnd(0)
        default:
            break
        }
    }
}
