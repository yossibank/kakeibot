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
                VStack(alignment: .leading, spacing: 28) {
                    header

                    section("記録", features: Self.recordFeatures)

                    section("同期と共有", features: Self.syncFeatures)

                    section("見た目", features: Self.lookFeatures)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            if isPro {
                Text("購入済みです。Pro の機能をすべて使えます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                VStack(spacing: 12) {
                    CardButton(model.purchaseTitle, style: .filled) {
                        purchase()
                    }

                    CardButton("購入を復元", style: .outlined(Palette.subtext)) {
                        restore()
                    }
                }
                .disabled(model.isWorking)
            }
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
        .task {
            await model.load()
        }
    }
}

private extension ProView {
    struct Feature: Identifiable {
        let art: FeatureArt.Kind
        let title: String
        let text: String

        var id: String {
            title
        }
    }
}

private extension ProView {
    var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .sansFont(.headline, weight: .ultraLight)
                .foregroundStyle(Palette.accent)
                .frame(width: 52, height: 52)
                .overlay {
                    Circle()
                        .stroke(Palette.outline, lineWidth: 0.8)
                }

            Text("かけいぼっと Pro")
                .displayFont(.headline, weight: .medium)
                .foregroundStyle(Palette.accentStrong)

            Text("一度買えば、ずっと使えます。\nファミリー共有の家族も使えます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    func section(
        _ title: String,
        features: [Feature]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(title)

            VStack(spacing: 12) {
                ForEach(features) { feature in
                    card(feature)
                }
            }
        }
    }

    func card(_ feature: Feature) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureArt(kind: feature.art)
                .frame(height: Self.artHeight)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(feature.text)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .card()
    }
}

private extension ProView {
    static let artHeight: CGFloat = 112

    static let recordFeatures = [
        Feature(
            art: .receipt,
            title: "レシートの読み取り",
            text: "無料では 3 回までです。Pro なら回数を気にせず、撮ったレシートから品目・合計・日付・店名を読めます"
        )
    ]

    static let syncFeatures = [
        Feature(
            art: .sync,
            title: "端末間の同期",
            text: "自分の iPhone どうしで、記録と設定をそろえます"
        ),
        Feature(
            art: .share,
            title: "家族との共有",
            text: "口座を共有して、一緒に記録できます。招待された人は Pro が無くても使えます"
        )
    ]

    static let lookFeatures = [
        Feature(
            art: .theme,
            title: "テーマを作る",
            text: "色を選んで、自分だけのテーマを作れます"
        ),
        Feature(
            art: .fonts,
            title: "4 つの字体",
            text: "丸ゴシック・手書き・ドット・ポップの字体を使えます"
        )
    ]

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
