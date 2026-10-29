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

private struct FloatingInputLayer<Card: View>: ViewModifier {
    let isPresented: Bool
    let onDismiss: () -> Void
    let card: Card

    func body(content: Content) -> some View {
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
                    .padding(.bottom, Self.inset)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(Self.transition)
                    .zIndex(1)
            }
        }
    }
}

private extension FloatingInputLayer {
    static var inset: CGFloat {
        12
    }

    static var transition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }
}
