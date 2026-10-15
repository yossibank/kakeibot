import SwiftUI
import UIKit

struct TagLiftGesture: UIGestureRecognizerRepresentable {
    let onMove: (CGFloat) -> Void
    let onEnd: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(
        context: Context
    ) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.3
        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UILongPressGestureRecognizer,
        context: Context
    ) {
        let x = recognizer.location(in: nil).x

        switch recognizer.state {
        case .began:
            context.coordinator.startX = x
            onMove(0)
        case .changed:
            onMove(x - context.coordinator.startX)
        case .ended, .cancelled, .failed:
            onEnd()
        default:
            break
        }
    }
}

extension TagLiftGesture {
    final class Coordinator {
        var startX: CGFloat = 0
    }
}
