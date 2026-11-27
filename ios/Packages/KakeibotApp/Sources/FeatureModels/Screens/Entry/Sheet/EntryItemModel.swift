import Core
import Observation

@MainActor
@Observable
public final class EntryItemModel {
    public let state: State

    init(
        isSlipOpen: Bool,
        wait: ScreenWait
    ) {
        self.state = State(isSlipOpen: isSlipOpen, wait: wait)
    }
}

public extension EntryItemModel {
    enum Target: Hashable, Sendable {
        case unit
        case quantity
    }

    enum Presented: Hashable, Sendable {
        case help
    }

    struct Editing: Equatable, Sendable {
        public let index: Int

        let item: EntryItem.Draft
    }

    struct Draft: Equatable, Sendable {
        public var name = ""
        public var taxRate: EntryItem.TaxRate?
        public var target: Target = .unit

        public private(set) var unit = AmountCalculator()
        public private(set) var quantity = AmountCalculator(amount: 1)
        public private(set) var isDiscount = false
        public private(set) var editing: Editing?

        init(taxRate: EntryItem.TaxRate? = nil) {
            self.taxRate = taxRate
        }

        init(
            editing item: EntryItem.Draft,
            at index: Int
        ) {
            let price = EntryModel.unitPrice(of: item)

            self.name = item.name
            self.taxRate = item.taxRate
            self.unit = AmountCalculator(amount: abs(price.unit))
            self.quantity = AmountCalculator(amount: price.quantity)
            self.isDiscount = item.amount < 0
            self.editing = Editing(index: index, item: item)
        }
    }

    struct Fields: ScreenEditable {
        public var draft = Draft()
        public var openIndex: Int?
        public var isSlipOpen: Bool
    }

    @MainActor
    @Observable
    final class State {
        public var fields: Fields
        public var presented = Shown<Presented>()

        public internal(set) var scroll = ScreenOutcome<Int>()

        public let removed: UndoNotice<EntryModel.RemovedItem>

        init(
            isSlipOpen: Bool,
            wait: ScreenWait
        ) {
            self.fields = Fields(isSlipOpen: isSlipOpen)
            self.removed = UndoNotice(wait: wait)
        }
    }
}

public extension EntryItemModel {
    func reset(for entry: EntryModel) {
        state.fields.draft = Draft(taxRate: entry.state.items.list.last?.taxRate)
    }

    func edit(
        _ index: Int,
        in entry: EntryModel
    ) {
        guard entry.state.items.list.indices.contains(index) else {
            return
        }

        state.fields.draft = Draft(editing: entry.state.items.list[index], at: index)
    }

    func add(to entry: EntryModel) {
        let draft = state.fields.draft

        entry.state.addItem(
            name: draft.trimmedName,
            quantity: draft.quantityValue,
            amount: draft.lineAmount,
            taxRate: draft.taxRate
        )
    }

    func update(in entry: EntryModel) {
        let draft = state.fields.draft

        guard let editing = draft.editing else {
            return
        }

        entry.state.updateItem(
            at: editing.index,
            name: draft.trimmedName,
            quantity: draft.lineQuantity,
            amount: draft.lineAmount,
            taxRate: draft.taxRate
        )
    }

    func remove(
        _ index: Int,
        from entry: EntryModel
    ) {
        if let removed = entry.state.removeItem(at: index) {
            state.removed.show(removed)
        }
    }

    func restore(
        _ removed: EntryModel.RemovedItem,
        in entry: EntryModel
    ) {
        state.fields.draft.shiftEditing(afterRestoring: removed.index)
        entry.state.restoreItem(removed)
    }

    func scroll(
        to index: Int,
        in entry: EntryModel
    ) {
        guard entry.state.items.list.indices.contains(index) else {
            return
        }

        state.scroll.send(index)
    }
}

public extension EntryItemModel.Draft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var quantityValue: Int {
        max(1, quantity.amount)
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

    var activeCalculator: AmountCalculator {
        target == .unit ? unit : quantity
    }

    func isEditing(_ index: Int) -> Bool {
        editing?.index == index
    }

    mutating func press(_ key: AmountCalculator.Key) {
        switch target {
        case .unit: unit.press(key)
        case .quantity: quantity.press(key)
        }
    }

    mutating func halveUnit() {
        target = .unit
        unit = AmountCalculator(amount: unit.amount / 2)
    }

    mutating func toggleDiscount() {
        isDiscount.toggle()
    }

    mutating func shiftEditing(afterRemoving index: Int) {
        if let editing,
           editing.index > index {
            self.editing = EntryItemModel.Editing(index: editing.index - 1, item: editing.item)
        }
    }

    mutating func shiftEditing(afterRestoring index: Int) {
        if let editing,
           index <= editing.index {
            self.editing = EntryItemModel.Editing(index: editing.index + 1, item: editing.item)
        }
    }
}

private extension EntryItemModel.Draft {
    var keptItem: EntryItem.Draft? {
        guard let item = editing?.item else {
            return nil
        }

        let price = EntryModel.unitPrice(of: item)
        let shownUnit = AmountCalculator(amount: abs(price.unit)).amount
        let shownQuantity = AmountCalculator(amount: price.quantity).amount

        guard
            unit.amount == shownUnit,
            quantity.amount == shownQuantity,
            isDiscount == (item.amount < 0)
        else {
            return nil
        }

        return item
    }
}
