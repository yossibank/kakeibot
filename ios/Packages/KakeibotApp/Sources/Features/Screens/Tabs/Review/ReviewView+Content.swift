import Core
import DesignSystem
import Store
import SwiftUI

extension ReviewView {
    var content: some View {
        VStack(spacing: 12) {
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
                if model.categoryShares.isEmpty,
                   model.walletShares.isEmpty {
                    ReviewSharesCard(
                        title: nil,
                        shares: [],
                        total: nil,
                        onOpen: { _ in }
                    )
                } else {
                    ReviewSharesCard(
                        title: "カテゴリごと",
                        shares: model.categoryShares,
                        total: ReviewSharesCard.Total(
                            title: totalTitle,
                            amount: model.total
                        ),
                        onOpen: { share in
                            openShare = share
                        }
                    )

                    ReviewSharesCard(
                        title: "口座ごと",
                        shares: model.walletShares,
                        total: nil,
                        onOpen: { share in
                            openShare = share
                        }
                    )
                }
            }

            if !model.stampTallies.isEmpty {
                stampCard
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

            if model.recurringTotal != nil
                || (model.kind == .expense && !model.moves.isEmpty) {
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
                            .frame(minHeight: 24)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }

                    if model.kind == .expense,
                       !model.moves.isEmpty {
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
                            .frame(minHeight: 24)
                            .contentShape(.rect)
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
                        tint: Palette.accent
                    )

                    balanceBar(
                        "支出",
                        amount: model.summary.expense.total,
                        tint: Palette.accentStrong
                    )
                }
                .padding(.top, 8)
            }

            if let usage = model.budgetUsage {
                VStack(spacing: 8) {
                    HStack {
                        Text("予算 \(AmountText.text(usage.budget))")

                        Spacer()

                        Text(usage.remainingText)
                    }
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                    UsageBar(usage)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var stampCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("押したスタンプ")

            LazyVGrid(columns: Self.stampColumns, alignment: .leading) {
                ForEach(model.stampTallies) { tally in
                    Button {
                        openStamp = tally
                    } label: {
                        HStack(spacing: 8) {
                            IconSeal(tally.icon, size: 28)

                            Text("×\(tally.count)")
                                .displayFont(.body)
                                .monospacedDigit()
                                .foregroundStyle(Palette.accentStrong)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.kind
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let rim = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let titleColor = isSelected ? Palette.accent : Palette.subtext
        let amountColor = isSelected ? Palette.accentStrong : Palette.text
        let change = model.change(of: kind)

        return Button {
            select(kind)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(Self.title(of: kind))
                        .textFont(.caption)
                        .foregroundStyle(titleColor)

                    Spacer(minLength: 0)

                    if model.hasPreviousEntries {
                        Image(systemName: Self.changeImage(change))
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Self.changeColor(change, of: kind))
                    }
                }

                Text(AmountText.text(model.total(of: kind)))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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

    func balanceBar(
        _ title: String,
        amount: Int,
        tint: Color
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer()

                Text(AmountText.text(amount))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)
            }

            RatioBar(balanceRatio(of: amount), tint: tint, height: 6)
        }
    }
}

private extension ReviewView {
    static let stampColumns = [
        GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .leading)
    ]

    var totalTitle: String {
        Self.title(of: model.kind)
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
