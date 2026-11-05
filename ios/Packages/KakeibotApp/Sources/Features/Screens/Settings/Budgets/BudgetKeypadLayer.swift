import Core
import DesignSystem
import SwiftUI

extension View {
    func budgetKeypad(
        _ model: BudgetListModel,
        cleared: Binding<BudgetListModel.Cleared?> = .constant(nil)
    ) -> some View {
        modifier(
            BudgetKeypadLayer(
                cleared: cleared,
                model: model
            )
        )
    }
}

private struct BudgetKeypadLayer: ViewModifier {
    @Binding var cleared: BudgetListModel.Cleared?

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.calculator.amount)

                if !model.suggestions.isEmpty {
                    suggestionRow
                }

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
            ForEach(model.suggestions, id: \.self) { suggestion in
                suggestionChip(suggestion)
            }
        }
        .frame(maxWidth: .infinity)
    }

    func suggestionChip(_ suggestion: BudgetListModel.Suggestion) -> some View {
        ChipButton(
            isSelected: model.calculator.amount == suggestion.amount,
            width: .fill
        ) {
            model.choose(suggestion)
        } content: {
            VStack(spacing: 0) {
                Text(suggestion.title)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(suggestion.amount))
                    .monospacedDigit()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 4)
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
