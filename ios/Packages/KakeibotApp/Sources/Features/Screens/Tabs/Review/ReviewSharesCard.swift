import Core
import DesignSystem
import SwiftUI

struct ReviewSharesCard: View {
    let title: String
    let type: Entry.Kind?
    let shares: [ReviewModel.Share]
    let total: Total?
    let onOpen: (ReviewModel.Share) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(title)

            content
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .sharesTextScale(id: shares.map(\.name))
    }
}

extension ReviewSharesCard {
    struct Total {
        let title: String
        let amount: Int
    }
}

private extension ReviewSharesCard {
    var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            if shares.isEmpty {
                Text("この期間の記録はありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                if let total {
                    DonutChart(Self.slices(shares)) { id in
                        if let share = shares.first(where: { $0.id == id }) {
                            onOpen(share)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .overlay {
                        center(total)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    if let others = Self.otherShares(shares) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Palette.hint)
                                .frame(width: 8, height: 8)

                            Text("その他 \(others.count) 件")
                                .textFont(.caption)
                                .foregroundStyle(Palette.subtext)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                let percents = ReviewText.shares(shares.map(\.amount))
                let items = Array(zip(shares, percents))

                ForEach(items, id: \.0.id) { share, percent in
                    Button {
                        onOpen(share)
                    } label: {
                        label(share, percent: percent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func center(_ total: Total) -> some View {
        VStack(spacing: 2) {
            Text(total.title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            AmountText(total.amount, type: type, font: .size(.body))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 36)
    }

    func label(
        _ share: ReviewModel.Share,
        percent: String?
    ) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                if total != nil {
                    Circle()
                        .fill(Self.color(of: share, in: shares))
                        .frame(width: 8, height: 8)
                }

                IconBadge(share.icon, size: 26)
            }

            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: " ")
                        .textFont(.subheadline)

                    Text(verbatim: " ")
                        .textFont(.caption)
                }
                .hidden()

                VStack(alignment: .leading, spacing: 4) {
                    Text(share.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .sharedTextScale()

                    if percent != nil || share.usage != nil {
                        HStack(spacing: 8) {
                            if let percent {
                                Text(percent)
                                    .textFont(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.subtext)
                                    .lineLimit(1)
                                    .fixedSize()
                            }

                            if let usage = share.usage {
                                BudgetUsageBar(usage)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                AmountText(share.amount, type: type, font: .size(.body))
                    .fixedSize()

                if let usage = share.usage {
                    Text(ReviewText.budget(usage))
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(usage.isOver ? Palette.rose : Palette.subtext)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .layoutPriority(1)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .contentShape(.rect)
    }
}

private extension ReviewSharesCard {
    static let chartLimit = 5
    static let minorRatio = 0.05

    static func otherShares(_ shares: [ReviewModel.Share]) -> [ReviewModel.Share]? {
        let main = shares
            .prefix(chartLimit)
            .prefix(while: { $0.ratio >= minorRatio })

        let others = Array(shares.dropFirst(main.count))

        return others.count > 1 ? others : nil
    }

    static func color(
        of share: ReviewModel.Share,
        in shares: [ReviewModel.Share]
    ) -> Color {
        let others = otherShares(shares) ?? []
        return others.contains { $0.id == share.id } ? Palette.hint : color(of: share)
    }

    static func color(of share: ReviewModel.Share) -> Color {
        share.icon.flatMap { Color(hex: $0.color) } ?? Palette.accent
    }

    static func slices(_ shares: [ReviewModel.Share]) -> [DonutChart<AnyHashable>.Slice] {
        let others = otherShares(shares) ?? []
        let main = shares.dropLast(others.count)

        let slices = main.map { share in
            DonutChart<AnyHashable>.Slice(
                id: share.id,
                value: share.amount,
                color: color(of: share)
            )
        }

        guard !others.isEmpty else {
            return slices
        }

        let other = DonutChart<AnyHashable>.Slice(
            id: "others",
            value: others.reduce(0) { $0 + $1.amount },
            color: Palette.hint
        )

        return slices + [other]
    }
}
