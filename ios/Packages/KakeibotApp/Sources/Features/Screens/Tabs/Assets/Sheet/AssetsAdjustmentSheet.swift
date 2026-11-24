import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct AssetsAdjustmentSheet: View {
    @State private var model: AssetsAdjustmentModel
    @State private var isConfirmingDiscard = false

    @Environment(\.dismiss) private var dismiss

    init(model: AssetsAdjustmentModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        FittedSheet {
            content
        }
        .errorBanner(Bindable(model.state).errorNotice)
        .confirmation(
            isPresented: $isConfirmingDiscard,
            systemImage: "pencil.slash",
            title: "保存せずに閉じますか",
            message: "入力した内容は残りません",
            keepTitle: "入力に戻る",
            confirmTitle: "保存せずに閉じる"
        ) {
            dismiss()
        }
    }
}

private extension AssetsAdjustmentSheet {
    static let slotSize: CGFloat = 44
    static let shape = EntryReceiptShape(tooth: 12, hasTopEdge: true)
}

private extension AssetsAdjustmentSheet {
    var differenceColor: Color {
        model.output.difference < 0 ? Palette.rose : Palette.accent
    }
}

private extension AssetsAdjustmentSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }
            .frame(width: Self.slotSize, alignment: .leading)

            Spacer()

            SheetTitle("残高を合わせる", wraps: false)

            Spacer()

            Color.clear
                .frame(width: Self.slotSize, height: Self.slotSize)
        }
    }

    var slip: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("残高照合")
                    .textFont(.caption, weight: .semibold)
                    .tracking(4)
                    .foregroundStyle(Palette.accent)

                Text(model.input.wallet.name)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
            }

            EntryReceiptRule(style: .dashed)

            line(
                "記録の残高",
                value: Yen.text(model.input.balance),
                titleColor: Palette.subtext,
                valueColor: Palette.subtext
            )

            handLine

            EntryReceiptRule(style: .double)

            line(
                "調整",
                value: model.output.differenceText,
                titleColor: differenceColor,
                valueColor: model.output.canSave ? differenceColor : Palette.subtext,
                weight: .semibold
            )

            Text(model.output.differenceNote)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background {
            Self.shape
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.6), radius: 12, y: 4)
        }
        .overlay {
            Self.shape
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
    }

    var handLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("手元の額")
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.text)
                .fixedSize()

            EntryReceiptLeader()

            AmountText(
                model.state.calculator.amount,
                font: .size(.title, weight: .bold),
                color: Palette.accentStrong
            )
            .lineLimit(1)
            .fixedSize()
            .contentTransition(.numericText())
            .animation(.snappy, value: model.state.calculator.amount)
        }
    }

    func line(
        _ title: String,
        value: String,
        titleColor: Color,
        valueColor: Color,
        weight: Font.Weight = .regular
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .textFont(.subheadline, weight: weight)
                .foregroundStyle(titleColor)
                .fixedSize()

            EntryReceiptLeader()

            Text(value)
                .textFont(.subheadline, weight: weight)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

private extension AssetsAdjustmentSheet {
    func close() {
        if model.output.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        if await model.save() {
            dismiss()
        }
    }
}

extension AssetsAdjustmentSheet {
    var content: some View {
        VStack(spacing: 20) {
            header

            slip

            Keypad(
                calculator: model.state.calculator,
                onKey: model.state.press
            )

            PrimaryButton(model.output.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.output.canSave)
        }
    }
}
