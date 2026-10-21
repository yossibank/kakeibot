public struct EntryFilter: Hashable, Sendable {
    public var categoryIds: Set<EntryCategory.ID>
    public var walletIds: Set<Wallet.ID>

    public init(
        categoryIds: Set<EntryCategory.ID> = [],
        walletIds: Set<Wallet.ID> = []
    ) {
        self.categoryIds = categoryIds
        self.walletIds = walletIds
    }
}

public extension EntryFilter {
    var isEmpty: Bool {
        categoryIds.isEmpty && walletIds.isEmpty
    }

    func includes(_ entry: Entry) -> Bool {
        includesCategory(of: entry) && includesWallet(of: entry)
    }

    func apply(to days: [EntryDay]) -> [EntryDay] {
        guard !isEmpty else {
            return days
        }

        let entries = days.flatMap(\.entries).filter(includes)
        return EntryDay.grouping(entries)
    }
}

private extension EntryFilter {
    func includesCategory(of entry: Entry) -> Bool {
        guard !categoryIds.isEmpty else {
            return true
        }

        guard let categoryId = entry.categoryId else {
            return false
        }

        return categoryIds.contains(categoryId)
    }

    func includesWallet(of entry: Entry) -> Bool {
        guard !walletIds.isEmpty else {
            return true
        }

        if walletIds.contains(entry.walletId) {
            return true
        }

        guard let toWalletId = entry.toWalletId else {
            return false
        }

        return walletIds.contains(toWalletId)
    }
}
