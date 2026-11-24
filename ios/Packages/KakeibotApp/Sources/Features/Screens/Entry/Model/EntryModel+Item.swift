import Core
import DesignSystem
import Foundation

public extension EntryModel {
    struct RemovedItem: Hashable {
        public let id = UUID()
        public let index: Int
        public let item: EntryItem.Draft
    }
}

extension EntryModel {
    static let itemSuggestionLimit = 8

    static func quantityText(for item: EntryItem.Draft) -> String? {
        guard item.quantity > 1 else {
            return nil
        }

        let price = unitPrice(of: item)

        return price.quantity > 1
            ? "\(price.quantity) × \(Yen.text(price.unit))"
            : "×\(item.quantity)"
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
