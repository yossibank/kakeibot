import UIKit

final class DismissAttemptController: UIViewController {
    var isChanged = false
    var onAttempt: () -> Void = {}

    private var original: (any UIAdaptivePresentationControllerDelegate)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        takeDelegate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard
            let presentation = sheetPresentation,
            presentation.delegate === self
        else {
            return
        }

        presentation.delegate = original
    }
}

extension DismissAttemptController {
    static func changed(in controller: UIViewController) -> Self? {
        if let attempt = controller as? Self,
           attempt.isChanged {
            return attempt
        }

        for child in controller.children {
            if let attempt = changed(in: child) {
                return attempt
            }
        }

        return nil
    }

    func takeDelegate() {
        guard
            viewIfLoaded?.window != nil,
            let presentation = sheetPresentation,
            presentation.delegate !== self
        else {
            return
        }

        original = presentation.delegate
        presentation.delegate = self
    }
}

private extension DismissAttemptController {
    var sheetPresentation: UIPresentationController? {
        var sheet: UIViewController = self

        while let parent = sheet.parent {
            sheet = parent
        }

        guard sheet.presentingViewController != nil else {
            return nil
        }

        return sheet.presentationController
    }
}

extension DismissAttemptController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        original?.presentationControllerShouldDismiss?(presentationController) ?? true
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        onAttempt()
        original?.presentationControllerDidAttemptToDismiss?(presentationController)
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        original?.presentationControllerWillDismiss?(presentationController)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        original?.presentationControllerDidDismiss?(presentationController)
    }
}
