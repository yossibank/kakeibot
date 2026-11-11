import Core
import DesignSystem
import SwiftUI

extension AssetsRewardSheet {
    var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("達成の履歴")

            if model.rewardHistory.isEmpty {
                Text("資産の「今日の達成を付ける」か、記録の日の見出しの贈り物のボタンから付けられます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 8)
            } else {
                ForEach(model.rewardHistory) { month in
                    monthBlock(month)
                }
            }
        }
    }
}

private extension AssetsRewardSheet {
    func monthBlock(_ month: AssetsModel.RewardMonth) -> some View {
        let total = month.logs.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(String(month.month.year))年 \(month.month.month)月")
                    .textFont(.footnote, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Spacer()

                AmountText(total, font: .style(.caption), sign: .plus, color: Palette.accent)
            }

            VStack(spacing: 8) {
                ForEach(month.logs) { log in
                    logRow(log)
                }
            }
            .padding(16)
            .card()
            .sharesTextScale(id: month.logs)
        }
    }

    func logRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 12) {
            IconBadge(icon, size: 36)

            Text(rule?.name ?? "")
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text(log.date.monthDayText)
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            AmountText(log.amount, font: .style(.footnote), sign: .plus, color: Palette.accent)
        }
    }
}
