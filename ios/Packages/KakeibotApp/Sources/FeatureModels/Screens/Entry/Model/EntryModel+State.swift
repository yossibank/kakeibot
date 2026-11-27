import Core
import DesignSystem
import Observation

public extension EntryModel {
    struct Payment: Equatable {
        public internal(set) var toWalletId: Wallet.ID?
        public internal(set) var billMonth: YearMonth?

        public private(set) var date: LocalDate
        public private(set) var walletId: Wallet.ID?

        init(date: LocalDate) {
            self.date = date
        }
    }

    struct CategoryChoice: Equatable {
        public internal(set) var tagId: EntryTag.ID?

        public private(set) var id: EntryCategory.ID?

        private(set) var byType: [Entry.Kind: EntryCategory.ID] = [:]
    }

    enum KeypadTarget: Hashable {
        case amount
        case fee
    }

    struct Keypad: Equatable {
        public internal(set) var calculator = AmountCalculator()
        public internal(set) var feeCalculator = AmountCalculator()
        public internal(set) var target: KeypadTarget = .amount
    }

    struct Items: Equatable {
        public internal(set) var list: [EntryItem.Draft] = []
        public internal(set) var taxIncluded = false

        var receiptStore: String?
        var isReceiptRead = false
    }

    struct Filled {
        public internal(set) var voice: VoiceFilled?

        var templateId: EntryTemplate.ID?
    }

    struct Fields: ScreenEditable {
        public var memo = ""
    }

    struct Closing: Equatable, Sendable {
        public private(set) var hasBegun = false

        public init() {}
    }

    enum Outcome: Hashable, Sendable {
        case ready(isFirst: Bool)
        case closed(EntryChange)
        case continued(EntryChange)
        case categoryMoved
        case categoryAdded
        case walletChosen
    }

    struct Presented: ScreenEditable {
        public var overlay = Shown<Overlay>()
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice
        public let deletion: UndoNotice<Deletion>
        public let hiddenCategory: UndoNotice<HiddenCategory>

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
            self.deletion = UndoNotice(wait: wait)
            self.hiddenCategory = UndoNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public let notices: Notices
        public let task = ModelTask()

        public internal(set) var outcome = ScreenOutcome<Outcome>()
        public internal(set) var closing = Closing()
        public internal(set) var screen: Screen
        public internal(set) var type: Entry.Kind
        public internal(set) var payment: Payment
        public internal(set) var category = CategoryChoice()
        public internal(set) var keypad = Keypad()
        public internal(set) var items = Items()
        public internal(set) var filled = Filled()

        init(
            type: Entry.Kind,
            date: LocalDate,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.type = type
            self.payment = Payment(date: date)
            self.screen = Screen(deck: EntryModel.Deck.start(for: type))
        }
    }
}

public extension EntryModel.Items {
    var totals: EntryItemTotal {
        EntryItemTotal(list, taxIncluded: taxIncluded)
    }
}

extension EntryModel.Items {
    var canAdjust: Bool {
        (0...AmountCalculator.maxValue).contains(totals.total)
    }

    mutating func forgetReadNames() {
        for index in list.indices {
            list[index].readName = nil
        }
    }
}

public extension EntryModel.Closing {
    mutating func begin() {
        hasBegun = true
    }

    mutating func cancel() {
        hasBegun = false
    }
}

public extension EntryModel.Keypad {
    var active: AmountCalculator {
        target == .fee ? feeCalculator : calculator
    }
}

extension EntryModel.Keypad {
    mutating func press(_ key: AmountCalculator.Key) {
        switch target {
        case .amount: calculator.press(key)
        case .fee: feeCalculator.press(key)
        }
    }

    mutating func setAmount(_ amount: Int) {
        calculator = AmountCalculator(amount: amount)
    }

    mutating func setFee(_ amount: Int) {
        feeCalculator = AmountCalculator(amount: amount)
    }
}

extension EntryModel.CategoryChoice {
    mutating func select(_ id: EntryCategory.ID?) {
        guard id != self.id else {
            return
        }

        self.id = id
        tagId = nil
    }

    mutating func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    mutating func remember(for type: Entry.Kind) {
        byType[type] = id
    }

