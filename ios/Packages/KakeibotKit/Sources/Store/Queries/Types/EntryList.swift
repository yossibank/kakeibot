import Core

public struct EntryList: Equatable, Sendable {
    public let days: [EntryDay]
    public let categories: [EntryCategory.ID: EntryCategory]
    public let tags: [EntryTag.ID: EntryTag]
    public let wallets: [Wallet.ID: Wallet]
    public let valuations: [Valuation]
    public let adjustments: [Adjustment]
    public let icons: [Icon.ID: Icon]
    public let cardBills: [Recurring]
    public let items: [Entry.ID: [EntryItem]]

    public init(
        days: [EntryDay],
        categories: [EntryCategory.ID: EntryCategory],
        tags: [EntryTag.ID: EntryTag],
        wallets: [Wallet.ID: Wallet],
        valuations: [Valuation] = [],
        adjustments: [Adjustment] = [],
        icons: [Icon.ID: Icon],
        cardBills: [Recurring] = [],
        items: [Entry.ID: [EntryItem]] = [:]
    ) {
        self.days = days
        self.categories = categories
        self.tags = tags
        self.wallets = wallets
        self.valuations = valuations
        self.adjustments = adjustments
        self.icons = icons
        self.cardBills = cardBills
        self.items = items
    }
}

public extension EntryList {
    func budgetCarryover(
        budgets: [Budget],
        from start: YearMonth?,
        into month: YearMonth,
        startingOn startDay: MonthStartDay
    ) -> Int {
        budgets.carryover(into: month, from: start) { month in
            let period = month.period(startingOn: startDay)

            return days.within(period).expenseTotal
        }
    }
}

public struct EntryOptions: Equatable, Sendable {
    public let expenseCategories: [EntryCategory]
    public let incomeCategories: [EntryCategory]
    public let tags: [EntryTag]
    public let wallets: [Wallet]
    public let icons: [Icon.ID: Icon]
    public let sharedCategories: [EntryCategory]
    public let sharedTags: [EntryTag]

    public init(
        expenseCategories: [EntryCategory],
        incomeCategories: [EntryCategory],
        tags: [EntryTag],
        wallets: [Wallet],
        icons: [Icon.ID: Icon],
        sharedCategories: [EntryCategory] = [],
        sharedTags: [EntryTag] = []
    ) {
        self.expenseCategories = expenseCategories
        self.incomeCategories = incomeCategories
        self.tags = tags
        self.wallets = wallets
        self.icons = icons
        self.sharedCategories = sharedCategories
        self.sharedTags = sharedTags
    }
}
