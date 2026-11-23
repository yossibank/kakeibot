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
                DismissAttemptReader(isChanged: isChanged) {
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

private struct DismissAttemptReader {
    let isChanged: Bool
    let onAttempt: () -> Void
}

extension DismissAttemptReader: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DismissAttemptController {
        DismissAttemptController()
    }

    func updateUIViewController(
        _ controller: DismissAttemptController,
        context: Context
    ) {
        controller.isChanged = isChanged
        controller.onAttempt = onAttempt

        DispatchQueue.main.async {
            controller.takeDelegate()
        }
    }
}
