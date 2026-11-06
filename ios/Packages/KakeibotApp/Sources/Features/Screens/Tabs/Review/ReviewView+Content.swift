import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    var content: some View {
        TwoColumnStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(ReviewKind.allCases, id: \.self) { kind in
                    kindTile(kind)
                }
            }
            .animation(.snappy, value: model.kind)

            detailCard

            if model.kind == .balance {
                let moves = model.moves

                if !moves.isEmpty {
                    moveCard(moves)
                }
            }

            if model.kind != .balance {
                let categoryShares = model.categoryShares
                let walletShares = model.walletShares

                if model.list == nil {
                    EmptyView()
                } else if categoryShares.isEmpty,
                          walletShares.isEmpty {
                    PlaceholderEmpty(
                        systemImage: "chart.pie",
                        text: "この期間の記録はありません",
                        onRecord: {
                            onAddEntry(recordDate)
                        }
                    )
                    .padding(.horizontal, 16)
                    .card()
                    .layoutColumn(.trailing)
                } else {
                    ReviewSharesCard(
                        title: "カテゴリごと",
                        type: model.entryType,
                        shares: categoryShares,
                        total: ReviewSharesCard.Total(
                            title: totalTitle,
                            amount: model.total
                        ),
                        onOpen: { share in
                            openShare = share
                        }
                    )
                    .layoutColumn(.trailing)

                    ReviewSharesCard(
                        title: "口座ごと",
                        type: model.entryType,
                        shares: walletShares,
                        total: nil,
                        onOpen: { share in
                            openShare = share
                        }
                    )
                    .layoutColumn(.trailing)
                }
            }

            let tallies = model.stampTallies

            if tallies.isEmpty {
                stampHint
                    .layoutColumn(.trailing)
            } else {
                StampTallyCard(
                    tallies: tallies,
                    emptyText: "この期間に押したスタンプはありません",
                    onOpen: { tally in
                        openStamp = tally
                    }
                )
                .layoutColumn(.trailing)
            }
        }
    }
}

private extension ReviewView {
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

            if hasRecurringRow || showsMoveRow {
                VStack(alignment: .leading, spacing: 0) {
                    if let recurring = model.recurringTotal {
                        Button {
                            openShare = model.recurringShare
                        } label: {
                            HStack(spacing: 4) {
                                Label(recurringText(recurring), systemImage: "repeat")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                            .tapArea(Self.rowTapOutsets(top: true, bottom: !showsMoveRow))
                        }
                        .buttonStyle(.plain)
                    }

                    if showsMoveRow {
                        Button {
                            select(.balance)
                        } label: {
                            HStack(spacing: 4) {
                                Label(moveText, systemImage: "arrow.right")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                            .tapArea(Self.rowTapOutsets(top: !hasRecurringRow, bottom: true))
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

    var stampHint: some View {
        Label("記録のカレンダーで日を選ぶと、スタンプを押せます", systemImage: "seal")
            .textFont(.footnote)
            .foregroundStyle(Palette.subtext)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(16))
                    .strokeBorder(Palette.outline, style: .dashed)
            }
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.kind
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let rim = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let titleColor = isSelected ? Palette.accent : Palette.subtext
        let change = model.change(of: kind)

        return Button {
            select(kind)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ViewThatFits(in: .horizontal) {
                        Text(tileTitle(of: kind))
                            .fixedSize()

                        Text(Self.title(of: kind))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .textFont(.caption)
                    .foregroundStyle(titleColor)

                    Spacer(minLength: 0)

                    if model.hasPreviousEntries {
                        Image(systemName: Self.changeImage(change))
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Self.changeColor(change, of: kind))
                    }
                }

                tileAmount(of: kind)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                fill,
                in: RoundedRectangle(cornerRadius: corner.radius(16))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(16))
                    .strokeBorder(rim, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func tileAmount(of kind: ReviewKind) -> some View {
        let total = model.total(of: kind)

        if kind == .balance {
            AmountText(
                total,
                font: .size(.body),
                sign: .plus,
                color: ReviewText.balanceColor(total)
            )
        } else {
            AmountText(total, type: kind.entryType, font: .size(.body))
        }
    }

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
    var hasRecurringRow: Bool {
        model.recurringTotal != nil
    }

    var showsMoveRow: Bool {
        model.kind == .expense && !model.moves.isEmpty
    }

    var totalTitle: String {
        Self.title(of: model.kind)
    }

    var recordDate: LocalDate {
        let range = model.period.range
        return range.contains(model.today) ? model.today : range.lowerBound
    }

    var selectedChangeColor: Color {
        Self.changeColor(model.change, of: model.kind)
    }

    var moveText: String {
        let total = ReviewModel.total(of: model.moves)
        return "ほかに返済と積立 \(AmountText.text(total))"
    }

    var comparisonText: String {
        guard model.hasPreviousEntries else {
            return "比べる記録がまだありません"
        }

        let previous = model.isComparingPartially
            ? Self.partialName(of: model.scale)
            : Self.previousName(of: model.scale)

        let change = model.change
        let amount = AmountText.text(abs(change))

        if change > 0 {
            return "\(previous)より \(amount) 多い"
        }

        if change < 0 {
            return "\(previous)より \(amount) 少ない"
        }

        return "\(previous)と同じ"
    }

    static func changeImage(_ change: Int) -> String {
        if change > 0 {
            return "arrow.up.right"
        }

        return change < 0 ? "arrow.down.right" : "equal"
    }

    static func changeColor(
        _ change: Int,
        of kind: ReviewKind
    ) -> Color {
        guard change != 0 else {
            return Palette.subtext
        }

        let isGood = kind == .expense ? change < 0 : change > 0

        return isGood ? Palette.accent : Palette.rose
    }

    static func title(of kind: ReviewKind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .balance: "収支"
        }
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

    func tileTitle(of kind: ReviewKind) -> String {
        guard kind == .balance else {
            return Self.title(of: kind)
        }

        return ReviewText.balanceTitle(model.total(of: kind))
    }

    func recurringText(_ recurring: Int) -> String {
        let other = model.total(of: model.kind) - recurring
        let fixed = "固定費 \(AmountText.text(recurring))"
        return "\(fixed)・それ以外 \(AmountText.text(other))"
    }

    func balanceRatio(of amount: Int) -> Double {
        let income = model.summary.income.total
        let expense = model.summary.expense.total
        let largest = max(income, expense)
        return largest > 0 ? Double(amount) / Double(largest) : 0
    }

    func select(_ kind: ReviewKind) {
        model.setKind(kind)

        Task {
            await model.saveSelection()
        }
    }
}
