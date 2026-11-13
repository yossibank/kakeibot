import Core
import DesignSystem
import Foundation

public extension EntryModel {
    static let recentEntryLimit = 3

    var recentEntries: [Entry] {
        guard type != .transfer else {
            return []
        }

        var seen: Set<String> = []

        let entries = (history?.days ?? [])
            .flatMap(\.entries)
            .filter { entry in
                entry.type == type
                    && entry.recurringId == nil
                    && entry.transferId == nil
                    && entry.id != editingId
                    && category(of: entry) != nil
            }
            .sorted { $0.createdAt > $1.createdAt }

        let unique = entries.filter { entry in
            let category = entry.categoryId.map { "\($0)" } ?? ""
            let key = "\(category)>\(entry.amount)>\(entry.memo ?? "")"
            return seen.insert(key).inserted
        }

        return Array(unique.prefix(Self.recentEntryLimit))
    }

    var lastCategoryNote: NoteLine? {
        guard
            type != .transfer,
            let category = selectedCategory
        else {
            return nil
        }

        let last = (history?.days ?? [])
            .flatMap(\.entries)
            .filter { $0.type == type && $0.categoryId == category.id && $0.id != editingId }
            .max { $0.createdAt < $1.createdAt }

        guard let last else {
            return nil
        }

        let day = Self.shortDateText(for: last.date, today: Self.today)
        let value = "\(AmountText.text(last.amount)) · \(day)"
        return NoteLine(title: "前回の\(category.name)", value: value)
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
