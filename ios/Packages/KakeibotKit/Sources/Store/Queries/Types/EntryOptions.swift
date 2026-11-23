import Core

public struct EntryOptions: Equatable, Sendable {
    public let expenseCategories: [EntryCategory]
    public let incomeCategories: [EntryCategory]
    public let tags: [EntryTag]
    public let wallets: [Wallet]
    public let icons: [Icon.ID: Icon]
    public let sharedCategories: [EntryCategory]
    public let sharedTags: [EntryTag]
    public let sharedWalletIds: Set<Wallet.ID>

    public init(
        expenseCategories: [EntryCategory],
        incomeCategories: [EntryCategory],
        tags: [EntryTag],
        wallets: [Wallet],
        icons: [Icon.ID: Icon],
        sharedCategories: [EntryCategory] = [],
        sharedTags: [EntryTag] = [],
        sharedWalletIds: Set<Wallet.ID> = []
    ) {
        self.expenseCategories = expenseCategories
        self.incomeCategories = incomeCategories
        self.tags = tags
        self.wallets = wallets
        self.icons = icons
        self.sharedCategories = sharedCategories
        self.sharedTags = sharedTags
        self.sharedWalletIds = sharedWalletIds
    }
}
