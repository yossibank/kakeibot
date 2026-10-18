import SwiftUI
import UIKit

public extension View {
    func confirmsDiscard(
        when isChanged: Bool,
        isPresented: Binding<Bool>,
        onDiscard: @escaping () -> Void
    ) -> some View {
        interactiveDismissDisabled(isChanged)
            .background {
                DismissAttemptReader {
                    isPresented.wrappedValue = true
                }
            }
            .confirmation(
                isPresented: isPresented,
                systemImage: "pencil.slash",
                title: "保存せずに閉じますか",
                message: "入力した内容は残りません",
                keepTitle: "入力に戻る",
                confirmTitle: "保存せずに閉じる",
                onConfirm: onDiscard
            )
    }
}

private struct DismissAttemptReader: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> DismissAttemptController {
        DismissAttemptController()
    }

    func updateUIViewController(
        _ controller: DismissAttemptController,
        context: Context
    ) {
        controller.onAttempt = onAttempt
    }
}

private final class DismissAttemptController: UIViewController {
    var onAttempt: () -> Void = {}

    private var original: (any UIAdaptivePresentationControllerDelegate)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let presentation = presentationController,
              presentation.delegate !== self else {
            return
        }

        original = presentation.delegate
        presentation.delegate = self
    }
}

extension DismissAttemptController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        original?.presentationControllerShouldDismiss?(
            presentationController
        ) ?? true
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        onAttempt()

        original?.presentationControllerDidAttemptToDismiss?(
            presentationController
        )
    }

    func presentationControllerWillDismiss(
        _ presentationController: UIPresentationController
    ) {
        original?.presentationControllerWillDismiss?(presentationController)
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        original?.presentationControllerDidDismiss?(presentationController)
    }
}
