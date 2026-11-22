import Core
import DesignSystem
import SwiftUI

struct ReviewProgressView: View {
    let pace: ReviewPace?
    let unit: String
    let currentName: String
    let goals: [ReviewGoalItem]
    let closingTitle: String
    let closingDate: LocalDate
    let nextGoalTitle: String
    let previousTitle: String
    let onOpenPrevious: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let pace {
                paceCard(pace)
            }

            ForEach(goals) { item in
                goalCard(item)
            }

            closingCard
        }
    }
}

private extension ReviewProgressView {
    var closingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: closingTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(closingDate.yearMonth.month)/\(closingDate.day) に届きます")
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.text)

                Text("締めると、AI がまとめます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }

            VStack(spacing: 0) {
                closingRow("checkmark", "一手の答え合わせ")
                closingRow("arrow.left.arrow.right", "いつもと比べて、多めと少なめ")
                closingRow("star", "よかったこと")
                closingRow("arrow.right", nextGoalTitle)
            }

            Button(action: onOpenPrevious) {
                HStack {
                    Text(previousTitle)
                        .textFont(.footnote, weight: .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .sansFont(.small, weight: .bold)
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .card(cornerRadius: 16)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    Palette.accent.opacity(.muted),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
        }
    }

    func paceCard(_ pace: ReviewPace) -> some View {
        let limitName = pace.limitName(unit: unit)
        let leadColor = pace.lead >= 0 ? Palette.accent : Palette.increase

        return VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: "いまのペース")

            HStack(spacing: 16) {
                ReviewReportGauge(pace: pace, limitName: limitName, showsMarker: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(Self.verdictText(pace))
                        .displayFont(.title, weight: .bold)
                        .foregroundStyle(Palette.gold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ペースより")
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)

                        Text(Self.leadText(pace))
                            .displayFont(.body, weight: .bold)
                            .foregroundStyle(leadColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    ReviewReportStat(
                        title: "使った",
                        value: ReviewYen.text(pace.spent),
                        note: "\(limitName) \(ReviewYen.text(pace.limit))"
                    )

                    ReviewReportStat(
                        title: "今日までの目安",
                        value: "\(ReviewPace.percent(pace.elapsedRatio))%",
                        note: "ゲージの針の位置"
                    )
                }

                GridRow {
                    ReviewReportStat(
                        title: "残りの 1 日に使える",
                        value: ReviewYen.text(pace.perDay),
                        note: Self.perDayNote(pace)
                    )

                    ReviewReportStat(
                        title: "このままだと\(unit)末",
                        value: Self.projectedText(pace),
                        note: "今のペースの見込み",
                        color: pace.projectedLeft >= 0 ? Palette.accent : Palette.increase
                    )
                }
            }
            .reviewStatGrid()
        }
        .reviewHero()
    }

    func closingRow(
        _ systemImage: String,
        _ title: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .bold)
                .foregroundStyle(Palette.accent)
                .frame(width: 28, height: 28)
                .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 8))

            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
        }
    }
}

private extension ReviewProgressView {
    static func verdictText(_ pace: ReviewPace) -> String {
        switch (pace.basis, pace.verdict) {
        case (.budget, .onTrack): "おおむね順調"
        case (.budget, .fast): "少し早めです"
        case (.budget, .over): "予算を超えました"
        case (.average, .onTrack): "いつもどおり"
        case (.average, .fast): "いつもより早め"
        case (.average, .over): "いつもより多め"
        }
    }

    static func leadText(_ pace: ReviewPace) -> String {
        let amount = ReviewYen.text(abs(pace.lead))
        return pace.lead >= 0 ? "\(amount) 少ない" : "\(amount) 多い"
    }

    static func perDayNote(_ pace: ReviewPace) -> String {
        guard pace.remaining > 0 else {
            return "\(ReviewYen.text(-pace.remaining)) 超えています"
        }

        return "\(ReviewYen.text(pace.remaining)) ÷ \(pace.daysLeft) 日"
    }

    static func projectedText(_ pace: ReviewPace) -> String {
        let amount = ReviewYen.text(abs(pace.projectedLeft))
        return pace.projectedLeft >= 0 ? "\(amount) 余る" : "\(amount) 足りない"
    }
}
