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

struct ReviewReportGauge: View {
    let pace: ReviewPace
    let limitName: String
    let showsMarker: Bool

    var body: some View {
        let used = min(pace.usedRatio, 1)
        let color = pace.verdict == .over ? Palette.increase : Palette.accent

        ZStack {
            Circle()
                .stroke(Palette.accent.opacity(.subtle), lineWidth: 10)

            Circle()
                .trim(from: 0, to: used)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if showsMarker {
                Capsule()
                    .fill(Palette.text)
                    .frame(width: 3, height: 20)
                    .offset(y: -60)
                    .rotationEffect(.degrees(360 * pace.elapsedRatio))
            }

            VStack(spacing: 0) {
                Text("\(limitName)の")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(ReviewPace.percent(pace.usedRatio))%")
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
}

struct ReviewReportStat: View {
    let title: String
    let value: String
    let note: String
    var color: Color = Palette.text

    var body: some View {
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
        switch goal.kind {
        case .count: "\(name)を、\(unit) \(goal.target) 回までに"
        case .average: "\(name)の 1 回を、\(ReviewYen.text(goal.target)) までに"
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
