import DesignSystem
import SwiftUI

struct ReviewSharesCard: View {
    let title: String
    let shares: [ReviewModel.Share]
    let total: Total?
    let onOpen: (ReviewModel.Share) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title)

            if shares.isEmpty {
                Text("この期間の記録はありません")
                    .font(.footnote)
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
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Palette.hint)
                                .frame(width: 8, height: 8)

                            Text("その他 \(others.count) 件")
                                .font(.caption)
                                .foregroundStyle(Palette.subtext)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                ForEach(shares) { share in
                    Button {
                        onOpen(share)
                    } label: {
                        label(share)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

extension ReviewSharesCard {
    struct Total {
        let title: String
        let amount: Int
    }
}

private extension ReviewSharesCard {
    func center(_ total: Total) -> some View {
        VStack(spacing: 2) {
            Text(total.title)
                .font(.caption2)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(total.amount))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 36)
    }

    func label(_ share: ReviewModel.Share) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                IconBadge(share.icon, size: 30)

                Text(share.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(Self.percentText(share.ratio))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(AmountText.text(share.amount))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Palette.hint)
            }

            if let usage = share.usage {
                UsageBar(usage)
                    .padding(.leading, 40)
            }
        }
        .contentShape(.rect)
    }
}

private extension ReviewSharesCard {
    static let chartLimit = 5
    static let minorRatio = 0.05

    static func percentText(_ ratio: Double) -> String {
        "\(Int((ratio * 100).rounded()))%"
    }

    static func otherShares(
        _ shares: [ReviewModel.Share]
    ) -> [ReviewModel.Share]? {
        let main = shares
            .prefix(chartLimit)
            .prefix(while: { $0.ratio >= minorRatio })

        let others = Array(shares.dropFirst(main.count))
        return others.count > 1 ? others : nil
    }

    static func slices(
        _ shares: [ReviewModel.Share]
    ) -> [DonutChart<AnyHashable>.Slice] {
        let others = otherShares(shares) ?? []
        let main = shares.dropLast(others.count)

        let slices = main.map { share in
            let color = share.icon.flatMap { Color(hex: $0.color) }

            return DonutChart<AnyHashable>.Slice(
                id: share.id,
                value: share.amount,
                color: color ?? Palette.accent
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
