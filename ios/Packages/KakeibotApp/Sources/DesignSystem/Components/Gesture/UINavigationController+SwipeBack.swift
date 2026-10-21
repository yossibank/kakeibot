import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard viewControllers.count > 1 else {
            return false
        }

        guard
            let top = topViewController,
            let attempt = DismissAttemptController.changed(in: top)
        else {
            return true
        }

        attempt.onAttempt()
        return false
    }
}
