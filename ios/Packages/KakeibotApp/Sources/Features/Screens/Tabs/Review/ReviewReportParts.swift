import Core
import DesignSystem
import SwiftUI

struct ReviewReportLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .tracking(2)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(Self.line)
                .frame(height: 1)
        }
    }
}

struct ReviewReportLead: View {
    let caption: String
    let value: String
    let suffix: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    amount
                        .fixedSize()

                    suffixText
                        .padding(.leading, 2)
                }

                VStack(alignment: .leading, spacing: 0) {
                    amount

                    suffixText
                }
            }
            .foregroundStyle(color)
        }
    }
}

private extension ReviewReportLead {
    var amount: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value)
                .displayFont(.title, weight: .bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("円")
                .displayFont(.small, weight: .bold)
                .fixedSize()
        }
    }

    var suffixText: some View {
        Text(suffix)
            .textFont(.footnote, weight: .bold)
            .fixedSize()
    }
}

struct ReviewReportChip: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .sansFont(.micro, weight: .bold)

            Text(title)
                .textFont(.caption2, weight: .bold)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Palette.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 12))
    }
}

struct ReviewReportStat: View {
    let title: String
    let systemImage: String
    let value: String
    let unit: String
    var note: String?
    var badge: String?
    var progress: Double?
    var color: Color = Palette.text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) {
                    titleText

                    Spacer(minLength: 4)

                    Image(systemName: systemImage)
                        .sansFont(.small, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 24, height: 24)
                        .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 8))
                }

                titleText
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 24)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .displayFont(style: .title2, weight: .bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(unit)
                    .textFont(.caption, weight: .bold)
                    .fixedSize()
            }
            .foregroundStyle(color)
            .frame(height: Self.valueHeight, alignment: .bottomLeading)

            detail
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.accent.opacity(.faint))
        .background(Palette.cardBottom)
    }
}

struct ReviewGoalItem: Identifiable {
    let goal: ReviewGoal
    let name: String
    let categoryName: String
    let progress: ReviewGoal.Progress

    var id: ReviewGoal.ID {
        goal.id
    }

    func title(unit: String) -> String {
        ReviewEmphasisText.plain(titleParts(unit: unit))
    }

    func titleParts(unit: String) -> [ReviewEmphasisText.Part] {
        switch goal.kind {
        case .count:
            [
                .name(name),
                .plain("を、\(unit) "),
                .number("\(goal.target)"),
                .plain(" 回までに")
            ]

        case .average:
            [
                .name(name),
                .plain("の 1 回を、"),
                .number(ReviewYen.number(goal.target)),
                .plain("円 までに")
            ]
        }
    }

    func value(_ number: Int) -> String {
        switch goal.kind {
        case .count: "\(number) 回"
        case .average: ReviewYen.text(number)
        }
    }
}

extension View {
    func reviewHero() -> some View {
        padding(20)
            .reviewTicket()
    }

    func reviewTicket() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Palette.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(ReviewReportLabel.glow)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(Palette.accent.opacity(.muted))
                    }
                    .shadow(color: Palette.accent.opacity(.subtle), radius: 16, y: 12)
            }
    }

    func reviewStatGrid() -> some View {
        background(Palette.accent.opacity(.soft))
            .clipShape(.rect(cornerRadius: 16))
    }
}

extension ReviewYen {
    static func signed(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(text(amount))"
        }

        return amount < 0 ? "−\(text(-amount))" : "±0円"
    }

    static func signedNumber(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(number(amount))"
        }

        return amount < 0 ? "−\(number(-amount))" : "±0"
    }
}

extension ReviewPace {
    static func percent(_ ratio: Double) -> Int {
        Int((ratio * 100).rounded())
    }

    static func periodsUnit(_ unit: String) -> String {
        unit == "月" ? "か月" : unit
    }

    func limitName(unit: String) -> String {
        switch basis {
        case .budget: "予算"
        case let .average(periods): "\(periods) \(Self.periodsUnit(unit))の平均"
        }
    }
}

private extension ReviewReportLabel {
    static var line: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.muted), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var glow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), .clear],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 240
        )
    }
}

private extension ReviewReportStat {
    static let valueHeight: CGFloat = 30

    var titleText: some View {
        Text(title)
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
    }

    @ViewBuilder
    var detail: some View {
        if let progress {
            let clamped = min(max(progress, 0), 1)

            Capsule()
                .fill(Palette.accent.opacity(.subtle))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Palette.gold)
                            .frame(width: proxy.size.width * clamped)
                    }
                }
                .padding(.top, 8)
        } else {
            HStack(spacing: 4) {
                if let badge {
                    Text(badge)
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(color.opacity(.subtle), in: Capsule())
                        .fixedSize()
                }

                if let note {
                    Text(note)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
