import SwiftUI

public extension View {
    func proOffer(
        _ feature: String?,
        onCancel: @escaping () -> Void = {},
        onUnlock: @escaping () -> Void
    ) -> some View {
        modifier(
            ProOfferModifier(
                feature: feature,
                onCancel: onCancel,
                onUnlock: onUnlock
            )
        )
    }
}

private struct ProOfferModifier: ViewModifier {
    @State private var isShowingPro = false

    @Environment(\.isPro) private var isPro
    @Environment(\.proStore) private var store

    let feature: String?
    let onCancel: () -> Void
    let onUnlock: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let feature {
                    ProOfferCard(
                        model: ProPurchaseModel(store: store),
                        feature: feature,
                        onUnlock: onUnlock,
                        onLearnMore: {
                            isShowingPro = true
                        },
                        onCancel: onCancel
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.25), value: feature)
            .onChange(of: isPro) { _, isPro in
                guard
                    isPro,
                    feature != nil
                else {
                    return
                }

                isShowingPro = false
                onUnlock()
            }
            .navigationDestination(isPresented: $isShowingPro) {
                ProView(
                    model: ProPurchaseModel(store: store),
                    onUnlock: onUnlock
                )
            }
    }
}
