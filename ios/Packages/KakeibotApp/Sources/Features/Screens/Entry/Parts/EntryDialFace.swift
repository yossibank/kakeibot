import Core
import DesignSystem
import SwiftUI

struct EntryDialFace: View {
    @Environment(\.themeStyle.displayFont) private var themeFont

    let model: EntryModel
    let onOpenItems: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            HalfDial(progress: progress, tint: tint)

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    if isEnteringFee {
                        Image(systemName: "yensign.circle")
                            .sansFont(.caption, weight: .semibold)

                        Text("手数料")
                    } else if model.type == .transfer,
                              let route = model.routeText {
                        Image(systemName: "arrow.left.arrow.right")
                            .sansFont(.caption, weight: .semibold)

                        Text(route)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else if let category = model.selectedCategory {
                        IconImage(model.icon(for: category), size: 13)

                        Text(category.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.accentStrong)
                .frame(maxWidth: Self.maxWidth * 0.7, minHeight: 20)

                Text(AmountText.text(shownAmount))
                    .font(amountFont)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .editBadge()
                    .frame(height: Self.amountHeight)

                Text(note ?? " ")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(noteColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: Self.maxWidth * 0.7)

                if showsItems {
                    EntryItemButton(
                        count: model.items.count,
                        total: model.itemTotal,
                        adjustment: model.itemAdjustment,
                        onOpen: onOpenItems
                    )
                    .frame(maxWidth: Self.maxWidth * 0.8)
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, Self.lift)
            .offset(y: showsItems ? Self.itemDrop : 0)
        }
        .frame(maxWidth: Self.maxWidth)
        .contentShape(.rect)
    }
}

private extension EntryDialFace {
    static let maxWidth: CGFloat = 320
    static let amountHeight: CGFloat = 48
    static let lift: CGFloat = 12
    static let itemDrop: CGFloat = 24

    var usage: BudgetUsage? {
        model.budgetUsageAfterSave
    }

    var progress: Double? {
        usage?.progress ?? model.transferProgress
    }

    var tint: Color {
        if let usage {
            return usage.tint
        }

        return model.isOverSourceBalance ? Palette.rose : Palette.accent
    }

    var showsItems: Bool {
        model.showsItems && !model.items.isEmpty && !isEnteringFee
    }

    var isEnteringFee: Bool {
        model.keypadTarget == .fee
    }

    var shownAmount: Int {
        isEnteringFee ? model.fee : model.amount
    }

    var amountFont: Font {
        let size: CGFloat = shownAmount < 100_000 ? 40 : 28
        return .display(size: size, weight: .semibold, in: themeFont)
    }

    var note: String? {
        if let expression = model.expressionText {
            return expression
        }

        if isEnteringFee {
            return "振替 \(AmountText.text(model.amount))"
        }

        if model.type == .transfer,
           model.fee > 0 {
            let fee = "手数料 \(AmountText.text(model.fee))"
            return [fee, model.sourceBalanceText].compactMap(\.self).joined(separator: "・")
        }

        if model.type == .transfer {
            return model.sourceBalanceText
        }

        return model.budgetText ?? model.monthTotalText
    }

    var noteColor: Color {
        if model.expressionText == nil,
           model.isOverSourceBalance {
            return Palette.rose
        }

        guard
            model.expressionText == nil,
            let usage
        else {
            return Palette.subtext
        }

        return usage.isOver || usage.isNearLimit
            ? usage.tint
            : Palette.subtext
    }
}
