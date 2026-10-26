import Core
import DesignSystem
import SwiftUI

struct EntryFeeRow: View {
    let model: EntryModel

    var body: some View {
        HStack(spacing: 8) {
            button(0)

            ForEach(EntryModel.feeChoices, id: \.self) { amount in
                button(amount)
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: model.fee)
    }
}

private extension EntryFeeRow {
    static let height: CGFloat = 34

    func button(_ amount: Int) -> some View {
        let isApplied = model.fee == amount
        let stroke = isApplied ? Palette.accent : Palette.accent.opacity(.soft)
        let title = amount == 0 ? "なし" : AmountText.text(amount)

        return Button {
            model.setFee(amount)
        } label: {
            Text(title)
                .textFont(size: .caption)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: Self.height)
                .background(EntrySheet.categoryFill(isApplied), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
