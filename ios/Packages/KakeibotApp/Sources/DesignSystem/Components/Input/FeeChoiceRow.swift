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
        .sensoryFeedback(.selection, trigger: selection)
    }
}

public extension FeeChoiceRow {
    static let defaultChoices = [110, 220, 330, 440]
}

private extension FeeChoiceRow {
    static let height: CGFloat = 34

    func button(_ amount: Int) -> some View {
        let isApplied = selection == amount
        let stroke = isApplied ? Palette.accent : Palette.accent.opacity(.soft)
        let fill = isApplied ? Palette.accent.opacity(.subtle) : Color.clear
        let title = amount == 0 ? "なし" : AmountText.text(amount)

        return Button {
            onSelect(amount)
        } label: {
            Text(title)
                .textFont(size: .caption)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: Self.height)
                .background(fill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
