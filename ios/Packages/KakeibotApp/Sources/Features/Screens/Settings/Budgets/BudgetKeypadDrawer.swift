import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension View {
    func budgetKeypad(_ model: BudgetListModel) -> some View {
        modifier(BudgetKeypadDrawer(model: model))
    }
}

private struct BudgetKeypadDrawer: ViewModifier {
    let model: BudgetListModel

    func body(content: Content) -> some View {
        content
            .settingsDrawerLayer(item: model.state.editing) {
                model.closeEditing()
            } drawer: { _ in
                drawer
            }
            .animation(.snappy, value: model.state.editing)
            .confirmsDiscard(
                when: model.output.isChanged,
                isPresented: Bindable(model.state).isConfirmingDiscard
            ) {
                model.cancelEditing()
            }
    }
}

private extension BudgetKeypadDrawer {
    var drawer: some View {
        SettingsDrawer(model.output.editingTitle, showsDone: false) {
            model.perform {
                await $0.finishEditing()
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
                    model.perform {
                        await $0.finishEditing()
                    }
                } onKey: { key in
                    model.state.press(key)
                }

                PrimaryButton(model.output.saveTitle) {
                    model.perform {
                        await $0.save()
                    }
                }
                .disabled(!model.output.canSave)

                if model.output.editingAmount != nil {
                    Button {
                        model.perform {
                            await $0.clear()
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
