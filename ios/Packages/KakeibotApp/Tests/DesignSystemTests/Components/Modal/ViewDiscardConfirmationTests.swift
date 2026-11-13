@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct ViewDiscardConfirmationTests {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))

    @Test
    func takesTheDelegateOfThePresentedSheet() {
        let sheet = PresentedSheet()
        let attempt = attach(to: sheet)

        attempt.takeDelegate()

        #expect(sheet.presentationController?.delegate === attempt)
    }

    @Test
    func leavesTheRootAloneWhenNotPresented() {
        let root = UIViewController()
        let attempt = attach(to: root)

        attempt.takeDelegate()

        #expect(root.presentationController?.delegate == nil)
    }
}

extension ViewDiscardConfirmationTests {
    final class PresentedSheet: UIViewController {
        override var presentingViewController: UIViewController? {
            presenter
        }

        private let presenter = UIViewController()
    }
}

private extension ViewDiscardConfirmationTests {
    func attach(to controller: UIViewController) -> DismissAttemptController {
        let attempt = DismissAttemptController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.addChild(attempt)
        controller.view.addSubview(attempt.view)
        attempt.didMove(toParent: controller)
        return attempt
    }
}
