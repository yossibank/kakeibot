import Core
import DesignSystem
import Store
import SwiftUI

struct AssetsGoalSheet: View {
    @State private var model: AssetsGoalEditModel
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    init(model: AssetsGoalEditModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            SettingsField(
                "欲しい物（例：新しい靴）",
                text: $model.name,
                focus: $focus,
                field: .name
            )

            VStack(spacing: 4) {
                Text("目標の額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(model.calculator.amount))
                    .displayFont(.title)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.calculator.amount)
            }

            Spacer(minLength: 0)

            Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                focus = nil

                model.press(key)
            }

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "この目標を削除しますか",
            message: "貯金箱の額はそのまま残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
            }
        }
    }
}

private extension AssetsGoalSheet {
    enum Field: Hashable {
        case name
    }

    var title: String {
        model.isEditing ? "目標を編集" : "目標を決める"
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text(title)
                .displayFont(.body)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            if model.isEditing {
                RingButton(
                    systemImage: "trash",
                    style: .destructive,
                    label: "削除"
                ) {
                    isConfirmingDelete = true
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    func save() async {
        focus = nil

        if await model.save() {
            dismiss()
        }
    }

    func delete() async {
        if await model.delete() {
            dismiss()
        }
    }
}
