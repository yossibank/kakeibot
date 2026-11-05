import Core
import Foundation

public struct Deletion: Hashable, Sendable, Identifiable {
    public let id = UUID()

    var icons: [Icon] = []
    var wallets: [Wallet] = []
    var categories: [EntryCategory] = []
    var tags: [EntryTag] = []
    var recurrings: [Recurring] = []
    var templates: [EntryTemplate] = []
    var budgets: [Budget] = []
    var valuations: [Valuation] = []
    var adjustments: [Adjustment] = []
    var shelfIcons: [ShelfIcon] = []
    var rewardRules: [RewardRule] = []
    var rewardLogs: [RewardLog] = []
    var themes: [Theme] = []
    var entries: [Entry] = []
    var themeChoice: ThemeChoice?
}

public extension Deletion {
    init(merging deletions: [Deletion]) {
        self.init()

        self.icons = deletions.flatMap(\.icons)
        self.wallets = deletions.flatMap(\.wallets)
        self.categories = deletions.flatMap(\.categories)
        self.tags = deletions.flatMap(\.tags)
        self.recurrings = deletions.flatMap(\.recurrings)
        self.templates = deletions.flatMap(\.templates)
        self.budgets = deletions.flatMap(\.budgets)
        self.valuations = deletions.flatMap(\.valuations)
        self.adjustments = deletions.flatMap(\.adjustments)
        self.shelfIcons = deletions.flatMap(\.shelfIcons)
        self.rewardRules = deletions.flatMap(\.rewardRules)
        self.rewardLogs = deletions.flatMap(\.rewardLogs)
        self.themes = deletions.flatMap(\.themes)
        self.entries = deletions.flatMap(\.entries)
        self.themeChoice = deletions.lazy.compactMap(\.themeChoice).first
    }
}
