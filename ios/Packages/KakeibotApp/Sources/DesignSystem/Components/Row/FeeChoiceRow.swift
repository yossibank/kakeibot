import SwiftUI

public struct FeeChoiceRow: View {
    let choices: [Int]
    let selection: Int
    let onSelect: (Int) -> Void

    public init(
        choices: [Int],
        selection: Int,
        onSelect: @escaping (Int) -> Void
    ) {
        self.choices = choices
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 8) {
            button(0)

            ForEach(choices, id: \.self) { amount in
                button(amount)
            }
        }
        .frame(maxWidth: .infinity)
        .haptic(.selection, trigger: selection)
    }
}

public extension FeeChoiceRow {
    static let defaultChoices = [110, 220, 330, 440]
}

private extension FeeChoiceRow {
    func button(_ amount: Int) -> some View {
        let title = amount == 0 ? "なし" : AmountText.text(amount)

        return ChipButton(
            isSelected: selection == amount,
            width: .fill
        ) {
            onSelect(amount)
        } content: {
            Text(title)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
