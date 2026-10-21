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
}
