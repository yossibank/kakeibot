import Core
import DesignSystem
import SwiftUI

extension EntryItemSheet {
    enum Field: Hashable {
        case store
        case name
    }

    enum Target: Hashable {
        case unit
        case quantity
    }

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
                text: $name,
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

            Keypad(calculator: activeCalculator) { key in
                press(key)
            }

            PrimaryButton(editingIndex == nil ? "追加" : "変更") {
                submit()
            }
            .disabled(!canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .background {
            EntryReceiptShape(tooth: 12, hasTopEdge: true, hasBottomEdge: false)
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.6), radius: 12, y: -2)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    func edit(_ index: Int) {
        guard model.items.indices.contains(index) else {
            return
        }

        let item = model.items[index]
        let price = EntryModel.unitPrice(of: item)

        openIndex = nil
        focus = nil

        withoutAnimation {
            name = item.name
            unit = AmountCalculator(amount: price.unit)
            quantity = AmountCalculator(amount: price.quantity)
            target = .unit
            editingIndex = index
            editingItem = item
        }

        withAnimation(.snappy) {
            isSlipOpen = true
        }
    }

    func remove(_ index: Int) {
        openIndex = nil

        if let editingIndex {
            if editingIndex == index {
                resetInput()
            } else if editingIndex > index {
                self.editingIndex = editingIndex - 1
            }
        }

        withAnimation(.snappy) {
            removed = model.removeItem(at: index)
        }
    }
}

private extension EntryItemSheet {
    var slipTitle: String {
        editingIndex.map { "品目 \($0 + 1) を変更" } ?? "品目を追加"
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var quantityValue: Int {
        max(1, quantity.amount)
    }

    var keptItem: EntryItem.Draft? {
        guard let editingItem else {
            return nil
        }

        let price = EntryModel.unitPrice(of: editingItem)
        let shownUnit = AmountCalculator(amount: price.unit).amount
        let shownQuantity = AmountCalculator(amount: price.quantity).amount

        guard
            unit.amount == shownUnit,
            quantity.amount == shownQuantity
        else {
            return nil
        }

        return editingItem
    }

    var lineQuantity: Int {
        keptItem?.quantity ?? quantityValue
    }

    var lineAmount: Int {
        keptItem?.amount ?? unit.amount * quantityValue
    }

    var canSubmit: Bool {
        guard !trimmedName.isEmpty else {
            return false
        }

        return keptItem != nil || (unit.amount > 0 && lineAmount <= AmountCalculator.maxValue)
    }

    var activeCalculator: AmountCalculator {
        target == .unit ? unit : quantity
    }

    var suggestions: [String] {
        model.itemNameSuggestions(for: name)
    }

    var equation: some View {
        HStack(spacing: 8) {
            token(AmountText.text(unit.amount), label: "単価", for: .unit)

            Text("×")
                .textFont(.body)
                .foregroundStyle(Palette.subtext)

            token("\(quantityValue)", label: "数量", for: .quantity)

            Spacer(minLength: 8)

            Text("=")
                .textFont(.body)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(lineAmount))
                .displayFont(.title, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    func token(
        _ value: String,
        label: String,
        for target: Target
    ) -> some View {
        let isSelected = self.target == target

        return Button {
            self.target = target
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
            name = suggestion
            focus = nil
        } content: {
            Text(suggestion)
                .sharedTextScale()
        }
    }

    func press(_ key: AmountCalculator.Key) {
        switch target {
        case .unit: unit.press(key)
        case .quantity: quantity.press(key)
        }
    }

    func openSlip() {
        resetInput()

        withAnimation(.snappy) {
            isSlipOpen = true
        }

        focus = .name
    }

    func submit() {
        guard canSubmit else {
            return
        }

        if let editingIndex {
            model.updateItem(
                at: editingIndex,
                name: trimmedName,
                quantity: lineQuantity,
                amount: lineAmount
            )
        } else {
            withAnimation(.snappy) {
                model.addItem(
                    name: trimmedName,
                    quantity: quantityValue,
                    amount: lineAmount
                )
            }
        }

        resetInput()
    }

    func closeSlip() {
        focus = nil
        resetInput()

        withAnimation(.snappy) {
            isSlipOpen = false
        }
    }

    func resetInput() {
        withoutAnimation {
            name = ""
            unit = AmountCalculator()
            quantity = AmountCalculator(amount: 1)
            target = .unit
            editingIndex = nil
            editingItem = nil
        }
    }

    func withoutAnimation(_ change: () -> Void) {
        var transaction = Transaction()

        transaction.disablesAnimations = true

        withTransaction(transaction, change)
    }
}
