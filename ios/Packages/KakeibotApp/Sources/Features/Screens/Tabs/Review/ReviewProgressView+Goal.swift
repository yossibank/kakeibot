import Core
import DesignSystem
import SwiftUI

extension ReviewProgressView {
    func goalCard(_ item: ReviewGoalItem) -> some View {
        let status = item.goal.status(of: item.progress)

        return VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: "\(currentName)の一手")

            ReviewEmphasisText(
                parts: item.titleParts(unit: unit),
                face: .display(.headline),
                weight: .bold,
                numberFace: .display(.title),
                color: Palette.text
            )
            .fixedSize(horizontal: false, vertical: true)

            if item.goal.kind == .count {
                pips(count: item.progress.count, target: item.goal.target)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline) {
                    goalNote(item)

                    Spacer(minLength: 8)

                    goalStatus(status)
                }

                VStack(alignment: .leading, spacing: 4) {
                    goalNote(item)

                    goalStatus(status)
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
        ReviewEmphasisText(
            parts: Self.goalNote(item),
            face: .text(.caption),
            weight: nil,
            numberFace: .display(.body),
            color: Palette.subtext
        )
        .fixedSize()
    }

    @ViewBuilder
    func goalStatus(_ status: ReviewGoal.Status?) -> some View {
        if let status {
            let color = status == .within ? Palette.accent : Palette.increase

            Text(Self.statusText(status))
                .textFont(.caption, weight: .bold)
                .foregroundStyle(color)
                .fixedSize()
        }
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
    static func goalNote(_ item: ReviewGoalItem) -> [ReviewEmphasisText.Part] {
        let goal = item.goal
        let progress = item.progress

        switch goal.kind {
        case .count:
            let left = max(goal.target - progress.count, 0)

            return [
                .plain("今 "),
                .number("\(progress.count)"),
                .plain(" 回　あと "),
                .number("\(left)"),
                .plain(" 回まで")
            ]

        case .average:
            let average = ReviewYen.number(goal.current(of: progress))

            return [
                .plain("今の 1 回の平均 "),
                .number(average),
                .plain("円（\(progress.count) 回）")
            ]
        }
    }

    static func statusText(_ status: ReviewGoal.Status) -> String {
        switch status {
        case .within: "このペースなら収まりそう"
        case .likelyOver: "このペースだと超えそう"
        case .over: "上限を超えました"
        }
    }
}
