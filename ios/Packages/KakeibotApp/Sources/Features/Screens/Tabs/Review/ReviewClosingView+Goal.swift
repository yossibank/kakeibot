import Core
import DesignSystem
import SwiftUI

extension ReviewClosingView {
    struct Goals {
        let answer: ReviewGoalItem?
        let next: Next
        let nextName: String
        let nextStart: LocalDate
        let checkDate: LocalDate
    }

    enum Next {
        case none
        case rest
        case goal(ReviewGoalItem, reason: String?)
    }

    @ViewBuilder
    var nextCard: some View {
        switch goals.next {
        case .none:
            EmptyView()

        case .rest:
            restCard

        case let .goal(item, reason):
            ticket(item, reason: reason)
        }
    }

    func answerCard(_ item: ReviewGoalItem) -> some View {
        let goal = item.goal
        let isAchieved = goal.isAchieved ?? false
        let result = goal.result ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                ReviewReportLabel(title: "\(name)の一手")

                Text("答え合わせ")
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .padding(.top, 8)

                Text("「\(item.title(unit: unit))」")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                seal(isAchieved)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.kind == .count ? "\(unit)の回数" : "1 回の平均")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.value(goal.baseline))
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.subtext)
                            .strikethrough()
                            .monospacedDigit()

                        Image(systemName: "arrow.right")
                            .sansFont(.caption, weight: .bold)
                            .foregroundStyle(Palette.accent)

                        Text(item.value(result))
                            .displayFont(.headline, weight: .bold)
                            .foregroundStyle(Palette.text)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("浮いた金額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(ReviewYen.text(goal.saved ?? 0))
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Palette.accent.opacity(.soft))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    var restCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ReviewReportLabel(title: "\(goals.nextName)の一手")

            Text("一手はお休みです")
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .padding(.top, 4)

            Text("いつもより多いカテゴリはありませんでした。このまま続けましょう。")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }

    func ticket(
        _ item: ReviewGoalItem,
        reason: String?
    ) -> some View {
        let goal = item.goal
        let start = goals.nextStart
        let check = goals.checkDate

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ReviewReportLabel(title: "\(goals.nextName)の一手")

                    Text("\(start.yearMonth.month)/\(start.day) から")
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(Palette.backgroundBottom)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.gold, in: Capsule())
                        .fixedSize()
                }

                Text(item.title(unit: unit))
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.gold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)

                if let reason {
                    Text(reason)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("\(name) \(item.value(goal.baseline)) → 目標 \(item.value(goal.target))")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .monospacedDigit()
            }
            .padding(20)

            Rectangle()
                .stroke(
                    Palette.accent.opacity(.muted),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            HStack {
                Text("守れたら浮く金額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(ReviewYen.text(goal.saving))
                    .displayFont(.largeTitle, weight: .bold)
                    .foregroundStyle(Palette.gold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(20)

            VStack(spacing: 12) {
                Text("途中経過で進み具合を見て、\(check.yearMonth.month)/\(check.day) に答え合わせします")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button {
                    onOpenGoal(item)
                } label: {
                    HStack {
                        Text("\(item.name)をくわしく見る")
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
            .padding([.horizontal, .bottom], 20)
        }
        .reviewTicket()
    }

    func seal(_ isAchieved: Bool) -> some View {
        let color = isAchieved ? Palette.accent : Palette.subtext

        return Text(isAchieved ? "達成" : "あと\n少し")
            .displayFont(.headline, weight: .bold)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .frame(width: 80, height: 80)
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: 2.5)
            }
            .overlay {
                Circle()
                    .strokeBorder(color.opacity(.medium), lineWidth: 1)
                    .padding(4)
            }
            .rotationEffect(.degrees(-12))
    }
}
