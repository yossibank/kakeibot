import Core

public extension EntryList {
    func categoryUses(through today: LocalDate) -> [EntryCategory.ID: Int] {
        let start = today.adding(days: 1 - TemplateOrder.frequentDays)

        var uses: [EntryCategory.ID: Int] = [:]

        for day in days where day.date >= start && day.date <= today {
            for entry in day.entries where entry.recurringId == nil {
                if let id = entry.categoryId {
                    uses[id, default: 0] += 1
                }
            }
        }

        return uses
    }

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
