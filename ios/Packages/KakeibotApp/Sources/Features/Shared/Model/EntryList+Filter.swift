import Core
import Store

extension EntryList {
    var filterCategories: [EntryCategory] {
        categories.values
            .filter { $0.archivedAt == nil }
            .sorted { lhs, rhs in
                if lhs.kind != rhs.kind {
                    return lhs.kind == .expense
                }

                return lhs.sortOrder < rhs.sortOrder
            }
    }

    var filterWallets: [Wallet] {
        wallets.values
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var filterTags: [EntryTag] {
        let categoryIds = filterCategories.map(\.id)

        return tags.values
            .filter { categoryIds.contains($0.categoryId) }
            .filter { $0.archivedAt == nil }
            .sorted { lhs, rhs in
                let left = categoryIds.firstIndex(of: lhs.categoryId) ?? 0
                let right = categoryIds.firstIndex(of: rhs.categoryId) ?? 0

                if left != right {
                    return left < right
                }

                return lhs.sortOrder < rhs.sortOrder
            }
    }

    func title(of filter: EntryFilter) -> String? {
        guard !filter.isEmpty else {
            return nil
        }

        let categories = filterCategories
            .filter { filter.categoryIds.contains($0.id) }
            .map(\.name)

        let wallets = filterWallets
            .filter { filter.walletIds.contains($0.id) }
            .map(\.name)

        let tags = filterTags
            .filter { filter.tagIds.contains($0.id) }
            .map(\.name)

        return [categories, wallets, tags]
            .filter { !$0.isEmpty }
            .map { $0.joined(separator: "・") }
            .joined(separator: "｜")
    }
}
