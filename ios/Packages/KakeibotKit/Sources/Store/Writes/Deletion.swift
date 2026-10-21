import Core
import Foundation

public struct Deletion: Hashable, Sendable, Identifiable {
    public let id = UUID()

    var wallets: [Wallet] = []
    var categories: [EntryCategory] = []
    var tags: [EntryTag] = []
    var recurrings: [Recurring] = []
    var templates: [EntryTemplate] = []
    var budgets: [Budget] = []
    var valuations: [Valuation] = []
    var shelfIcons: [ShelfIcon] = []
    var entries: [Entry] = []
}

public extension Deletion {
    init(merging deletions: [Deletion]) {
        self.init(
            wallets: deletions.flatMap(\.wallets),
            categories: deletions.flatMap(\.categories),
            tags: deletions.flatMap(\.tags),
            recurrings: deletions.flatMap(\.recurrings),
            templates: deletions.flatMap(\.templates),
            budgets: deletions.flatMap(\.budgets),
            valuations: deletions.flatMap(\.valuations),
            shelfIcons: deletions.flatMap(\.shelfIcons),
            entries: deletions.flatMap(\.entries)
        )
    }
}
