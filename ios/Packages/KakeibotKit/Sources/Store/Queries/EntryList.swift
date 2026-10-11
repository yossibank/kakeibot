import Core

public struct EntryList: Equatable, Sendable {
    public let days: [EntryDay]
    public let categories: [EntryCategory.ID: EntryCategory]
    public let wallets: [Wallet.ID: Wallet]
    public let icons: [Icon.ID: Icon]

    public init(
        days: [EntryDay],
        categories: [EntryCategory.ID: EntryCategory],
        wallets: [Wallet.ID: Wallet],
        icons: [Icon.ID: Icon]
    ) {
        self.days = days
        self.categories = categories
        self.wallets = wallets
        self.icons = icons
    }
}

public struct EntryOptions: Equatable, Sendable {
    public let expenseCategories: [EntryCategory]
    public let incomeCategories: [EntryCategory]
    public let wallets: [Wallet]
    public let icons: [Icon.ID: Icon]

    public init(
        expenseCategories: [EntryCategory],
        incomeCategories: [EntryCategory],
        wallets: [Wallet],
        icons: [Icon.ID: Icon]
    ) {
        self.expenseCategories = expenseCategories
        self.incomeCategories = incomeCategories
        self.wallets = wallets
        self.icons = icons
    }
}
