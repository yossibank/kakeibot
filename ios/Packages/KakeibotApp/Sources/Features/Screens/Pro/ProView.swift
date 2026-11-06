import DesignSystem
import SwiftUI

public struct ProView: View {
    @State private var model: ProPurchaseModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPro) private var isPro

    private let onUnlock: () -> Void

    public init(
        model: ProPurchaseModel,
        onUnlock: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onUnlock = onUnlock
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("Pro")

            ScrollView {
                VStack(spacing: 20) {
                    ProHero(price: model.price)

                    ForEach(ProFeature.all) { feature in
                        ProFeatureCard(feature: feature)
                    }

                    ProComparison()
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            purchaseBar
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(model.isWorking)
        .task {
            await model.load()
        }
    }
}

private extension ProView {
    @ViewBuilder
    var purchaseBar: some View {
        if isPro {
            Label("購入済みです。Pro の機能をすべて使えます", systemImage: "checkmark.seal.fill")
                .textFont(.footnote)
                .foregroundStyle(Palette.accentStrong)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
        } else {
            VStack(spacing: 4) {
                Button {
                    purchase()
                } label: {
                    workLabel(
                        model.purchaseTitle,
                        work: .purchase,
                        tint: Palette.backgroundBottom
                    )
                    .textFont(.subheadline, weight: .bold)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .goldFace()
                }
                .buttonStyle(.plain)
                .opacity(opacity(of: .purchase))

                Button {
                    restore()
                } label: {
                    workLabel(
                        "購入を復元",
                        work: .restore,
                        tint: Palette.subtext
                    )
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .opacity(opacity(of: .restore))
            }
            .allowsHitTesting(!model.isWorking)
        }
    }

    func workLabel(
        _ title: String,
        work: ProPurchaseModel.Work,
        tint: Color
    ) -> some View {
        let isWorking = model.working == work

        return ZStack {
            Text(title)
                .opacity(isWorking ? 0 : 1)

            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(tint)

                Text(work.title)
            }
            .opacity(isWorking ? 1 : 0)
        }
    }
}

private extension ProView {
    func opacity(of work: ProPurchaseModel.Work) -> Double {
        model.isWorking && model.working != work
            ? 0.4
            : 1
    }

    func purchase() {
        Task {
            if await model.purchase() {
                finish()
            }
        }
    }

    func restore() {
        Task {
            if await model.restore() {
                finish()
            }
        }
    }

    func finish() {
        dismiss()
        onUnlock()
    }
}

#Preview {
    NavigationStack {
        ProView(model: ProPurchaseModel(store: .unavailable))
    }
}
