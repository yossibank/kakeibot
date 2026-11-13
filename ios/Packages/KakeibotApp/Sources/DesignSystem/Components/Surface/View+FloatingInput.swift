import SwiftUI

public extension View {
    func floatingInput(
        isPresented: Bool,
        onDismiss: @escaping () -> Void,
        @ViewBuilder card: () -> some View
    ) -> some View {
        modifier(
            FloatingInputLayer(
                isPresented: isPresented,
                onDismiss: onDismiss,
                card: card()
            )
        )
    }
}

struct FloatingInputLayer<Card: View>: ViewModifier {
    @State private var frame: CGRect = .zero
    @State private var keyboardTop: CGFloat?

    let isPresented: Bool
    let onDismiss: () -> Void
    let card: Card

    func body(content: Content) -> some View {
        let lift = keyboardTop.map { Self.lift(for: frame, keyboardTop: $0) } ?? 0

        ZStack {
            content

            if isPresented {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)
                    .transition(.opacity)
                    .zIndex(1)

                card
                    .padding(.horizontal, Self.inset)
                    .padding(.bottom, Self.inset + lift)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(Self.transition)
                    .zIndex(1)
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            self.frame = frame
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: Self.keyboardChange)) { note in
            follow(note)
        }
    }
}

extension FloatingInputLayer {
    static func lift(
        for layer: CGRect,
        keyboardTop: CGFloat
    ) -> CGFloat {
        max(0, layer.maxY - keyboardTop)
    }
}

private extension FloatingInputLayer {
    static var inset: CGFloat {
        12
    }

    static var transition: AnyTransition {
        .asymmetric(
            insertion: .opacity,
            removal: .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
        )
    }

    static var keyboardMotion: Animation {
        .interpolatingSpring(mass: 3, stiffness: 1000, damping: 500)
    }

    static var keyboardChange: Notification.Name {
        UIResponder.keyboardWillChangeFrameNotification
    }

    func follow(_ note: Notification) {
        let info = note.userInfo
        let end = info?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect

        guard let end else {
            return
        }

        withAnimation(Self.keyboardMotion) {
            keyboardTop = end.minY
        }
    }
}
