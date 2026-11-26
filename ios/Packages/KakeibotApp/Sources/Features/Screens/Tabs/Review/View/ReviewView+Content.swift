import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewView {
    var content: some View {
        TwoColumnStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(ReviewKind.allCases, id: \.self) { kind in
                    kindTile(kind)
                }
            }
            .animation(.snappy, value: model.input.kind)

            detailCard

            if model.input.kind == .balance {
                let moves = model.output.moves

                if !moves.isEmpty {
                    moveCard(moves)
                }
            }

            if model.input.kind != .balance {
                shareCards
            }

            let tallies = model.output.stampTallies

            if !tallies.isEmpty {
                StampTallyCard(
                    tallies: tallies,
                    emptyText: "この期間に押したスタンプはありません",
                    onOpen: { tally in
                        model.state.sheet = .stamp(tally)
                    }
                )
                .layoutColumn(.trailing)
            }

            storeReviewCard
                .layoutColumn(.trailing)
        }
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

    func select(_ kind: ReviewKind) {
        model.setKind(kind)

        model.perform {
            await $0.saveSelection()
        }
    }
}

private extension ReviewView {
    @ViewBuilder
    var shareCards: some View {
        let categoryShares = model.output.categoryShares
        let walletShares = model.output.walletShares
        let isEmpty = categoryShares.isEmpty && walletShares.isEmpty

        if !model.input.list.isLoaded {
            EmptyView()
        } else if isEmpty {
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
                type: model.output.entryType,
                shares: categoryShares,
                total: ReviewSharesCard.Total(
                    title: totalTitle,
                    amount: model.output.total
                ),
                onOpen: { share in
                    model.state.sheet = .share(share)
                }
            )
            .layoutColumn(.trailing)

            ReviewSharesCard(
                title: "口座ごと",
                type: model.output.entryType,
                shares: walletShares,
                total: nil,
                onOpen: { share in
                    model.state.sheet = .share(share)
                }
            )
        }
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.input.kind
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let rim = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let titleColor = isSelected ? Palette.accent : Palette.subtext
        let change = model.output.change(of: kind)

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

                    if model.output.hasPreviousEntries {
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
        let total = model.output.total(of: kind)

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
}

private extension ReviewView {
    var totalTitle: String {
        Self.title(of: model.input.kind)
    }

    var recordDate: LocalDate {
        let range = model.output.period.range
        return range.contains(model.state.today) ? model.state.today : range.lowerBound
    }

    func tileTitle(of kind: ReviewKind) -> String {
        guard kind == .balance else {
            return Self.title(of: kind)
        }

        return ReviewText.balanceTitle(model.output.total(of: kind))
    }
}
