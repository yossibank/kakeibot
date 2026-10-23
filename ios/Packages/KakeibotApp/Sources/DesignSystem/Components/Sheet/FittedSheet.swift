import SwiftUI
import UIKit

public struct FittedSheet<Content: View>: View {
    @State private var contentHeight: CGFloat = 0

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background {
            FittedDetent(height: max(contentHeight, 120))
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.panel)
    }
}

private struct FittedDetent: UIViewControllerRepresentable {
    let height: CGFloat

    func makeUIViewController(context: Context) -> FittedDetentController {
        FittedDetentController()
    }

    func updateUIViewController(
        _ controller: FittedDetentController,
        context: Context
    ) {
        controller.height = height
    }
}

final class FittedDetentController: UIViewController {
    var height: CGFloat = 0 {
        didSet {
            if height != oldValue {
                apply(animated: isAppeared)
            }
        }
    }

    private var isAppeared = false

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        apply(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppeared = true
    }
}

private extension FittedDetentController {
    func apply(animated: Bool) {
        guard let sheet = sheetPresentationController else {
            return
        }

        let height = height

        let change = {
            sheet.detents = [.custom { _ in height }]
        }

        if animated {
            sheet.animateChanges(change)
        } else {
            change()
        }
    }
}
