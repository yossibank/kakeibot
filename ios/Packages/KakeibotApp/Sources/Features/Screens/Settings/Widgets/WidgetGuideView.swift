import DesignSystem
import SwiftUI

public struct WidgetGuideView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("ウィジェットの置き方")

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    WidgetGuideIntroCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsSectionTitle("置けるもの")

                        VStack(spacing: 0) {
                            ForEach(Self.kinds) { kind in
                                if kind.id != Self.kinds.first?.id {
                                    Hairline()
                                }

                                kindRow(kind)
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsSectionTitle("ホーム画面に置く")

                        VStack(spacing: 0) {
                            ForEach(Self.steps.indices, id: \.self) { index in
                                if index > 0 {
                                    Hairline()
                                }

                                stepRow(number: index + 1, text: Self.steps[index])
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()

                        SettingsCaption(Self.otherPlaces)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension WidgetGuideView {
    struct Kind: Identifiable {
        let id: String
        let systemImage: String
        let title: String
        let place: String
        let detail: String
    }

    static let kinds = [
        Kind(
            id: "quickRecord",
            systemImage: "bolt",
            title: "すぐ記録",
            place: "ホーム画面・中と大",
            detail: "テンプレートを押すと、アプリを開かずに記録します"
        ),
        Kind(
            id: "budget",
            systemImage: "yensign.circle",
            title: "あといくら",
            place: "ホーム画面・小と中",
            detail: "今月あといくら使えるかと、今日の支出を出します"
        ),
        Kind(
            id: "budgetLock",
            systemImage: "lock",
            title: "あといくら",
            place: "ロック画面",
            detail: "今月あといくら使えるかを出します"
        ),
        Kind(
            id: "recordControl",
            systemImage: "switch.2",
            title: "記録する",
            place: "コントロールセンター",
            detail: "今日の入力シートを開きます"
        )
    ]

    static let steps = [
        "ホーム画面の空いた所を長押しします",
        "左上の「編集」から「ウィジェットを追加」を選びます",
        "「かけいぼっと」を選び、置きたいものを選びます"
    ]

    static let otherPlaces = "ロック画面は、ロック画面を長押しして「カスタマイズ」から置けます。コントロールセンターは、開いて左上の ＋ から置けます。"

    func kindRow(_ kind: Kind) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(kind.title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Text(kind.place)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text(kind.detail)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    func stepRow(
        number: Int,
        text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        WidgetGuideView()
    }
}
