import Core

public struct EntryList: Equatable, Sendable {
    public let days: [EntryDay]
    public let categories: [EntryCategory.ID: EntryCategory]
    public let tags: [EntryTag.ID: EntryTag]
    public let wallets: [Wallet.ID: Wallet]
    public let valuations: [Valuation]
    public let icons: [Icon.ID: Icon]

    public init(
        days: [EntryDay],
        categories: [EntryCategory.ID: EntryCategory],
        tags: [EntryTag.ID: EntryTag],
        wallets: [Wallet.ID: Wallet],
        valuations: [Valuation] = [],
        icons: [Icon.ID: Icon]
    ) {
        self.days = days
        self.categories = categories
        self.tags = tags
        self.wallets = wallets
        self.valuations = valuations
        self.icons = icons
    }
}

public struct EntryOptions: Equatable, Sendable {
    public let expenseCategories: [EntryCategory]
    public let incomeCategories: [EntryCategory]
    public let tags: [EntryTag]
    public let wallets: [Wallet]
    public let icons: [Icon.ID: Icon]

    public init(
        expenseCategories: [EntryCategory],
        incomeCategories: [EntryCategory],
        tags: [EntryTag],
        wallets: [Wallet],
        icons: [Icon.ID: Icon]
    ) {
        self.expenseCategories = expenseCategories
        self.incomeCategories = incomeCategories
        self.tags = tags
        self.wallets = wallets
        self.icons = icons
    }
}
