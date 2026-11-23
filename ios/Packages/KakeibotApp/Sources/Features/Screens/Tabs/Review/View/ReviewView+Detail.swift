import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    var detailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if model.hasPreviousEntries {
                    Image(systemName: Self.changeImage(model.change))
                        .sansFont(.caption)
                        .foregroundStyle(selectedChangeColor)
                }

                Text(comparisonText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
            }

            if hasRecurringRow || hasUpcomingRow || showsMoveRow {
                VStack(alignment: .leading, spacing: 0) {
                    if let recurring = model.recurringTotal {
                        Button {
                            openShare = model.recurringShare
                        } label: {
                            HStack(spacing: 4) {
                                Label(recurringText(recurring), systemImage: "repeat")

                                DisclosureMark(.link)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: rowMinHeight,
                                alignment: .leading
                            )
                            .tapArea(Self.rowTapOutsets(top: true, bottom: isLastRow(.recurring)))
                        }
                        .buttonStyle(.plain)
                    }

                    if let upcoming = model.upcomingRecurringTotal {
                        let outsets = Self.rowTapOutsets(
                            top: isFirstRow(.upcoming),
                            bottom: isLastRow(.upcoming)
                        )

                        upcomingRow(
                            upcoming,
                            tapOutsets: outsets,
                            minHeight: rowMinHeight
                        )
                    }

                    if showsMoveRow {
                        Button {
                            select(.balance)
                        } label: {
                            HStack(spacing: 4) {
                                Label(moveText, systemImage: "arrow.right")

                                DisclosureMark(.link)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: rowMinHeight,
                                alignment: .leading
                            )
                            .tapArea(Self.rowTapOutsets(top: isFirstRow(.move), bottom: true))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if model.kind == .balance {
                VStack(spacing: 12) {
                    balanceBar(
                        "収入",
                        amount: model.summary.income.total,
                        type: .income
                    )

                    balanceBar(
                        "支出",
                        amount: model.summary.expense.total,
                        type: .expense
                    )
                }
                .padding(.top, 8)
            }

            if let usage = model.budgetUsage {
                VStack(spacing: 8) {
                    HStack {
                        Text(usage.budgetText)
                            .sharedTextScale()

                        Spacer()

                        Text(usage.remainingText)
                            .sharedTextScale()
                    }
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .sharesTextScale(id: [usage.budgetText, usage.remainingText])

                    BudgetUsageBar(usage)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private extension ReviewView {
    func balanceBar(
        _ title: String,
        amount: Int,
        type: Entry.Kind
    ) -> some View {
        let tint = type == .income ? Palette.accent : Palette.accentStrong

        return VStack(spacing: 4) {
            HStack {
                Text(title)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer()

                AmountText(amount, type: type, font: .size(.body))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            RatioBar(balanceRatio(of: amount), tint: tint, height: 6)
        }
    }
}

private extension ReviewView {
    enum DetailRow {
        case recurring
        case upcoming
        case move
    }

    var hasRecurringRow: Bool {
        model.recurringTotal != nil
    }

    var hasUpcomingRow: Bool {
        model.upcomingRecurringTotal != nil
    }

    var showsMoveRow: Bool {
        model.kind == .expense && !model.moves.isEmpty
    }

    var detailRows: [DetailRow] {
        let recurring: [DetailRow] = hasRecurringRow ? [.recurring] : []
        let upcoming: [DetailRow] = hasUpcomingRow ? [.upcoming] : []
        let move: [DetailRow] = showsMoveRow ? [.move] : []
        return recurring + upcoming + move
    }

    var rowMinHeight: CGFloat? {
        detailRows.count > 1 ? 24 : nil
    }

    var selectedChangeColor: Color {
        Self.changeColor(model.change, of: model.kind)
    }

    var moveText: String {
        let total = ReviewModel.total(of: model.moves)
        return "ほかに返済と積立 \(Yen.text(total))"
    }

    var comparisonText: String {
        guard model.hasPreviousEntries else {
            return "比べる記録がまだありません"
        }

        let previous = model.isComparingPartially
            ? Self.partialName(of: model.scale)
            : Self.previousName(of: model.scale)

        let change = model.change
        let amount = Yen.text(abs(change))

        if change > 0 {
            return "\(previous)より \(amount) 多い"
        }

        if change < 0 {
            return "\(previous)より \(amount) 少ない"
        }

        return "\(previous)と同じ"
    }

    static func previousName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "前の週"
        case .month: "前の月"
        case .year: "前の年"
        }
    }

    static func partialName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "前の週の同じ曜日まで"
        case .month: "前の月の同じ日まで"
        case .year: "前の年の同じ日まで"
        }
    }

    static func rowTapOutsets(
        top: Bool,
        bottom: Bool
    ) -> EdgeInsets {
        EdgeInsets(
            top: top ? 10 : 0,
            leading: 0,
            bottom: bottom ? 10 : 0,
            trailing: 0
        )
    }

    func recurringText(_ recurring: Int) -> String {
        let other = model.total(of: model.kind) - recurring
        let fixed = "固定費 \(Yen.text(recurring))"
        return "\(fixed)・それ以外 \(Yen.text(other))"
    }

    func isFirstRow(_ row: DetailRow) -> Bool {
        detailRows.first == row
    }

    func isLastRow(_ row: DetailRow) -> Bool {
        detailRows.last == row
    }

    func balanceRatio(of amount: Int) -> Double {
        let income = model.summary.income.total
        let expense = model.summary.expense.total
        let largest = max(income, expense)
        return largest > 0 ? Double(amount) / Double(largest) : 0
    }
}
