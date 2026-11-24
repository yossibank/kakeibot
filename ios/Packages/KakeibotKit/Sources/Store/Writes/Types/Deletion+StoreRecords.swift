import Core

extension Deletion {
    var records: [any StoreRecord] {
        let groups: [[any StoreRecord]] = [
            icons,
            wallets,
            categories,
            tags,
            recurrings,
            templates,
            budgets,
            valuations,
            adjustments,
            shelfIcons,
            rewardRules,
            rewardLogs,
            themes
        ]

        return groups.flatMap(\.self)
    }
}