    func tags(in allTags: [EntryTag]) -> [EntryTag] {
        allTags.filter { tag in
            tag.categoryId == id
                && (tag.archivedAt == nil || tag.id == tagId)
        }
    }
}

extension EntryModel.Payment {
    mutating func setDate(_ date: LocalDate) {
        guard date != self.date else {
            return
        }

        self.date = date
        billMonth = nil
    }
}

private extension EntryModel.Payment {
    mutating func setWallet(_ id: Wallet.ID?) -> Bool {
        guard id != walletId else {
            return false
        }

        walletId = id
        billMonth = nil

        return true
    }
}

public extension EntryModel.Fields {
    var store: String {
        get {
            memoLines[0]
        }
        set {
            var lines = memoLines
            lines[0] = newValue.replacingOccurrences(of: "\n", with: " ")
            memo = lines.joined(separator: "\n")
        }
    }
}

private extension EntryModel.Fields {
    var memoLines: [String] {
        memo.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }
}

public extension EntryModel.State {
    func setDate(_ date: LocalDate) {
        payment.setDate(date)
    }

    func setDestination(_ id: Wallet.ID?) {
        payment.toWalletId = id
    }

    func setCategory(_ id: EntryCategory.ID?) {
        category.select(id)
    }

    func toggleTag(_ id: EntryTag.ID) {
        category.toggleTag(id)
    }

    func press(_ key: AmountCalculator.Key) {
        keypad.press(key)
    }

    func enter(_ target: EntryModel.KeypadTarget) {
        keypad.target = type == .transfer ? target : .amount
    }

    func setFee(_ amount: Int) {
        keypad.setFee(amount)
    }

    func addItem(
        name: String,
        quantity: Int = 1,
        amount: Int,
        taxRate: EntryItem.TaxRate? = nil
    ) {
        let draft = EntryItem.Draft(
            name: name,
            quantity: quantity,
            amount: amount,
            taxRate: taxRate
        )

        changeItems {
            items.list.append(draft)
        }
    }

    func updateItem(
        at index: Int,
        name: String,
        quantity: Int = 1,
        amount: Int,
        taxRate: EntryItem.TaxRate? = nil
    ) {
        guard items.list.indices.contains(index) else {
            return
        }

        changeItems {
            items.list[index].name = name
            items.list[index].quantity = quantity
            items.list[index].amount = amount
            items.list[index].taxRate = taxRate
        }
    }

    func removeItem(at index: Int) -> EntryModel.RemovedItem? {
        guard items.list.indices.contains(index) else {
            return nil
        }

        let removed = EntryModel.RemovedItem(index: index, item: items.list[index])

        changeItems {
            items.list.remove(at: index)
        }

        return removed
    }

    func restoreItem(_ removed: EntryModel.RemovedItem) {
        let index = min(removed.index, items.list.count)

        changeItems {
            items.list.insert(removed.item, at: index)
        }
    }

    func setTaxIncluded(_ isIncluded: Bool) {
        changeItems {
            items.taxIncluded = isIncluded
        }
    }

    func adjustToItems() {
        guard items.canAdjust else {
            return
        }

        keypad.setAmount(items.totals.total)
    }
}

extension EntryModel.State {
    func setWallet(
        _ id: Wallet.ID?,
        offering categories: [EntryCategory],
        allCategories: [EntryCategory],
        allTags: [EntryTag]
    ) {
        guard payment.setWallet(id),
              let categoryId = category.id,
              let current = allCategories.first(where: { $0.id == categoryId }),
              !categories.contains(where: { $0.id == categoryId })
        else {
            return
        }

        let tagName = allTags.first { $0.id == category.tagId }?.name
        let fitted = categories.first { $0.name == current.name } ?? categories.first

        category.select(fitted?.id)
        category.tagId = category.tags(in: allTags).first { $0.name == tagName }?.id
    }

    func clearForNext() {
        keypad = EntryModel.Keypad()
        fields.memo = ""
        items = EntryModel.Items()
        category.tagId = nil
        payment.billMonth = nil
        filled = EntryModel.Filled()
    }
}

private extension EntryModel.State {
    func changeItems(_ change: () -> Void) {
        let amount = keypad.calculator.amount
        let follows = amount == 0 || amount - items.totals.total == 0

        change()

        if follows {
            adjustToItems()
        }
    }
}
