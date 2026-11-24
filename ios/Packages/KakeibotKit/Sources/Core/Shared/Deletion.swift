import Foundation

public struct Deletion: Hashable, Sendable, Identifiable {
    public let id = UUID()

    package var icons: [Icon]
    package var wallets: [Wallet]
    package var categories: [EntryCategory]
    package var tags: [EntryTag]
    package var recurrings: [Recurring]
    package var templates: [EntryTemplate]
    package var budgets: [Budget]
    package var valuations: [Valuation]
    package var adjustments: [Adjustment]
    package var shelfIcons: [ShelfIcon]
    package var rewardRules: [RewardRule]
    package var rewardLogs: [RewardLog]
    package var themes: [Theme]
    package var entries: [Entry]
    package var themeChoice: ThemeChoice?

    package init(
        icons: [Icon] = [],
        wallets: [Wallet] = [],
        categories: [EntryCategory] = [],
        tags: [EntryTag] = [],
        recurrings: [Recurring] = [],
        templates: [EntryTemplate] = [],
        budgets: [Budget] = [],
        valuations: [Valuation] = [],
        adjustments: [Adjustment] = [],
        shelfIcons: [ShelfIcon] = [],
        rewardRules: [RewardRule] = [],
        rewardLogs: [RewardLog] = [],
        themes: [Theme] = [],
        entries: [Entry] = [],
        themeChoice: ThemeChoice? = nil
    ) {
        self.icons = icons
        self.wallets = wallets
        self.categories = categories
        self.tags = tags
        self.recurrings = recurrings
        self.templates = templates
        self.budgets = budgets
        self.valuations = valuations
        self.adjustments = adjustments
        self.shelfIcons = shelfIcons
        self.rewardRules = rewardRules
        self.rewardLogs = rewardLogs
        self.themes = themes
        self.entries = entries
        self.themeChoice = themeChoice
    }
}

public extension Deletion {
    init(merging deletions: [Deletion]) {
        self.init(
            icons: deletions.flatMap(\.icons),
            wallets: deletions.flatMap(\.wallets),
            categories: deletions.flatMap(\.categories),
            tags: deletions.flatMap(\.tags),
            recurrings: deletions.flatMap(\.recurrings),
            templates: deletions.flatMap(\.templates),
            budgets: deletions.flatMap(\.budgets),
            valuations: deletions.flatMap(\.valuations),
            adjustments: deletions.flatMap(\.adjustments),
            shelfIcons: deletions.flatMap(\.shelfIcons),
            rewardRules: deletions.flatMap(\.rewardRules),
            rewardLogs: deletions.flatMap(\.rewardLogs),
            themes: deletions.flatMap(\.themes),
            entries: deletions.flatMap(\.entries),
            themeChoice: deletions.lazy.compactMap(\.themeChoice).first
        )
    }
}
