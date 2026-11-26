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

    private var caught: Set<UIPress> = []
    private var observers: [NSObjectProtocol] = []

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            stopObserving()
            NotificationCenter.default.post(name: Self.didLeaveWindow, object: self)
        } else {
            startObserving()
            catchKeys()
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

        caught.formUnion(presses.subtracting(unhandled))

        if !unhandled.isEmpty {
            super.pressesBegan(unhandled, with: event)
        }
    }

    override func pressesEnded(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {
        let rest = release(presses)

        if !rest.isEmpty {
            super.pressesEnded(rest, with: event)
        }
    }

    override func pressesCancelled(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {
        let rest = release(presses)

        if !rest.isEmpty {
            super.pressesCancelled(rest, with: event)
        }
    }
}

private extension KeyCatcherView {
    static let didLeaveWindow = Notification.Name("KeyCatcherView.didLeaveWindow")

    static let retakeTriggers: [Notification.Name] = [
        .GCKeyboardDidConnect,
        UITextField.textDidEndEditingNotification,
        UITextView.textDidEndEditingNotification,
        didLeaveWindow
    ]

    var isCovered: Bool {
        var responder = next

        while let current = responder {
            if let controller = current as? UIViewController {
                return sequence(first: controller, next: \.parent)
                    .contains { $0.presentedViewController != nil }
            }

            responder = current.next
        }

        return false
    }

    func startObserving() {
        guard observers.isEmpty else {
            return
        }

        observers = Self.retakeTriggers.map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.catchKeys()
                }
            }
        }
    }

    func stopObserving() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers = []
    }

    func catchKeys() {
        guard
            window != nil,
            GCKeyboard.coalesced != nil,
            !isFirstResponder,
            !isCovered,
            UIResponder.current == nil
        else {
            return
        }

        becomeFirstResponder()
    }

    func release(_ presses: Set<UIPress>) -> Set<UIPress> {
        defer {
            caught.subtract(presses)
        }

        return presses.subtracting(caught)
    }
}

private extension UIResponder {
    weak static var found: UIResponder?

    static var current: UIResponder? {
        found = nil

        UIApplication.shared.sendAction(
            #selector(reportFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

        return found
    }

    @objc func reportFirstResponder() {
        Self.found = self
    }
}
