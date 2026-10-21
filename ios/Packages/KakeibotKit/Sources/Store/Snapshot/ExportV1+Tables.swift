import Core
import GRDB

extension ExportV1.Tables {
    init(fetchingFrom db: Database) throws {
        try self.init(
            icons: Icon.orderByPrimaryKey().fetchAll(db),
            shelfIcons: ShelfIcon.orderByPrimaryKey().fetchAll(db),
            wallets: Wallet.orderByPrimaryKey().fetchAll(db),
            valuations: Valuation.orderByPrimaryKey().fetchAll(db),
            categories: EntryCategory.orderByPrimaryKey().fetchAll(db),
            tags: EntryTag.orderByPrimaryKey().fetchAll(db),
            entries: Entry.orderByPrimaryKey().fetchAll(db),
            templates: EntryTemplate.orderByPrimaryKey().fetchAll(db),
            budgets: Budget.orderByPrimaryKey().fetchAll(db),
            recurrings: Recurring.orderByPrimaryKey().fetchAll(db),
            rewardRules: RewardRule.orderByPrimaryKey().fetchAll(db),
            rewardLogs: RewardLog.orderByPrimaryKey().fetchAll(db),
            rewardGoals: RewardGoal.orderByPrimaryKey().fetchAll(db),
            calendarStamps: CalendarStamp.orderByPrimaryKey().fetchAll(db),
            noSpendDays: NoSpendDay.orderByPrimaryKey().fetchAll(db),
            themes: Theme.orderByPrimaryKey().fetchAll(db),
            settings: Setting.orderByPrimaryKey().fetchAll(db)
        )
    }

    static func deleteAll(in db: Database) throws {
        for type in recordTypes.reversed() {
            try type.deleteAll(db)
        }
    }

    func insert(into db: Database) throws {
        for record in records {
            try record.insert(db)
        }
    }
}

private extension ExportV1.Tables {
    static let recordTypes: [any StoreRecord.Type] = [
        Icon.self,
        ShelfIcon.self,
        Wallet.self,
        Valuation.self,
        EntryCategory.self,
        EntryTag.self,
        Recurring.self,
        EntryTemplate.self,
        Entry.self,
        Budget.self,
        RewardRule.self,
        RewardLog.self,
        RewardGoal.self,
        CalendarStamp.self,
        NoSpendDay.self,
        Theme.self,
        Setting.self
    ]

    var records: [any StoreRecord] {
        let tables: [[any StoreRecord]] = [
            icons,
            shelfIcons,
            wallets,
            valuations,
            categories,
            tags,
            recurrings,
            templates,
            entries,
            budgets,
            rewardRules,
            rewardLogs,
            rewardGoals,
            calendarStamps,
            noSpendDays,
            themes,
            settings
        ]

        return tables.flatMap(\.self)
    }
}
