import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    func headline(_ focus: ReviewBreakdown.Focus) -> some View {
        let isUp = Self.isUp(focus)
        let title = isUp ? "いちばん増えたカテゴリ" : "いちばん使ったカテゴリ"
        let main = isUp ? "+\(Self.percent(of: focus))%" : ReviewInsight.yen(focus.amount)
        let sub = isUp ? Self.signed(focus.amount - focus.previousAmount) : "\(focus.count) 回"
        let color = isUp ? Palette.increase : Palette.text

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(focus.name)
                        .displayFont(.headline, weight: .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(main)
                        .displayFont(.display, weight: .bold)
                        .foregroundStyle(color.gradient)
                        .shadow(color: color.opacity(.soft), radius: 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(sub)
                        .displayFont(.small, weight: .semibold)
                        .foregroundStyle(isUp ? Palette.increase : Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .layoutPriority(1)
            }
            .monospacedDigit()
            .fixedSize(horizontal: false, vertical: true)

            if isUp {
                reasons(focus)
            }
        }
    }

    func metrics(_ focus: ReviewBreakdown.Focus) -> some View {
        let isPriceUp = focus.hasPrevious
            && !focus.hasSamePrice
            && focus.unitPrice > focus.previousUnitPrice

        return HStack(spacing: 8) {
            metric(
                "支出",
                value: ReviewInsight.yen(focus.amount),
                pair: (focus.previousAmount, focus.amount),
                change: amountChange(of: focus),
                isUp: Self.isUp(focus),
                hasPrevious: focus.hasPrevious
            )

            metric(
                "回数",
                value: "\(focus.count) 回",
                pair: (focus.previousCount, focus.count),
                change: countChange(of: focus),
                isUp: focus.hasPrevious && focus.count > focus.previousCount,
                hasPrevious: focus.hasPrevious
            )

            metric(
                "1 回の金額",
                value: ReviewInsight.yen(focus.unitPrice),
                pair: (focus.previousUnitPrice, focus.unitPrice),
                change: priceChange(of: focus),
                isUp: isPriceUp,
                hasPrevious: focus.hasPrevious
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension ReviewAnalysisView {
    func metric(
        _ title: String,
        value: String,
        pair: (Int, Int),
        change: String?,
        isUp: Bool,
        hasPrevious: Bool
    ) -> some View {
        let peak = CGFloat(max(pair.0, pair.1, 1))
        let fill = isUp ? AnyShapeStyle(Palette.increase.gradient) : AnyShapeStyle(Palette.gold)

        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .displayFont(.body, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if hasPrevious {
                HStack(alignment: .bottom, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Palette.accent.opacity(.soft))
                        .frame(height: 24 * CGFloat(pair.0) / peak)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(fill)
                        .frame(height: 24 * CGFloat(pair.1) / peak)
                }
                .frame(height: 24, alignment: .bottom)
                .padding(.vertical, 4)
            }

            if let change {
                Text(change)
                    .textFont(.caption2, weight: .semibold)
                    .foregroundStyle(isUp ? Palette.increase : Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .monospacedDigit()
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Palette.accent.opacity(.subtle))
        }
    }

    func ring(
        _ share: Double,
        title: String
    ) -> some View {
        ZStack {
            Circle()
                .stroke(Palette.accent.opacity(.subtle), lineWidth: 8)

            Circle()
                .trim(from: 0, to: hasAppeared ? share : 0)
                .stroke(
                    Palette.increase.gradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Palette.increase.opacity(.soft), radius: 3)

            VStack(spacing: 0) {
                Text("\(Int((share * 100).rounded()))%")
                    .displayFont(.body, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(title)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
            .monospacedDigit()
        }
        .frame(width: 76, height: 76)
    }

    func reasons(_ focus: ReviewBreakdown.Focus) -> some View {
        let count = max(focus.countEffect, 0)
        let price = max(focus.priceEffect, 0)
        let isCount = count >= price
        let share = Double(max(count, price)) / Double(max(count + price, 1))

        let rows = VStack(alignment: .leading, spacing: 8) {
            Text("増えた理由")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            reasonRow("回数の増加", amount: focus.countEffect, isMain: isCount)

            reasonRow("1 回の金額", amount: focus.priceEffect, isMain: !isCount)
        }

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                ring(share, title: isCount ? "回数" : "金額")

                rows
            }

            rows
        }
        .padding(12)
        .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Palette.accent.opacity(.subtle))
        }
    }

    func reasonRow(
        _ title: String,
        amount: Int,
        isMain: Bool
    ) -> some View {
        let color = isMain ? Palette.increase : Palette.subtext
        let fill = isMain ? Palette.increase.opacity(.subtle) : Color.clear
        let edge = isMain ? Palette.increase.opacity(.muted) : Palette.accent.opacity(.subtle)

        return Button {
            onOpen(.current)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(isMain ? Palette.increase : Palette.subtext.opacity(.muted))
                    .frame(width: 8, height: 8)
                    .shadow(color: color.opacity(isMain ? 0.5 : 0), radius: 2)

                Text(title)
                    .textFont(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                Text(Self.signed(amount))
                    .displayFont(.small, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(color)
            }
            .foregroundStyle(isMain ? Palette.text : Palette.subtext)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(fill, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(edge)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension ReviewAnalysisView {
    static func isUp(_ focus: ReviewBreakdown.Focus) -> Bool {
        focus.hasPrevious && focus.amount > focus.previousAmount
    }

    static func percent(of focus: ReviewBreakdown.Focus) -> Int {
        guard focus.previousAmount > 0 else {
            return 0
        }

        return (focus.amount - focus.previousAmount) * 100 / focus.previousAmount
    }

    func amountChange(of focus: ReviewBreakdown.Focus) -> String? {
        guard focus.hasPrevious else {
            return nil
        }

        let percent = Self.percent(of: focus)

        if percent == 0 {
            return "± 0%"
        }

        let mark = percent > 0 ? "▲" : "▼"
        return "\(mark) \(abs(percent))%"
    }

    func countChange(of focus: ReviewBreakdown.Focus) -> String? {
        guard focus.hasPrevious else {
            return nil
        }

        let diff = focus.count - focus.previousCount

        if diff == 0 {
            return "± 0 回"
        }

        let mark = diff > 0 ? "▲" : "▼"
        return "\(mark) \(abs(diff)) 回"
    }

    func priceChange(of focus: ReviewBreakdown.Focus) -> String? {
        guard focus.hasPrevious else {
            return nil
        }

        guard !focus.hasSamePrice else {
            return "± 前の\(unit)と同じ"
        }

        let diff = focus.unitPrice - focus.previousUnitPrice
        let mark = diff > 0 ? "▲" : "▼"

        return "\(mark) \(ReviewInsight.yen(abs(diff)))"
    }
}
