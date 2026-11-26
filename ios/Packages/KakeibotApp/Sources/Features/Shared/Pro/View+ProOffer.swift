import FeatureModels
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

private struct ProOfferModifier: ViewModifier {
    @State private var model = ProOfferModel()

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
                            model.showPro()
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

                model.closePro()
                onUnlock()
            }
            .proDestination(
                isPresented: Bindable(model.state).presented[.pro],
                inSheet: presentsInSheet
            ) {
                ProView(
                    model: ProPurchaseModel(store: store),
                    onUnlock: onUnlock
                )
            }
    }
}
