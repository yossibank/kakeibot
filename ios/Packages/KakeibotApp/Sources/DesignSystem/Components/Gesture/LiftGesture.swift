import SwiftUI
import UIKit

public struct LiftGesture: UIGestureRecognizerRepresentable {
    private let space: String
    private let onMove: (CGPoint) -> Void
    private let onEnd: () -> Void

    public init(
        in space: String,
        onMove: @escaping (CGPoint) -> Void,
        onEnd: @escaping () -> Void
    ) {
        self.space = space
        self.onMove = onMove
        self.onEnd = onEnd
    }
}

public extension LiftGesture {
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
        let location = context.converter.location(in: .named(space))

        switch recognizer.state {
        case .began, .changed:
            onMove(location)
        case .ended, .cancelled, .failed:
            onEnd()
        default:
            break
        }
    }
}
