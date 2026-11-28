import Core
import DesignSystem
import Foundation

public extension EntryModel.Output {
    var showsItems: Bool {
        state.type != .transfer
    }

    var itemTotals: EntryItemTotal {
        state.items.totals
    }

    var itemTotal: Int {
        itemTotals.total
    }

    var itemAdjustment: Int {
        amount - itemTotal
    }

    var itemCount: Int {
        state.items.list.reduce(0) { $0 + $1.quantity }
    }

    var hasItemAdjustment: Bool {
        !state.items.list.isEmpty && itemAdjustment != 0
    }

    var canAdjustToItems: Bool {
        state.items.canAdjust
    }

    var showsReceipt: Bool {
        showsItems && state.keypad.target == .amount
    }

    var showsReceiptGuide: Bool {
        !input.receiptGuideHidden
    }

    var freeReceiptsLeft: Int {
        max(EntryModel.freeReceiptLimit - input.receiptSavedCount, 0)
    }

    var suspectItemIndices: Set<Int> {
        let items = state.items.list

        guard items.contains(where: { $0.readName != nil }) else {
            return []
        }

        return Set(ReceiptSuspect.indices(of: items, difference: itemAdjustment))
    }

    func canReadReceipt(isPro: Bool) -> Bool {
        isPro || input.receiptSavedCount < EntryModel.freeReceiptLimit
    }

    func itemNameSuggestions(for text: String) -> [String] {
        EntryModel.suggestions(
            from: input.recentItemNames,
            readings: input.readings,
            for: text,
            limit: EntryModel.itemSuggestionLimit
        )
    }
}
