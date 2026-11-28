import Core
import DesignSystem
import SwiftUI

struct WhatsNewOutlookScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .block:
            block
                .whatsNewTapped()

        case .list:
            WhatsNewMoveList(title: "今月これからの出入り")

        case .tab:
            WhatsNewPlanScene(step: .tab)
        }
    }
}

extension WhatsNewOutlookScene {
    enum Step: Hashable, Sendable {
        case tab
        case block
        case list
    }
}

private extension WhatsNewOutlookScene {
    var block: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("今月これから", systemImage: "calendar")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            totalRow("入る", amount: WhatsNewMove.income, color: Palette.accentStrong)

            totalRow("出る", amount: WhatsNewMove.expense, color: Palette.text)

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)

            Text("月末の見込み")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 2) {
                Spacer(minLength: 2)

                AmountText(
                    WhatsNewMove.outlook,
                    font: .size(.caption, weight: .bold),
                    color: Palette.text
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                Image(systemName: "chevron.right")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.hint)
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func totalRow(
        _ label: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 2)

            AmountText(amount, font: .size(.micro, weight: .semibold), color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .textFont(size: .micro, weight: .semibold)
    }
}
