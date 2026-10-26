import Core

public extension EntryList {
    func lastWalletId(
        for type: Entry.Kind,
        category categoryId: EntryCategory.ID?
    ) -> Wallet.ID? {
        let entries = days
            .flatMap(\.entries)
            .filter { entry in
                entry.type == type
                    && entry.recurringId == nil
                    && (categoryId == nil || entry.categoryId == categoryId)
            }

        return entries.max { $0.createdAt < $1.createdAt }?.walletId
    }
}
