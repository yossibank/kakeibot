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

        for column in Self.columns {
            column.merge(&self, deletions)
        }

        self.entries = deletions.flatMap(\.entries)
        self.themeChoice = deletions.lazy.compactMap(\.themeChoice).first
    }
}

extension Deletion {
    var records: [any StoreRecord] {
        Self.columns.flatMap { $0.records(self) }
    }
}

private extension Deletion {
    static var columns: [DeletionColumn] {
        [
            DeletionColumn(\.icons),
            DeletionColumn(\.wallets),
            DeletionColumn(\.categories),
            DeletionColumn(\.tags),
            DeletionColumn(\.recurrings),
            DeletionColumn(\.templates),
            DeletionColumn(\.budgets),
            DeletionColumn(\.valuations),
            DeletionColumn(\.adjustments),
            DeletionColumn(\.shelfIcons),
            DeletionColumn(\.rewardRules),
            DeletionColumn(\.rewardLogs),
            DeletionColumn(\.themes)
        ]
    }
}

private struct DeletionColumn {
    let merge: (inout Deletion, [Deletion]) -> Void
    let records: (Deletion) -> [any StoreRecord]
}

private extension DeletionColumn {
    init(_ keyPath: WritableKeyPath<Deletion, [some StoreRecord]>) {
        self.merge = { merged, deletions in
            merged[keyPath: keyPath] = deletions.flatMap { $0[keyPath: keyPath] }
        }

        self.records = { deletion in
            deletion[keyPath: keyPath]
        }
    }
}
