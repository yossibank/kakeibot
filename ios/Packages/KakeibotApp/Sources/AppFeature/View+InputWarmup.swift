import SwiftUI
import UIKit

extension View {
    func warmsUpInput() -> some View {
        background(InputWarmup())
    }
}

private struct InputWarmup: UIViewRepresentable {
    func makeUIView(context: Context) -> WarmupView {
        WarmupView()
    }

    func updateUIView(
        _ uiView: WarmupView,
        context: Context
    ) {}
}

private final class WarmupView: UIView {
    private var isWarmedUp = false

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard let window, !isWarmedUp else {
            return
        }

        isWarmedUp = true
        let field = UITextField()
        window.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
        UISelectionFeedbackGenerator().prepare()
        UIImpactFeedbackGenerator(style: .light).prepare()
    }
}
