import Core
import Foundation

public extension EntryModel {
    struct RemovedItem: Hashable {
        public let id = UUID()
        public let index: Int
        public let item: EntryItem.Draft
    }

    var showsItems: Bool {
        type != .transfer
    }

    var itemTotals: EntryItemTotal {
        EntryItemTotal(items)
    }

    var itemTotal: Int {
        itemTotals.total
    }

    var itemAdjustment: Int {
        amount - itemTotal
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var hasItemAdjustment: Bool {
        !items.isEmpty && itemAdjustment != 0
    }

    var canAdjustToItems: Bool {
        (0...AmountCalculator.maxValue).contains(itemTotal)
    }

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

    func itemNameSuggestions(for text: String) -> [String] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let names = text.isEmpty
            ? recentItemNames
            : recentItemNames.filter { $0 != text && $0.localizedStandardContains(text) }

        return Array(names.prefix(Self.itemSuggestionLimit))
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
            items.append(draft)
        }
    }

    func updateItem(
        at index: Int,
        name: String,
        quantity: Int = 1,
        amount: Int,
        taxRate: EntryItem.TaxRate? = nil
    ) {
        guard items.indices.contains(index) else {
            return
        }

        changeItems {
            items[index].name = name
            items[index].quantity = quantity
            items[index].amount = amount
            items[index].taxRate = taxRate
        }
    }

    func removeItem(at index: Int) -> RemovedItem? {
        guard items.indices.contains(index) else {
            return nil
        }

        let removed = RemovedItem(index: index, item: items[index])

        changeItems {
            items.remove(at: index)
        }

        return removed
    }

    func restoreItem(_ removed: RemovedItem) {
        let index = min(removed.index, items.count)

        changeItems {
            items.insert(removed.item, at: index)
        }
    }

    func adjustToItems() {
        guard canAdjustToItems else {
            return
        }

        calculator = AmountCalculator(amount: itemTotal)
    }
}

extension EntryModel {
    static let itemSuggestionLimit = 8

    static func quantityText(for item: EntryItem.Draft) -> String? {
        item.quantity > 1 ? "×\(item.quantity)" : nil
    }

    static func unitPrice(of item: EntryItem.Draft) -> (unit: Int, quantity: Int) {
        guard
            item.quantity > 1,
            item.amount % item.quantity == 0
        else {
            return (item.amount, 1)
        }

        return (item.amount / item.quantity, item.quantity)
    }

    static func itemNames(of items: [EntryItem.Draft]) -> String {
        items.map(\.trimmedName).joined(separator: "・")
    }
}

private extension EntryModel {
    var memoLines: [String] {
        memo.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    func changeItems(_ change: () -> Void) {
        let follows = amount == 0 || itemAdjustment == 0

        change()

        if follows {
            adjustToItems()
        }
    }
}
