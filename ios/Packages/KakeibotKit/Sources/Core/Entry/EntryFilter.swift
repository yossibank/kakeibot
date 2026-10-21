public struct EntryFilter: Hashable, Sendable {
    public var categoryIds: Set<EntryCategory.ID>
    public var walletIds: Set<Wallet.ID>
    public var tagIds: Set<EntryTag.ID>

    public init(
        categoryIds: Set<EntryCategory.ID> = [],
        walletIds: Set<Wallet.ID> = [],
        tagIds: Set<EntryTag.ID> = []
    ) {
        self.categoryIds = categoryIds
        self.walletIds = walletIds
        self.tagIds = tagIds
    }
}

public extension EntryFilter {
    var isEmpty: Bool {
        categoryIds.isEmpty && walletIds.isEmpty && tagIds.isEmpty
    }

    func includes(_ entry: Entry) -> Bool {
        includesCategory(of: entry)
            && includesWallet(of: entry)
            && includesTag(of: entry)
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

    func includesTag(of entry: Entry) -> Bool {
        guard !tagIds.isEmpty else {
            return true
        }

        guard let tagId = entry.tagId else {
            return false
        }

        return tagIds.contains(tagId)
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
