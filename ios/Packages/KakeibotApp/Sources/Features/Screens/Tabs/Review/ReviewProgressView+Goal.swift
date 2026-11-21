import Core
import DesignSystem
import SwiftUI

extension ReviewProgressView {
    func goalCard(_ item: ReviewGoalItem) -> some View {
        let isOnTrack = item.goal.isOnTrack(item.progress)

        return VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: "\(currentName)の一手")

            Text(item.title(unit: unit))
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
    func goalNote(_ item: ReviewGoalItem) -> some View {
        Text(Self.goalNote(item))
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .monospacedDigit()
            .fixedSize()
    }

    func goalStatus(_ isOnTrack: Bool) -> some View {
        let color = isOnTrack ? Palette.accent : Palette.increase

        return Text(isOnTrack ? "このままなら達成" : "このままだと届きません")
            .textFont(.caption, weight: .bold)
            .foregroundStyle(color)
            .fixedSize()
    }

    func pips(
        count: Int,
        target: Int
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<max(target, 1), id: \.self) { index in
                let fill = index < count ? Palette.accent : Palette.accent.opacity(.subtle)

                Capsule()
                    .fill(fill)
                    .frame(height: 8)
            }
        }
    }
}

private extension ReviewProgressView {
    static func goalNote(_ item: ReviewGoalItem) -> String {
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
