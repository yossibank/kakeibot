import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    static let maximumDots = 15

    func compare(_ focus: ReviewBreakdown.Focus) -> some View {
        let hasPrevious = focus.hasPrevious

        return panel {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    panelTitle(hasPrevious ? "\(focus.name)をくらべる" : "\(focus.name)のまとめ")

                    Text(spanNote(hasPrevious: hasPrevious))
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                countSection(focus)

                divider

                priceSection(focus)

                divider

                totalSection(focus)

                recordButtons(hasPrevious: hasPrevious)
            }
            .monospacedDigit()
        }
    }

    func dots(
        _ count: Int,
        base: Int,
        dashed: Int = 0
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<count + dashed, id: \.self) { index in
                dot(isUp: index >= base && index < count, isDashed: index >= count)
                    .scaleEffect(hasAppeared ? 1 : 0.2)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        .spring(duration: 0.4).delay(Double(index) * 0.03),
                        value: hasAppeared
                    )
            }
        }
    }
}

private extension ReviewAnalysisView {
    var divider: some View {
        Rectangle()
            .fill(Palette.accent.opacity(.subtle))
            .frame(height: 1)
    }

    func dot(
        isUp: Bool,
        isDashed: Bool
    ) -> some View {
        ZStack {
            if isDashed {
                Circle()
                    .strokeBorder(Palette.accent, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            } else {
                Circle()
                    .fill(isUp ? AnyShapeStyle(Palette.increase) : AnyShapeStyle(Palette.gold))
            }
        }
        .frame(width: 12, height: 12)
    }

    func sectionTitle(
        _ title: String,
        change: String?,
        isUp: Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .textFont(.caption, weight: .bold)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            if let change {
                Text(change)
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(isUp ? Palette.increase : Palette.subtext)
            }
        }
    }

    func rowLabel(_ title: String) -> some View {
        Text(title)
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: 48, alignment: .leading)
    }

    func countSection(_ focus: ReviewBreakdown.Focus) -> some View {
        let difference = focus.count - focus.previousCount
        let top = max(focus.count, focus.previousCount, 1)
        let change = focus.hasPrevious ? Self.countText(difference) : nil

        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("回数", change: change, isUp: difference > 0)

            if focus.hasPrevious {
                countRow(
                    "前の\(unit)",
                    count: focus.previousCount,
                    base: focus.previousCount,
                    top: top
                )
            }

            countRow(
                currentName,
                count: focus.count,
                base: focus.hasPrevious ? focus.previousCount : focus.count,
                top: top
            )
        }
    }

    func countRow(
        _ title: String,
        count: Int,
        base: Int,
        top: Int
    ) -> some View {
        HStack(spacing: 8) {
            rowLabel(title)

            if top <= Self.maximumDots {
                dots(count, base: base)

                Spacer(minLength: 0)
            } else {
                bar(
                    ratio: Double(min(count, base)) / Double(top),
                    extra: Double(max(count - base, 0)) / Double(top)
                )
            }

            Text("\(count) 回")
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.text)
                .fixedSize()
                .frame(minWidth: 40, alignment: .trailing)
        }
    }

    func priceSection(_ focus: ReviewBreakdown.Focus) -> some View {
        let difference = focus.unitPrice - focus.previousUnitPrice
        let change = focus.hasPrevious ? Self.signed(difference) : nil

        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("1 回あたり", change: change, isUp: difference > 0)

            HStack(spacing: 12) {
                if focus.hasPrevious {
                    priceValue("前の\(unit)", amount: focus.previousUnitPrice, isCurrent: false)

                    Image(systemName: "arrow.right")
                        .sansFont(.small, weight: .bold)
                        .foregroundStyle(Palette.accent)
                }

                priceValue(currentName, amount: focus.unitPrice, isCurrent: true)

                Spacer(minLength: 0)
            }
        }
    }

    func priceValue(
        _ title: String,
        amount: Int,
        isCurrent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            Text(ReviewInsight.yen(amount))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(isCurrent ? Palette.text : Palette.subtext)
                .fixedSize()
        }
    }

    func totalSection(_ focus: ReviewBreakdown.Focus) -> some View {
        let difference = focus.amount - focus.previousAmount
        let top = Double(max(focus.amount, focus.previousAmount, 1))
        let base = focus.hasPrevious ? min(focus.amount, focus.previousAmount) : focus.amount
        let change = focus.hasPrevious ? Self.signed(difference) : nil

        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("合計", change: change, isUp: difference > 0)

            if focus.hasPrevious {
                totalRow(
                    "前の\(unit)",
                    amount: focus.previousAmount,
                    ratio: Double(focus.previousAmount) / top,
                    extra: 0
                )
            }

            totalRow(
                currentName,
                amount: focus.amount,
                ratio: Double(base) / top,
                extra: Double(focus.amount - base) / top
            )
        }
    }

    func totalRow(
        _ title: String,
        amount: Int,
        ratio: Double,
        extra: Double
    ) -> some View {
        HStack(spacing: 8) {
            rowLabel(title)

            bar(ratio: ratio, extra: extra)

            Text(ReviewInsight.yen(amount))
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.text)
                .fixedSize()
                .frame(minWidth: 72, alignment: .trailing)
        }
    }

    func bar(
        ratio: Double,
        extra: Double
    ) -> some View {
        let grow: Double = hasAppeared ? 1 : 0

        return Capsule()
            .fill(Palette.accent.opacity(.faint))
            .frame(height: 10)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Palette.gold)
                            .frame(width: proxy.size.width * ratio * grow)

                        Rectangle()
                            .fill(Palette.increase.gradient)
                            .frame(width: proxy.size.width * extra * grow)
                    }
                    .clipShape(Capsule())
                }
            }
    }

    func recordButtons(hasPrevious: Bool) -> some View {
        HStack(spacing: 8) {
            if hasPrevious {
                recordButton("前の\(unit)の記録", factor: .previous)
            }

            recordButton("\(currentName)の記録", factor: .current)
        }
    }

    func recordButton(
        _ title: String,
        factor: ReviewModel.Factor
    ) -> some View {
        Button {
            onOpen(factor)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Palette.accent.opacity(.faint), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Palette.accent.opacity(.muted))
            }
            .contentShape(.rect)
        }
        .buttonStyle(PressButtonStyle())
    }

    func spanNote(hasPrevious: Bool) -> String {
        hasPrevious ? "\(previousSpan) と \(currentSpan) をくらべています" : currentSpan
    }
}
