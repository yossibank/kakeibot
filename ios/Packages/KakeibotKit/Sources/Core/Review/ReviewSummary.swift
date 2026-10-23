public struct ReviewSummary: Hashable, Sendable {
    public let expense: Breakdown
    public let income: Breakdown

    public init(
        entries: [Entry],
        in range: ClosedRange<LocalDate>
    ) {
        let inRange = entries.filter { range.contains($0.date) }

        self.expense = Breakdown(inRange.filter { $0.type == .expense })
        self.income = Breakdown(inRange.filter { $0.type == .income })
    }
}

public extension ReviewSummary {
    struct Breakdown: Hashable, Sendable {
        public let total: Int
        public let byCategory: [EntryCategory.ID: Int]
        public let byWallet: [Wallet.ID: Int]
    }

    var balance: Int {
        income.total - expense.total
    }

    func breakdown(of type: Entry.Kind) -> Breakdown? {
        switch type {
        case .expense: expense
        case .income: income
        case .transfer: nil
        }
    }
}

extension ReviewSummary.Breakdown {
    init(_ entries: [Entry]) {
        var byCategory: [EntryCategory.ID: Int] = [:]
        var byWallet: [Wallet.ID: Int] = [:]

        for entry in entries {
            if let categoryId = entry.categoryId {
                byCategory[categoryId, default: 0] += entry.amount
            }

            byWallet[entry.walletId, default: 0] += entry.amount
        }

        self.init(
            total: entries.reduce(0) { $0 + $1.amount },
            byCategory: byCategory,
            byWallet: byWallet
        )
    }
}
