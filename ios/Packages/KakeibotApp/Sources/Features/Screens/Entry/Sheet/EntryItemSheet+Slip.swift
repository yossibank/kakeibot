import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension EntryItemSheet {
    enum Field: Hashable {
        case store
        case name
    }
}

extension EntryItemSheet {
    var addBar: some View {
        PrimaryButton("＋ 品目を追加") {
            openSlip()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    var slip: some View {
        VStack(spacing: 12) {
            HStack {
                SectionTitle(slipTitle)

                Spacer()

                RingButton(systemImage: "xmark") {
                    closeSlip()
                }
            }

            SettingsField(
                "品名",
                text: Bindable(items.state).draft.name,
                focus: $focus,
                field: .name
            )

            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            suggestionButton(suggestion)
                        }
                    }
                    .sharesTextScale(id: suggestions)
                }
                .scrollIndicators(.hidden)
            }

            EntryReceiptRule(style: .dashed)

            equation

            Keypad(calculator: draft.activeCalculator, accessories: accessories) { key in
                items.state.draft.press(key)
            }

            PrimaryButton(draft.editing == nil ? "追加" : "変更") {
                submit()
            }
            .disabled(!draft.canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            EntryReceiptShape(tooth: 12, hasTopEdge: false, hasBottomEdge: false)
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.6), radius: 12, y: -2)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    func edit(_ index: Int) {
        guard model.state.items.list.indices.contains(index) else {
            return
        }

        items.state.openIndex = nil
        focus = nil

        withoutAnimation {
            items.edit(index, in: model)
        }

        showSlip(scrollingTo: index)
    }

    func remove(_ index: Int) {
        items.state.openIndex = nil

        if draft.isEditing(index) {
            resetInput()
        } else {
            items.state.draft.shiftEditing(afterRemoving: index)
        }

        withAnimation(.snappy) {
            items.remove(index, from: model)
        }
    }

    func showSlip(scrollingTo index: Int) {
        withAnimation(.snappy) {
            items.state.isSlipOpen = true
        } completion: {
            items.scroll(to: index, in: model)
        }
    }
}

private extension EntryItemSheet {
    var equation: some View {
        let lineColor = draft.isDiscount ? Palette.rose : Palette.accentStrong

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                token(Yen.text(draft.unit.amount), label: "単価", for: .unit)

                Text("×")
                    .textFont(.body)
                    .foregroundStyle(Palette.subtext)

                token("\(draft.quantityValue)", label: "数量", for: .quantity)

                Spacer(minLength: 4)

                Text("=")
                    .textFont(.body)
                    .foregroundStyle(Palette.subtext)

                AmountText(
                    draft.lineAmount,
                    font: .size(.headline, weight: .bold),
                    color: lineColor
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            CapsulePicker(
                selection: Bindable(items.state).draft.taxRate,
                options: Self.taxOptions,
                size: .small
            )
            .fixedSize()
        }
    }

    func token(
        _ value: String,
        label: String,
        for target: EntryItemModel.Target
    ) -> some View {
        let isSelected = draft.target == target

        return Button {
            items.state.draft.target = target
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .textFont(.footnote)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.subtext)

                Text(value)
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Palette.accentStrong : Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                isSelected ? Palette.accent.opacity(.subtle) : Color.clear,
                in: .rect(cornerRadius: corner.radius(8))
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func suggestionButton(_ suggestion: String) -> some View {
        ChipButton {
            items.state.draft.name = suggestion
            focus = nil
        } content: {
            Text(suggestion)
                .sharedTextScale()
        }
    }
}

private extension EntryItemSheet {
    static let taxOptions: [CapsulePicker<EntryItem.TaxRate?>.Option] = [
        .init("税込", value: nil),
        .init("8%", value: .reduced),
        .init("10%", value: .standard)
    ]

    var slipTitle: String {
        draft.editing.map { "品目 \($0.index + 1) を変更" } ?? "品目を追加"
    }

    var accessories: [Keypad.Accessory] {
        [
            Keypad.Accessory("値引", isActive: draft.isDiscount) {
                items.state.draft.toggleDiscount()
            },
            Keypad.Accessory("半額") {
                items.state.draft.halveUnit()
            }
        ]
    }

    var suggestions: [String] {
        model.output.itemNameSuggestions(for: draft.name)
    }

    func openSlip() {
        resetInput()
        showSlip(scrollingTo: model.state.items.list.count - 1)
        focus = .name
    }

    func submit() {
        guard draft.canSubmit else {
            return
        }

        if draft.editing != nil {
            items.update(in: model)
            closeSlip()
        } else {
            withAnimation(.snappy) {
                items.add(to: model)
            }

            resetInput()
            items.scroll(to: model.state.items.list.count - 1, in: model)
        }
    }

    func closeSlip() {
        focus = nil

        guard
            let geometry = layout.scrollGeometry,
            geometry.contentOffset.y > settledOffset(of: geometry) + 1
        else {
            withAnimation(.snappy) {
                items.state.isSlipOpen = false
            }

            return
        }

        withAnimation(.smooth(duration: 0.35)) {
            layout.scrollPosition.scrollTo(y: settledOffset(of: geometry))
        } completion: {
            withAnimation(.snappy) {
                items.state.isSlipOpen = false
            }
        }
    }

    func settledOffset(of geometry: ScrollGeometry) -> CGFloat {
        let insets = geometry.contentInsets
        let grownHeight = geometry.containerSize.height + layout.slipHeight - layout.barHeight
        let maxOffset = geometry.contentSize.height + insets.bottom - grownHeight
        return max(-insets.top, maxOffset)
    }

    func resetInput() {
        withoutAnimation {
            items.reset(for: model)
        }
    }

    func withoutAnimation(_ change: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }
}
