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

        return [categories, wallets]
            .filter { !$0.isEmpty }
            .map { $0.joined(separator: "・") }
            .joined(separator: "｜")
    }
}
