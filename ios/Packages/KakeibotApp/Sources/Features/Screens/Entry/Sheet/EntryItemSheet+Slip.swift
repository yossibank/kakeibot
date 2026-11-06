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

    struct ScrollRequest: Equatable {
        let id = UUID()
        let index: Int
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

            Keypad(calculator: activeCalculator, accessories: accessories) { key in
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
        .fixedSize(horizontal: false, vertical: true)
        .background {
            EntryReceiptShape(tooth: 12, hasTopEdge: false, hasBottomEdge: false)
                .fill(Palette.paper)
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
            unit = AmountCalculator(amount: abs(price.unit))
            quantity = AmountCalculator(amount: price.quantity)
            target = .unit
            editingIndex = index
            editingItem = item
            taxRate = item.taxRate
            isDiscount = item.amount < 0
        }

        showSlip(scrollingTo: index)
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

    func scroll(to index: Int) {
        guard model.items.indices.contains(index) else {
            return
        }

        scrollRequest = ScrollRequest(index: index)
    }

    func showSlip(scrollingTo index: Int) {
        withAnimation(.snappy) {
            isSlipOpen = true
        } completion: {
            scroll(to: index)
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
        let shownUnit = AmountCalculator(amount: abs(price.unit)).amount
        let shownQuantity = AmountCalculator(amount: price.quantity).amount

        guard
            unit.amount == shownUnit,
            quantity.amount == shownQuantity,
            isDiscount == (editingItem.amount < 0)
        else {
            return nil
        }

        return editingItem
    }

    var lineQuantity: Int {
        keptItem?.quantity ?? quantityValue
    }

    var lineAmount: Int {
        let sign = isDiscount ? -1 : 1
        return keptItem?.amount ?? sign * unit.amount * quantityValue
    }

    var canSubmit: Bool {
        guard !trimmedName.isEmpty else {
            return false
        }

        return keptItem != nil || (unit.amount > 0 && abs(lineAmount) <= AmountCalculator.maxValue)
    }

    var accessories: [Keypad.Accessory] {
        [
            Keypad.Accessory("値引", isActive: isDiscount) {
                isDiscount.toggle()
            },
            Keypad.Accessory("半額") {
                halveUnit()
            }
        ]
    }

    var activeCalculator: AmountCalculator {
        target == .unit ? unit : quantity
    }

    var suggestions: [String] {
        model.itemNameSuggestions(for: name)
    }

    var equation: some View {
        let lineColor = isDiscount ? Palette.rose : Palette.accentStrong

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                token(AmountText.text(unit.amount), label: "単価", for: .unit)

                Text("×")
                    .textFont(.body)
                    .foregroundStyle(Palette.subtext)

                token("\(quantityValue)", label: "数量", for: .quantity)

                Spacer(minLength: 4)

                Text("=")
                    .textFont(.body)
                    .foregroundStyle(Palette.subtext)

                AmountText(
                    lineAmount,
                    font: .size(.headline, weight: .bold),
                    color: lineColor
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            CapsulePicker(selection: $taxRate, options: Self.taxOptions, size: .small)
                .fixedSize()
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

    func halveUnit() {
        target = .unit
        unit = AmountCalculator(amount: unit.amount / 2)
    }

    func openSlip() {
        resetInput()
        showSlip(scrollingTo: model.items.count - 1)
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
                amount: lineAmount,
                taxRate: taxRate
            )

            closeSlip()
        } else {
            withAnimation(.snappy) {
                model.addItem(
                    name: trimmedName,
                    quantity: quantityValue,
                    amount: lineAmount,
                    taxRate: taxRate
                )
            }

            resetInput()
            scroll(to: model.items.count - 1)
        }
    }

    func closeSlip() {
        focus = nil

        guard
            let geometry = scrollGeometry,
            geometry.contentOffset.y > settledOffset(of: geometry) + 1
        else {
            withAnimation(.snappy) {
                isSlipOpen = false
            }

            return
        }

        withAnimation(.smooth(duration: 0.35)) {
            scrollPosition.scrollTo(y: settledOffset(of: geometry))
        } completion: {
            withAnimation(.snappy) {
                isSlipOpen = false
            }
        }
    }

    func settledOffset(of geometry: ScrollGeometry) -> CGFloat {
        let insets = geometry.contentInsets
        let grownHeight = geometry.containerSize.height + slipHeight - barHeight
        let maxOffset = geometry.contentSize.height + insets.bottom - grownHeight
        return max(-insets.top, maxOffset)
    }

    func resetInput() {
        withoutAnimation {
            name = ""
            unit = AmountCalculator()
            quantity = AmountCalculator(amount: 1)
            target = .unit
            editingIndex = nil
            editingItem = nil
            taxRate = model.items.last?.taxRate
            isDiscount = false
        }
    }

    func withoutAnimation(_ change: () -> Void) {
        var transaction = Transaction()

        transaction.disablesAnimations = true

        withTransaction(transaction, change)
    }
}
