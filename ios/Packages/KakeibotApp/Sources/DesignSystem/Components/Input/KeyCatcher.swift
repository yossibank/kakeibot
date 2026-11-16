import GameController
import SwiftUI
import UIKit

struct KeyCatcher: UIViewRepresentable {
    let onType: (String) -> Bool

    func makeUIView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()

        view.onType = onType

        return view
    }

    func updateUIView(
        _ view: KeyCatcherView,
        context: Context
    ) {
        view.onType = onType
    }
}

final class KeyCatcherView: UIView {
    override var canBecomeFirstResponder: Bool {
        true
    }

    var onType: (String) -> Bool = { _ in false }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil, GCKeyboard.coalesced != nil {
            becomeFirstResponder()
        }
    }

    override func pressesBegan(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {
        let unhandled = presses.filter { press in
            guard let characters = press.key?.characters else {
                return true
            }

            return !onType(characters)
        }

        if !unhandled.isEmpty {
            super.pressesBegan(unhandled, with: event)
        }
    }
}
