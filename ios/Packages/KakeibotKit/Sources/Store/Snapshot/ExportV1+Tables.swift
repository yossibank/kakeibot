import Core
import GRDB

extension ExportV1.Tables {
    init(fetchingFrom db: Database) throws {
        let knownKeys = Setting.Key.allCases
            .filter { $0 != .backupExportedAt }
            .map(\.rawValue)

        let settings = try Setting
            .filter(knownKeys.contains(Column("key")))
            .orderByPrimaryKey()
            .fetchAll(db)

        let icons = try Icon.orderByPrimaryKey().fetchAll(db)
        let shelfIcons = try ShelfIcon.orderByPrimaryKey().fetchAll(db)
        let wallets = try Wallet.orderByPrimaryKey().fetchAll(db)
        let valuations = try Valuation.orderByPrimaryKey().fetchAll(db)
        let adjustments = try Adjustment.orderByPrimaryKey().fetchAll(db)
        let categories = try EntryCategory.orderByPrimaryKey().fetchAll(db)
        let tags = try EntryTag.orderByPrimaryKey().fetchAll(db)
        let entries = try Entry.orderByPrimaryKey().fetchAll(db)
        let entryItems = try EntryItem.orderByPrimaryKey().fetchAll(db)
        let itemNames = try ItemName.orderByPrimaryKey().fetchAll(db)
        let templates = try EntryTemplate.orderByPrimaryKey().fetchAll(db)
        let budgets = try Budget.orderByPrimaryKey().fetchAll(db)
        let recurrings = try Recurring.orderByPrimaryKey().fetchAll(db)
        let rewardRules = try RewardRule.orderByPrimaryKey().fetchAll(db)
        let rewardLogs = try RewardLog.orderByPrimaryKey().fetchAll(db)
        let rewardGoals = try RewardGoal.orderByPrimaryKey().fetchAll(db)
        let calendarStamps = try CalendarStamp.orderByPrimaryKey().fetchAll(db)
        let noSpendDays = try NoSpendDay.orderByPrimaryKey().fetchAll(db)
        let themes = try Theme.orderByPrimaryKey().fetchAll(db)

        self.init(
            icons: icons,
            shelfIcons: shelfIcons,
            wallets: wallets,
            valuations: valuations,
            adjustments: adjustments,
            categories: categories,
            tags: tags,
            entries: entries,
            entryItems: entryItems,
            itemNames: itemNames,
            templates: templates,
            budgets: budgets,
            recurrings: recurrings,
            rewardRules: rewardRules,
            rewardLogs: rewardLogs,
            rewardGoals: rewardGoals,
            calendarStamps: calendarStamps,
            noSpendDays: noSpendDays,
            themes: themes,
            settings: settings
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
        Adjustment.self,
        EntryCategory.self,
        EntryTag.self,
        Recurring.self,
        EntryTemplate.self,
        Entry.self,
        EntryItem.self,
        ItemName.self,
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
            adjustments,
            categories,
            tags,
            recurrings,
            templates,
            entries.filter { $0.transferId == nil },
            entries.filter { $0.transferId != nil },
            entryItems,
            itemNames,
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
