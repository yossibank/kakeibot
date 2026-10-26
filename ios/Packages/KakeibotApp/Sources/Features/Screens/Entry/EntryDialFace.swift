import Core
import DesignSystem
import SwiftUI

struct EntryDialFace: View {
    @Environment(\.themeStyle.displayFont) private var themeFont

    let model: EntryModel

    var body: some View {
        ZStack(alignment: .bottom) {
            HalfDial(progress: usage?.progress, tint: usage?.tint ?? Palette.accent)

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    if model.type == .transfer, let route = model.routeText {
                        Image(systemName: "arrow.left.arrow.right")
                            .sansFont(.caption, weight: .semibold)

                        Text(route)
                            .lineLimit(1)
                    } else if let category = model.selectedCategory {
                        IconImage(model.icon(for: category), size: 13)

                        Text(category.name)
                            .lineLimit(1)
                    }
                }
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.accentStrong)
                .frame(maxWidth: Self.width * 0.7, minHeight: 20)

                Text(AmountText.text(model.amount))
                    .font(amountFont)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .editBadge()
                    .frame(height: Self.amountHeight)

                Text(note ?? " ")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(noteColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: Self.width * 0.7)
            }
            .padding(.bottom, Self.lift)
        }
        .frame(width: Self.width)
        .contentShape(.rect)
    }
}

extension EntryDialFace {
    static let width: CGFloat = 320
}

private extension EntryDialFace {
    static let amountHeight: CGFloat = 48
    static let lift: CGFloat = 12

    var usage: BudgetUsage? {
        model.budgetUsage
    }

    var amountFont: Font {
        let size: CGFloat = model.amount < 100_000 ? 40 : 28
        return .display(size: size, weight: .semibold, in: themeFont)
    }

    var note: String? {
        if let expression = model.expressionText {
            return expression
        }

        if model.type == .transfer {
            return model.sourceBalanceText
        }

        return usage.map { "\($0.remainingTitle) \($0.remainingAmountText)" }
    }

    var noteColor: Color {
        if model.expressionText == nil, model.isOverSourceBalance {
            return Palette.rose
        }

        guard
            model.expressionText == nil,
            let usage
        else {
            return Palette.subtext
        }

        return usage.isOver || usage.isNearLimit ? usage.tint : Palette.subtext
    }
}
