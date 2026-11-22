import Core
import DesignSystem
import SwiftUI

struct ReviewProgressView: View {
    let pace: ReviewPace?
    let year: ReviewYearProgress?
    let unit: String
    let currentName: String
    let goals: [ReviewGoalItem]
    let closingTitle: String
    let closingDate: LocalDate
    let closingDaysLeft: Int
    let nextGoalTitle: String
    let previousTitle: String
    let onOpenPrevious: () -> Void
    let onOpenMonth: (ReviewYearProgress.Month) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let pace {
                paceCard(pace)
            }

            if let year {
                yearCard(year)
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
        let day = "\(closingDate.yearMonth.month)/\(closingDate.day)"

        return VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: closingTitle)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(day)
                            .displayFont(.largeTitle, weight: .bold)
                            .foregroundStyle(Palette.accent)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Text("に届きます")
                            .displayFont(.body, weight: .bold)
                            .foregroundStyle(Palette.text)
                            .fixedSize()
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            daysLeftChip

                            closingNote
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            daysLeftChip

                            closingNote
                        }
                    }
                }

                Spacer(minLength: 0)

                envelope
            }

            VStack(spacing: 4) {
                closingRow(1, "checkmark.seal", "一手の答え合わせ", "決めた一手を守れたか")
                closingRow(2, "arrow.up.arrow.down", "いつもと比べる", "多めと少なめのカテゴリ")
                closingRow(3, "sparkles", "よかったこと", "減らせた所と続いたこと")
                closingRow(4, "flag", nextGoalTitle, "AI が次の目標を 1 つ決めます")
            }
            .background(alignment: .leading) {
                Rectangle()
                    .fill(Self.pathFill)
                    .frame(width: 2)
                    .frame(width: 40)
                    .padding(.vertical, 24)
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
                .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 16))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }

    var daysLeftChip: some View {
        ReviewReportChip(systemImage: "hourglass", title: "あと \(closingDaysLeft) 日")
            .fixedSize()
    }

    var closingNote: some View {
        Text("締めると、AI がまとめます")
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .fixedSize()
    }

    var envelope: some View {
        ZStack {
            Image(systemName: "envelope")
                .sansFont(.display, weight: .ultraLight)
                .foregroundStyle(Palette.accent.opacity(.medium))

            Circle()
                .fill(Palette.gold)
                .frame(width: 14, height: 14)
                .shadow(color: Palette.accent.opacity(.muted), radius: 3, y: 2)
                .offset(y: 6)
        }
        .frame(width: 64, height: 56)
    }

    func paceCard(_ pace: ReviewPace) -> some View {
        let limitName = pace.limitName(unit: unit)
        let leadColor = pace.lead >= 0 ? Palette.accent : Palette.increase
        let leadSuffix = pace.lead >= 0 ? "少ない" : "多い"
        let projectedColor = pace.projectedLeft >= 0 ? Palette.accent : Palette.increase
        let projectedBadge = pace.projectedLeft >= 0 ? "余る見込み" : "足りない見込み"
        let lead = ReviewYen.number(abs(pace.lead))
        let spent = ReviewYen.number(pace.spent)
        let elapsed = "\(ReviewPace.percent(pace.elapsedRatio))"
        let perDay = ReviewYen.number(pace.perDay)
        let projected = ReviewYen.number(abs(pace.projectedLeft))

        return VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: "いまのペース")

            ReviewReportGaugeRow(pace: pace, limitName: limitName, showsMarker: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Self.verdictText(pace))
                        .displayFont(.title, weight: .bold)
                        .foregroundStyle(Palette.gold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)

                    ReviewReportLead(
                        caption: "ペースより",
                        value: lead,
                        suffix: leadSuffix,
                        color: leadColor
                    )
                }
            }

            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    ReviewReportStat(
                        title: "使った",
                        systemImage: "yensign.circle",
                        value: spent,
                        unit: "円",
                        note: "\(limitName) \(ReviewYen.text(pace.limit))"
                    )

                    ReviewReportStat(
                        title: "今日までの目安",
                        systemImage: "clock",
                        value: elapsed,
                        unit: "%",
                        progress: pace.elapsedRatio
                    )
                }

                GridRow {
                    ReviewReportStat(
                        title: "残りの 1 日に使える",
                        systemImage: "sun.max",
                        value: perDay,
                        unit: "円",
                        note: Self.perDayNote(pace)
                    )

                    ReviewReportStat(
                        title: "このままだと\(unit)末",
                        systemImage: "arrow.forward",
                        value: projected,
                        unit: "円",
                        badge: projectedBadge,
                        color: projectedColor
                    )
                }
            }
            .reviewStatGrid()
        }
        .reviewHero()
    }

    func closingRow(
        _ number: Int,
        _ systemImage: String,
        _ title: String,
        _ detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.body, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: 40, height: 40)
                .background(Palette.cardTop, in: .rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1.5)
                }
                .shadow(color: Palette.accent.opacity(.subtle), radius: 3, y: 2)
                .overlay(alignment: .topTrailing) {
                    Text("\(number)")
                        .sansFont(.micro, weight: .heavy)
                        .foregroundStyle(Palette.cardBottom)
                        .frame(width: 16, height: 16)
                        .background(Palette.gold, in: Circle())
                        .offset(x: 5, y: -5)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .displayFont(style: .subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(detail)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private extension ReviewProgressView {
    static var pathFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.strong), Palette.accent.opacity(.subtle)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func verdictText(_ pace: ReviewPace) -> String {
        switch (pace.basis, pace.verdict) {
        case (.budget, .onTrack): "おおむね\n順調"
        case (.budget, .fast): "少し\n早めです"
        case (.budget, .over): "予算を\n超えました"
        case (.average, .onTrack): "いつも\nどおり"
        case (.average, .fast): "いつもより\n早め"
        case (.average, .over): "いつもより\n多め"
        }
    }

    static func perDayNote(_ pace: ReviewPace) -> String {
        guard pace.remaining > 0 else {
            return "\(ReviewYen.text(-pace.remaining)) 超えています"
        }

        return "\(ReviewYen.text(pace.remaining)) ÷ \(pace.daysLeft) 日"
    }
}
