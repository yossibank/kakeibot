import Core
import DesignSystem
import SwiftUI

struct ReviewClosingView: View {
    let content: Content
    let goals: Goals
    let name: String
    let previousName: String
    let unit: String
    let onOpenGoal: (ReviewGoalItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            resultCard

            if let answer = goals.answer {
                answerCard(answer)
            }

            if content.scale != .week {
                streakCard

                if !content.rows.isEmpty {
                    compareCard
                }

                if !goodItems.isEmpty {
                    goodCard
                }
            }

            nextCard
        }
    }
}

extension ReviewClosingView {
    struct Content {
        let scale: ReviewPeriod.Scale
        let range: ClosedRange<LocalDate>
        let weekStart: Weekday
        let pace: ReviewPace?
        let spent: Int
        let previousTotal: Int?
        let rows: [CompareRow]
        let averagePeriods: Int
        let special: Special?
        let streak: ReviewStreak
        let continuing: Int
        let budgetStreak: Int
    }

    struct CompareRow: Identifiable {
        let name: String
        let row: ReviewCompare.Row

        var id: EntryCategory.ID {
            row.categoryId
        }
    }

    struct Special {
        let date: LocalDate
        let name: String
        let amount: Int
    }

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
        VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: "\(name)の結果")

            HStack(spacing: 16) {
                if let pace = content.pace {
                    ReviewReportGauge(
                        pace: pace,
                        limitName: pace.limitName(unit: unit),
                        showsMarker: false
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(verdictText)
                        .displayFont(.title, weight: .bold)
                        .foregroundStyle(Palette.gold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)

                    if let pace = content.pace {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(leadCaption(pace))
                                .textFont(.caption)
                                .foregroundStyle(Palette.subtext)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(Self.leftText(pace))
                                .displayFont(.body, weight: .bold)
                                .foregroundStyle(Self.leftColor(pace))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    ReviewReportStat(
                        title: "使った",
                        value: ReviewYen.text(spent),
                        note: spentNote
                    )

                    ReviewReportStat(
                        title: "1 日あたり",
                        value: ReviewYen.text(spent / totalDays),
                        note: "\(totalDays) 日で割った額"
                    )
                }

                if let previousTotal = content.previousTotal {
                    GridRow {
                        ReviewReportStat(
                            title: "\(previousName)より",
                            value: ReviewYen.signed(spent - previousTotal),
                            note: "\(previousName) \(ReviewYen.text(previousTotal))",
                            color: spent <= previousTotal ? Palette.accent : Palette.increase
                        )
                        .gridCellColumns(2)
                    }
                }
            }
            .reviewStatGrid()
        }
        .reviewHero()
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

    var spentNote: String {
        guard let pace = content.pace else {
            return "\(content.streak.count) 件の記録"
        }

        return "\(pace.limitName(unit: unit)) \(ReviewYen.text(pace.limit))"
    }

    static func leftColor(_ pace: ReviewPace) -> Color {
        pace.remaining >= 0 ? Palette.accent : Palette.increase
    }

    static func leftText(_ pace: ReviewPace) -> String {
        let amount = ReviewYen.text(abs(pace.remaining))

        switch pace.basis {
        case .budget: return pace.remaining >= 0 ? "\(amount) 余り" : "\(amount) 超え"
        case .average: return pace.remaining >= 0 ? "\(amount) 少ない" : "\(amount) 多い"
        }
    }

    func leadCaption(_ pace: ReviewPace) -> String {
        if pace.basis == .budget,
           content.budgetStreak >= 2 {
            return "\(content.budgetStreak) \(periodsUnit)つづけて"
        }

        return pace.basis == .budget ? "予算より" : "平均より"
    }
}
