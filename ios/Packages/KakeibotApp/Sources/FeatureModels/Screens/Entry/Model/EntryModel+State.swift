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

        mutating func setDate(_ date: LocalDate) {
            guard date != self.date else {
                return
            }

            self.date = date
            billMonth = nil
        }

        fileprivate mutating func setWallet(_ id: Wallet.ID?) -> Bool {
            guard id != walletId else {
                return false
            }

            walletId = id
            billMonth = nil

            return true
        }
    }

    struct CategoryChoice: Equatable {
        public internal(set) var tagId: EntryTag.ID?

        public private(set) var id: EntryCategory.ID?

        private(set) var byType: [Entry.Kind: EntryCategory.ID] = [:]

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

    enum KeypadTarget: Hashable {
        case amount
        case fee
    }

    struct Keypad: Equatable {
        public internal(set) var calculator = AmountCalculator()
        public internal(set) var feeCalculator = AmountCalculator()
        public internal(set) var target: KeypadTarget = .amount

        public var active: AmountCalculator {
            target == .fee ? feeCalculator : calculator
        }

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

    struct Items: Equatable {
        public internal(set) var list: [EntryItem.Draft] = []
        public internal(set) var taxIncluded = false

        var receiptStore: String?
        var isReceiptRead = false

        public var totals: EntryItemTotal {
            EntryItemTotal(list, taxIncluded: taxIncluded)
        }

        var canAdjust: Bool {
            (0...AmountCalculator.maxValue).contains(totals.total)
        }

        mutating func forgetReadNames() {
            for index in list.indices {
                list[index].readName = nil
            }
        }
    }

    struct Filled {
        public internal(set) var voice: VoiceFilled?

        var templateId: EntryTemplate.ID?
    }

    struct Progress: Equatable {
        public internal(set) var isClosing = false

        var isSaving = false
    }

    enum Outcome: Hashable, Sendable {
        case ready(isFirst: Bool)
        case closed(EntryChange)
        case continued(EntryChange)
        case categoryMoved
        case categoryAdded
        case walletChosen
    }

    struct Results {
        public var deletion: Deletion?
        public var hiddenCategory: HiddenCategory?

        public internal(set) var outcome = ScreenOutcome<Outcome>()
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()
        public var results = Results()

        public var memo = ""
        public var today: LocalDate
        public var screen: Screen

        public internal(set) var type: Entry.Kind
        public internal(set) var payment: Payment
        public internal(set) var category = CategoryChoice()
        public internal(set) var keypad = Keypad()
        public internal(set) var items = Items()
        public internal(set) var filled = Filled()
        public internal(set) var progress = Progress()

        init(
            type: Entry.Kind,
            date: LocalDate,
            today: LocalDate
        ) {
            self.type = type
            self.payment = Payment(date: date)
            self.today = today
            self.screen = Screen(deck: EntryModel.Deck.start(for: type))
        }
    }
}

public extension EntryModel.State {
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
        memo = ""
        items = EntryModel.Items()
        category.tagId = nil
        payment.billMonth = nil
        filled = EntryModel.Filled()
    }
}

private extension EntryModel.State {
    var memoLines: [String] {
        memo.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    func changeItems(_ change: () -> Void) {
        let amount = keypad.calculator.amount
        let follows = amount == 0 || amount - items.totals.total == 0

        change()

        if follows {
            adjustToItems()
        }
    }
}
