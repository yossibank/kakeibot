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

                    homeSection

                    place(
                        "ロック画面",
                        sample: .lockScreen,
                        title: "あといくら",
                        detail: "今月あといくら使えるかを、丸・横長・1 行の形で出します",
                        howTo: "ロック画面を長押しして「カスタマイズ」から置けます"
                    )

                    place(
                        "コントロールセンター",
                        sample: .control,
                        title: "記録する",
                        detail: "押すと、今日の入力シートを開きます",
                        howTo: "コントロールセンターを開き、左上の ＋ から置けます"
                    )
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
    static let sideTextWidth: CGFloat = 150

    static let steps = [
        "ホーム画面の空いた所を長押しします",
        "左上の「編集」から「ウィジェットを追加」を選びます",
        "「かけいぼっと」を選び、置きたいものを選びます"
    ]
}

private extension WidgetGuideView {
    var homeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("ホーム画面")

            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 14) {
                        WidgetGuideSample(kind: .budget)

                        budgetExplanation
                            .frame(minWidth: Self.sideTextWidth)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        WidgetGuideSample(kind: .budget)

                        budgetExplanation
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    WidgetGuideSample(kind: .quickRecord)

                    explanation(
                        title: "すぐ記録",
                        size: "中・大",
                        detail: "テンプレートを押すと、アプリを開かずにその場で記録します。鉛筆の印のものは、入力シートで金額を入れます"
                    )
                }

                Hairline()

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Self.steps.indices, id: \.self) { index in
                        stepRow(number: index + 1, text: Self.steps[index])
                    }
                }
            }
            .padding(16)
            .card()
        }
    }

    var budgetExplanation: some View {
        explanation(
            title: "あといくら",
            size: "小・中",
            detail: "今月あといくら使えるかと、今日の支出を出します。中では今週の支出と次の固定費も並べます"
        )
    }

    func place(
        _ name: String,
        sample: WidgetGuideSample.Kind,
        title: String,
        detail: String,
        howTo: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(name)

            VStack(alignment: .leading, spacing: 12) {
                WidgetGuideSample(kind: sample)

                explanation(title: title, size: nil, detail: detail)

                Label(howTo, systemImage: "hand.tap")
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .card()
        }
    }

    func explanation(
        title: String,
        size: String?,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)

                if let size {
                    Text(size)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }

            Text(detail)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        WidgetGuideView()
    }
}
