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
            .confirmationDialog(
                "入力した内容を捨てますか",
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                Button("捨てて閉じる", role: .destructive, action: onDiscard)
                Button("入力を続ける", role: .cancel) {}
            }
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

        guard
            let presentation = presentationController,
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
