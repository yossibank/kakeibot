import Core
import DesignSystem
import SwiftUI

extension View {
    func budgetKeypad(
        _ model: BudgetListModel,
        cleared: Binding<BudgetListModel.Cleared?> = .constant(nil)
    ) -> some View {
        modifier(
            BudgetKeypadDrawer(
                cleared: cleared,
                model: model
            )
        )
    }
}

private struct BudgetKeypadDrawer: ViewModifier {
    @Binding var cleared: BudgetListModel.Cleared?

    @State private var isConfirmingDiscard = false

    let model: BudgetListModel

    func body(content: Content) -> some View {
        content
            .settingsDrawerLayer(item: model.state.editing) {
                close()
            } drawer: { _ in
                drawer
            }
            .animation(.snappy, value: model.state.editing)
            .confirmsDiscard(
                when: model.output.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                model.cancelEditing()
            }
    }
}

private extension BudgetKeypadDrawer {
    var drawer: some View {
        SettingsDrawer(model.output.editingTitle, showsDone: false) {
            Task {
                await model.finishEditing()
            }
        } content: {
            VStack(spacing: 12) {
                AmountText(
                    model.state.calculator.amount,
                    font: .size(.largeTitle, weight: .bold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.state.calculator.amount)

                if !model.output.suggestions.isEmpty {
                    suggestionRow
                }

                Keypad(calculator: model.state.calculator) {
                    Task {
                        await model.finishEditing()
                    }
                } onKey: { key in
                    model.state.press(key)
                }

                PrimaryButton(model.output.saveTitle) {
                    Task {
                        await model.save()
                    }
                }
                .disabled(!model.output.canSave)

                if model.output.editingAmount != nil {
                    Button {
                        Task {
                            if let result = await model.clear() {
                                cleared = result
                            }
                        }
                    } label: {
                        Text("予算をなくす")
                            .textFont(.footnote)
                            .foregroundStyle(Palette.rose)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .contentShape(.rect)
                    }
                }
            }
        }
    }

    var suggestionRow: some View {
        HStack(spacing: 8) {
            ForEach(model.output.suggestions, id: \.self) { suggestion in
                suggestionChip(suggestion)
            }
        }
        .frame(maxWidth: .infinity)
    }

    func suggestionChip(_ suggestion: BudgetListModel.Suggestion) -> some View {
        ChipButton(
            isSelected: model.state.calculator.amount == suggestion.amount,
            width: .fill
        ) {
            model.state.choose(suggestion)
        } content: {
            VStack(spacing: 0) {
                Text(suggestion.title)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                AmountText(suggestion.amount, font: .size(.caption))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 4)
        }
    }
}

private extension BudgetKeypadDrawer {
    func close() {
        if model.output.isChanged {
            isConfirmingDiscard = true
        } else {
            model.cancelEditing()
        }
    }
}
