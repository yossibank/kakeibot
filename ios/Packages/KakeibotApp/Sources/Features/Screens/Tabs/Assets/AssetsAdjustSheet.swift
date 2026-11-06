import Core
import DesignSystem
import SwiftUI

struct AssetsAdjustSheet: View {
    @State private var model: AssetsAdjustModel
    @State private var isConfirmingDiscard = false

    @Environment(\.dismiss) private var dismiss

    init(model: AssetsAdjustModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        FittedSheet {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    SheetTitle("残高を合わせる")

                    Text("\(model.wallet.name) · 記録の残高 \(AmountText.text(model.balance))")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                VStack(spacing: 4) {
                    Text("いま手元にある額")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.subtext)

                    SettingsKeypadValue(model.calculator.amount)

                    Text(model.differenceText)
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Keypad(
                    calculator: model.calculator,
                    onKey: model.press
                )

                PrimaryButton("合わせる") {
                    Task {
                        await save()
                    }
                }
                .disabled(!model.canSave)
            }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
    }
}

private extension AssetsAdjustSheet {
    func save() async {
        if await model.save() {
            dismiss()
        }
    }
}
