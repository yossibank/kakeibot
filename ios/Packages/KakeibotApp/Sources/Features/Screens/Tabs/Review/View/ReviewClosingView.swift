import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct ReviewClosingView: View {
    let content: ReviewClosing.Content
    let goals: ReviewClosing.Goals
    let notes: ReviewClosing.Notes
    let name: String
    let previousName: String
    let unit: String
    let onOpenGoal: (ReviewGoalItem) -> Void
    let onOpenWhy: (ReviewClosing.CompareRow, ReviewCompare.Why) -> Void

    var body: some View {
        VStack(spacing: 12) {
            resultCard

            if let summary = notes.summary {
                summaryCard(summary)
            }

            if let answer = goals.answer {
                answerCard(answer)
            }

            streakCard

            if !content.rows.isEmpty {
                compareCard
            }

            if !goodItems.isEmpty {
                goodCard
            }

            nextCard
        }
    }
}

extension ReviewClosingView {
    var periodsUnit: String {
        ReviewPace.periodsUnit(unit)
    }

    var spent: Int {
        content.spent
    }

    var totalDays: Int {
        content.range.lowerBound.days(until: content.range.upperBound) + 1
    }
}

private extension ReviewClosingView {
    var resultCard: some View {
        let limitName = content.pace?.limitName(unit: unit) ?? ""

        return VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: "\(name)の結果")

            ReviewReportGaugeRow(pace: content.pace, limitName: limitName, showsMarker: false) {
                resultVerdict
            }

            resultStats
        }
        .reviewHero()
    }

    var resultVerdict: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verdictText)
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.gold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)

                if let streakTitle {
                    ReviewReportChip(systemImage: "rosette", title: streakTitle)
                }
            }

            if let pace = content.pace {
                let left = ReviewYen.number(abs(pace.remaining))

                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)

                ReviewReportLead(
                    caption: Self.leadCaption(pace),
                    value: left,
                    suffix: Self.leftSuffix(pace),
                    color: Self.leftColor(pace)
                )
            }
        }
    }

    var resultStats: some View {
        let perDay = ReviewYen.number(spent / totalDays)
        let spentText = ReviewYen.number(spent)

        return Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                ReviewReportStat(
                    title: "使った",
                    systemImage: "yensign.circle",
                    value: spentText,
                    unit: "円",
                    note: spentNote
                )

                ReviewReportStat(
                    title: "1 日あたり",
                    systemImage: "calendar",
                    value: perDay,
                    unit: "円",
                    note: "\(totalDays) 日で割った額"
                )
            }

            if let previousTotal = content.previousTotal {
                let difference = spent - previousTotal
                let color = difference <= 0 ? Palette.accent : Palette.increase
                let symbol = difference <= 0 ? "arrow.down.right" : "arrow.up.right"
                let value = ReviewYen.signedNumber(difference)

                GridRow {
                    ReviewReportStat(
                        title: "\(previousName)より",
                        systemImage: symbol,
                        value: value,
                        unit: "円",
                        note: "\(previousName) \(ReviewYen.text(previousTotal))",
                        color: color
                    )
                    .gridCellColumns(2)
                }
            }
        }
        .reviewStatGrid()
    }

    func summaryCard(_ summary: String) -> some View {
        let sparkle = Text(Image(systemName: "sparkles"))

        return VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: "AI のひとこと")

            Text(summary)
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(sparkle) 端末の中の AI が、この\(unit)の数字からまとめました")
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    var verdictText: String {
        guard let pace = content.pace else {
            return "\(name)を締めました"
        }

        switch pace.basis {
        case .budget:
            return pace.verdict == .over ? "予算を\n超えました" : "予算内で\n締めました"

        case .average:
            return switch ReviewCompare.tone(amount: pace.spent, average: pace.limit) {
            case .more: "いつもより\n多め"
            case .less: "いつもより\n少なめ"
            case .usual: "いつもどおり"
            }
        }
    }

    var streakTitle: String? {
        let isBudget = content.pace?.basis == .budget

        let continues = isBudget
            && content.budgetStreak >= 2

        guard continues else {
            return nil
        }

        return "\(content.budgetStreak) \(periodsUnit)つづけて予算内"
    }

    var spentNote: String {
        guard let pace = content.pace else {
            return "\(content.streak.count) 件の記録"
        }

        return "\(pace.limitName(unit: unit)) \(ReviewYen.text(pace.limit))"
    }

    static func leftColor(_ pace: ReviewPace) -> Color {
        pace.remaining >= 0 ? Palette.accent : Palette.increase
    }

    static func leftSuffix(_ pace: ReviewPace) -> String {
        switch pace.basis {
        case .budget: pace.remaining >= 0 ? "余り" : "超え"
        case .average: pace.remaining >= 0 ? "少ない" : "多い"
        }
    }

    static func leadCaption(_ pace: ReviewPace) -> String {
        pace.basis == .budget ? "予算より" : "平均より"
    }
}
