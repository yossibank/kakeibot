import SwiftUI

public extension View {
    func proOffer(
        _ feature: String?,
        presentsInSheet: Bool = false,
        onCancel: @escaping () -> Void = {},
        onUnlock: @escaping () -> Void
    ) -> some View {
        modifier(
            ProOfferModifier(
                feature: feature,
                presentsInSheet: presentsInSheet,
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
    let presentsInSheet: Bool
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
            .proDestination(
                isPresented: $isShowingPro,
                inSheet: presentsInSheet
            ) {
                ProView(
                    model: ProPurchaseModel(store: store),
                    onUnlock: onUnlock
                )
            }
    }
}

private extension View {
    @ViewBuilder
    func proDestination(
        isPresented: Binding<Bool>,
        inSheet: Bool,
        @ViewBuilder destination: @escaping () -> some View
    ) -> some View {
        if inSheet {
            sheet(isPresented: isPresented) {
                NavigationStack {
                    destination()
                }
            }
        } else {
            navigationDestination(
                isPresented: isPresented,
                destination: destination
            )
        }
    }
}
