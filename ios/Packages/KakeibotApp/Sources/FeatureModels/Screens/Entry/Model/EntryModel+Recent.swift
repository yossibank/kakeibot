import Core
import DesignSystem
import Foundation

public extension EntryModel {
    static let recentEntryLimit = 3

    func applyRecent(_ entry: Entry) {
        if output.wallet(entry.walletId) != nil {
            setWallet(entry.walletId)
        }

        if output.categories.contains(where: { $0.id == entry.categoryId }) {
            state.setCategory(entry.categoryId)
        }

        state.category.tagId = output.tags.first { tag in
            tag.id == entry.tagId && tag.archivedAt == nil
        }?.id

        if let memo = entry.memo,
           !memo.isEmpty {
            state.memo = memo
        }

        state.keypad.setAmount(entry.amount)
    }
}
