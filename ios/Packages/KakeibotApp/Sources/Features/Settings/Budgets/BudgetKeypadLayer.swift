import Core
import DesignSystem
import SwiftUI

extension View {
    func budgetKeypad(_ model: BudgetListModel) -> some View {
        modifier(BudgetKeypadLayer(model: model))
    }
}

private struct BudgetKeypadLayer: ViewModifier {
    let model: BudgetListModel

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if model.editing != nil {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        model.cancelEditing()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                drawer
                    .transition(.settingsDrawer)
                    .zIndex(1)
            }
        }
        .animation(.snappy, value: model.editing)
    }
}

private extension BudgetKeypadLayer {
    var drawer: some View {
        SettingsDrawer(model.editingTitle) {
            Task {
                await model.finishEditing()
            }
        } content: {
            VStack(spacing: 10) {
                Text(AmountText.text(model.calculator.amount))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.calculator.amount)

                Keypad(activeTax: model.calculator.taxNote?.rate) { key in
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
