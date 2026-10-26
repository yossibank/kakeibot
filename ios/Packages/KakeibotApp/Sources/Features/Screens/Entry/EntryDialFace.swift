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
                    if let category = model.selectedCategory {
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

                Text(note ?? " ")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(noteColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: Self.width * 0.7)
            }
        }
        .frame(width: Self.width)
        .contentShape(.rect)
    }
}

extension EntryDialFace {
    static let width: CGFloat = 304
}

private extension EntryDialFace {
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

        return usage.map { "\($0.remainingTitle) \($0.remainingAmountText)" }
    }

    var noteColor: Color {
        guard
            model.expressionText == nil,
            let usage
        else {
            return Palette.subtext
        }

        return usage.isOver || usage.isNearLimit ? usage.tint : Palette.subtext
    }
}
