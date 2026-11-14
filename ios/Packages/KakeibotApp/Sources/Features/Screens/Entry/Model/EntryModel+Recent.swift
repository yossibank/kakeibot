import Core
import DesignSystem
import Foundation

public extension EntryModel {
    static let recentEntryLimit = 3

    var recentEntries: [Entry] {
        guard type != .transfer else {
            return []
        }

        let shown = Set(categories.map(\.id))

        let templateKeys = templates.map { template in
            Self.recentKey(
                categoryId: template.categoryId,
                amount: template.amount,
                memo: template.memo
            )
        }

        let entries = (history?.entries ?? [])
            .filter { entry in
                entry.type == type
                    && entry.recurringId == nil
                    && entry.transferId == nil
                    && entry.id != editingId
                    && entry.categoryId.map(shown.contains) == true
            }
            .sorted { $0.createdAt > $1.createdAt }

        var seen = Set(templateKeys)

        let unique = entries.filter { entry in
            let key = Self.recentKey(
                categoryId: entry.categoryId,
                amount: entry.amount,
                memo: entry.memo
            )

            return seen.insert(key).inserted
        }

        return Array(unique.prefix(Self.recentEntryLimit))
    }

    func category(of entry: Entry) -> EntryCategory? {
        categories.first { $0.id == entry.categoryId }
    }

    func applyRecent(_ entry: Entry) {
        if wallet(entry.walletId) != nil {
            walletId = entry.walletId
        }

        if categories.contains(where: { $0.id == entry.categoryId }) {
            categoryId = entry.categoryId
        }

        tagId = tags.first { $0.id == entry.tagId && $0.archivedAt == nil }?.id

        if let memo = entry.memo,
           !memo.isEmpty {
            self.memo = memo
        }

        calculator = AmountCalculator(amount: entry.amount)
    }
}

private extension EntryModel {
    static func recentKey(
        categoryId: EntryCategory.ID?,
        amount: Int?,
        memo: String?
    ) -> String {
        let category = categoryId.map { "\($0)" } ?? ""
        let amount = amount.map { "\($0)" } ?? ""
        return "\(category)>\(amount)>\(memo ?? "")"
    }
}
