import Core
import DesignSystem
import SwiftUI

extension ReviewProgressView {
    func goalCard(_ item: GoalItem) -> some View {
        let isOnTrack = item.goal.isOnTrack(item.progress)

        return VStack(alignment: .leading, spacing: 12) {
            label("\(currentName)の一手")

            Text(Self.goalTitle(item, unit: unit))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            if item.goal.kind == .count {
                pips(count: item.progress.count, target: item.goal.target)
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    goalNote(item)

                    Spacer(minLength: 8)

                    goalStatus(isOnTrack)
                }

                VStack(alignment: .leading, spacing: 4) {
                    goalNote(item)

                    goalStatus(isOnTrack)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewProgressView {
    func goalNote(_ item: GoalItem) -> some View {
        Text(Self.goalNote(item))
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .monospacedDigit()
            .fixedSize()
    }

    func goalStatus(_ isOnTrack: Bool) -> some View {
        Text(isOnTrack ? "このままなら達成" : "このままだと届きません")
            .textFont(.caption, weight: .bold)
            .foregroundStyle(isOnTrack ? Palette.accent : Palette.increase)
            .fixedSize()
    }

    func pips(
        count: Int,
        target: Int
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<max(target, 1), id: \.self) { index in
                Capsule()
                    .fill(index < count ? Palette.accent : Palette.accent.opacity(.subtle))
                    .frame(height: 8)
            }
        }
    }
}

private extension ReviewProgressView {
    static func goalTitle(
        _ item: GoalItem,
        unit: String
    ) -> String {
        switch item.goal.kind {
        case .count: "\(item.name)を、\(unit) \(item.goal.target) 回までに"
        case .average: "\(item.name)の 1 回を、\(ReviewInsight.yen(item.goal.target)) までに"
        }
    }

    static func goalNote(_ item: GoalItem) -> String {
        let goal = item.goal
        let progress = item.progress

        switch goal.kind {
        case .count:
            let left = max(goal.target - progress.count, 0)
            return "今 \(progress.count) 回　あと \(left) 回まで"

        case .average:
            let average = ReviewInsight.yen(goal.current(of: progress))
            return "今の 1 回の平均 \(average)（\(progress.count) 回）"
        }
    }
}
