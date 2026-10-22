import SwiftUI

public struct LaunchView: View {
    @State private var isLeaving = false

    let isReady: Bool
    let onLeave: () -> Void
    let onFinish: () -> Void

    public init(
        isReady: Bool,
        onLeave: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.isReady = isReady
        self.onLeave = onLeave
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color("LaunchBackground", bundle: .main)

            Image("LaunchMark", bundle: .main)
        }
        .ignoresSafeArea()
        .opacity(isLeaving ? 0 : 1)
        .allowsHitTesting(!isLeaving)
        .onChange(of: isReady, initial: true) {
            if isReady {
                leave()
            }
        }
    }
}

private extension LaunchView {
    func leave() {
        onLeave()

        withAnimation(.easeOut(duration: 0.25)) {
            isLeaving = true
        } completion: {
            onFinish()
        }
    }
}

#Preview {
    LaunchView(isReady: false) {} onFinish: {}
}
