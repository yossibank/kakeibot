import Core
import DesignSystem
import SwiftUI

extension View {
    func budgetKeypad(_ model: BudgetListModel) -> some View {
        modifier(BudgetKeypadLayer(model: model))
    }
}

private struct BudgetKeypadLayer: ViewModifier {
    @State private var isConfirmingDiscard = false

    let model: BudgetListModel

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if model.editing != nil {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        close()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                drawer
                    .transition(.settingsDrawer)
                    .zIndex(1)
            }
        }
        .animation(.snappy, value: model.editing)
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            model.cancelEditing()
        }
    }
}

private extension BudgetKeypadLayer {
    var drawer: some View {
        SettingsDrawer(model.editingTitle, showsDone: false) {
            Task {
                await model.finishEditing()
            }
        } content: {
            VStack(spacing: 12) {
                Text(AmountText.text(model.calculator.amount))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.calculator.amount)

                Keypad(calculator: model.calculator) {
                    Task {
                        await model.finishEditing()
                    }
                } onKey: { key in
                    model.press(key)
                }

                PrimaryButton(model.saveTitle) {
                    Task {
                        await model.save()
                    }
                }
                .disabled(!model.canSave)

                if model.editingAmount != nil {
                    Button("予算をなくす") {
                        Task {
                            await model.clear()
                        }
                    }
                    .textFont(.footnote)
                    .foregroundStyle(Palette.rose)
                    .frame(minHeight: 36)
                }
            }
        }
    }
}

private extension BudgetKeypadLayer {
    func close() {
        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            model.cancelEditing()
        }
    }
}
