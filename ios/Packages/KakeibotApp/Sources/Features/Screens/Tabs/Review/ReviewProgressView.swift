import Core
import DesignSystem
import SwiftUI

struct ReviewProgressView: View {
    let pace: ReviewPace?
    let unit: String
    let currentName: String
    let goals: [GoalItem]
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

extension ReviewProgressView {
    struct GoalItem: Identifiable {
        let goal: ReviewGoal
        let name: String
        let progress: ReviewGoal.Progress

        var id: ReviewGoal.ID {
            goal.id
        }
    }

    func label(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .tracking(2)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(Self.labelLine)
                .frame(height: 1)
        }
    }
}

private extension ReviewProgressView {
    var closingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label(closingTitle)

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
        VStack(alignment: .leading, spacing: 16) {
            label("いまのペース")

            HStack(spacing: 16) {
                gauge(pace)

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
                            .foregroundStyle(pace.lead >= 0 ? Palette.accent : Palette.increase)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    stat(
                        "使った",
                        value: ReviewInsight.yen(pace.spent),
                        note: "\(limitName(pace)) \(ReviewInsight.yen(pace.limit))"
                    )

                    stat(
                        "今日までの目安",
                        value: "\(Self.percent(pace.elapsedRatio))%",
                        note: "ゲージの針の位置"
                    )
                }

                GridRow {
                    stat(
                        "残りの 1 日に使える",
                        value: ReviewInsight.yen(pace.perDay),
                        note: Self.perDayNote(pace)
                    )

                    stat(
                        "このままだと\(unit)末",
                        value: Self.projectedText(pace),
                        note: "今のペースの見込み",
                        color: pace.projectedLeft >= 0 ? Palette.accent : Palette.increase
                    )
                }
            }
            .background(Palette.accent.opacity(.soft))
            .clipShape(.rect(cornerRadius: 16))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(Palette.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Self.glow)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(Palette.accent.opacity(.muted))
                }
                .shadow(color: Palette.accent.opacity(.subtle), radius: 16, y: 12)
        }
    }

    func gauge(_ pace: ReviewPace) -> some View {
        let used = min(pace.usedRatio, 1)
        let color = pace.verdict == .over ? Palette.increase : Palette.accent

        return ZStack {
            Circle()
                .stroke(Palette.accent.opacity(.subtle), lineWidth: 10)

            Circle()
                .trim(from: 0, to: used)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Capsule()
                .fill(Palette.text)
                .frame(width: 3, height: 20)
                .offset(y: -60)
                .rotationEffect(.degrees(360 * pace.elapsedRatio))

            VStack(spacing: 0) {
                Text("\(limitName(pace))の")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text("\(Self.percent(pace.usedRatio))%")
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("使いました")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 120, height: 120)
    }

    func stat(
        _ title: String,
        value: String,
        note: String,
        color: Color = Palette.text
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(note)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.cardBottom)
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
    static var glow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), .clear],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 240
        )
    }

    static var labelLine: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.muted), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func percent(_ ratio: Double) -> Int {
        Int((ratio * 100).rounded())
    }

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
        let amount = ReviewInsight.yen(abs(pace.lead))
        return pace.lead >= 0 ? "\(amount) 少ない" : "\(amount) 多い"
    }

    static func perDayNote(_ pace: ReviewPace) -> String {
        guard pace.remaining > 0 else {
            return "\(ReviewInsight.yen(-pace.remaining)) 超えています"
        }

        return "\(ReviewInsight.yen(pace.remaining)) ÷ \(pace.daysLeft) 日"
    }

    static func projectedText(_ pace: ReviewPace) -> String {
        let amount = ReviewInsight.yen(abs(pace.projectedLeft))
        return pace.projectedLeft >= 0 ? "\(amount) 余る" : "\(amount) 足りない"
    }

    static func periodsUnit(_ unit: String) -> String {
        unit == "月" ? "か月" : unit
    }

    func limitName(_ pace: ReviewPace) -> String {
        switch pace.basis {
        case .budget: "予算"
        case let .average(periods): "\(periods) \(Self.periodsUnit(unit))の平均"
        }
    }
}
